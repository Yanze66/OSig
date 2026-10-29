// hpu_server: TCP front-end for the hpu_mini user-managed RTL kernel on VCK190.
// Frames (big-endian headers, FNV-1a payload digest):
//   request : "HPQ1" id:u32 cmd:u32 len:u32 arg0:u64 arg1:u64 digest:u64  (40 B) + payload
//   reply   : "HPR1" id:u32 status:u32 len:u32 hw_cycles:u64 us:u64 digest:u64 (40 B) + payload
// cmd 1 PING | 2 KEY_BSK(arg0=pc, arg1=key slot) | 3 KEY_KSK(arg0=pc, arg1=key slot) | 4 LUT(arg0=gid)
//     5 KEYS_COMMIT(arg0=key slot): slot complete; the hardware switches to a slot on first use
//     6 PBS(arg0 = gid | slot<<16): payload = 2049 little-endian u64 (big-LWE, HW order) -> same format back
//     7 RESET_CACHE | 8 REGDUMP | 10 REG_WRITE(arg0 = 0x38 BPIP_CTRL or 0x3C BPIP_TIMEOUT, arg1 = value) -> regdump
//     9 PBS_BATCH(arg0 = gid | slot<<16, arg1=n<=32): payload = n ciphertexts -> n ciphertexts back.
//       Pipelined in the PE: n LDs, then n PBS DOps (only the last one carries the flush bit so the
//       sequencer batches 8 at a time with 16 in flight), then n STs. hw_cycles = PBS phase only.
// Key slots: one BSK/KSK set per OSig recipient, allocated lazily in DDR (slot 0..MAX_SLOTS-1).
// Switching slots rewrites the BSK/KSK base registers and resets the on-chip key caches.
// One thread per TCP connection; hardware access is serialized by a mutex, so network transfer
// of one client's batch overlaps PBS execution of another's.
// status 0 ok | 1 bad frame | 2 digest mismatch | 3 hardware error | 4 bad state/arg
#include <xrt/xrt_device.h>
#include <xrt/xrt_bo.h>
#include <xrt/experimental/xrt_ip.h>
#include <xrt/experimental/xrt_xclbin.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>
#include <array>
#include <chrono>
#include <cerrno>
#include <cstring>
#include <iostream>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

namespace {
constexpr size_t MAX_PAYLOAD = 16u * 1024 * 1024;
constexpr size_t BSK_PC_BYTES = 14401536, KSK_PC_BYTES = 10813440;
constexpr size_t LUT_BYTES = 16384, GLWE_REGION = 256 * LUT_BYTES;
constexpr size_t CT_BYTES = 2049 * 8, CT_STRIDE = 20480, CT_SLOTS = 64;
constexpr int PC_NB = 4;
constexpr uint32_t MAX_SLOTS = 16;
// batch: inputs in regfile R0..R31 / slots 0..31, outputs in R32..R63 / slots 32..63.
// 32 DOps per phase never overflow the 64-deep DOp FIFO (PE instruction FIFOs are 8 deep and back-pressure the router).
constexpr uint32_t BATCH_MAX = 32, OUT_BASE = 32;
constexpr uint32_t BPIP_TIMEOUT_DEFAULT = 1000000; // 5 ms @200 MHz; was 10000 (50 us) until 2026-10-28
// hpu_mini register map
enum Reg : uint32_t { MAGIC=0x00, VERSION=0x04, STATUS=0x0C, ISSUED=0x10, ACK_TOTAL=0x14, DOP_PUSH=0x18, ERRORREG=0x1C,
  CT_LO=0x20, CT_HI=0x24, GLWE_LO=0x30, GLWE_HI=0x34, BPIP_CTRL=0x38, BPIP_TIMEOUT=0x3C, BSK_BASE=0x40, KSK_BASE=0x60,
  KEY_CTRL=0x80, KEY_STATUS=0x84, PEM_LD_ACK=0x90, PEM_ST_ACK=0x94, PEA_ACK=0x98, PEP_ACK=0x9C, LOCAL_ACK=0xA0,
  LAST_PBS_CYCLES=0xA8, CYCLE_LO=0xB0, CYCLE_HI=0xB4 };

struct Fd { int v; explicit Fd(int n):v(n){} ~Fd(){ if(v>=0) close(v);} Fd(const Fd&)=delete; };
uint32_t get32(const uint8_t*p){uint32_t x=0;for(int i=0;i<4;++i)x=(x<<8)|p[i];return x;}
uint64_t get64(const uint8_t*p){uint64_t x=0;for(int i=0;i<8;++i)x=(x<<8)|p[i];return x;}
void put32(uint8_t*p,uint32_t x){for(int i=3;i>=0;--i){p[i]=x&255;x>>=8;}}
void put64(uint8_t*p,uint64_t x){for(int i=7;i>=0;--i){p[i]=x&255;x>>=8;}}
uint64_t fnv(const uint8_t*p,size_t n){uint64_t h=14695981039346656037ULL;for(size_t i=0;i<n;i++){h^=p[i];h*=1099511628211ULL;}return h;}
bool receive(int fd,uint8_t*p,size_t n){size_t done=0;while(done<n){ssize_t k=recv(fd,p+done,n-done,0);if(k==0){if(done==0)return false;throw std::runtime_error("truncated frame");}if(k<0){if(errno==EINTR)continue;throw std::runtime_error("recv error/timeout");}done+=size_t(k);}return true;}
void send_all(int fd,const uint8_t*p,size_t n){while(n){ssize_t k=send(fd,p,n,MSG_NOSIGNAL);if(k<0&&errno==EINTR)continue;if(k<=0)throw std::runtime_error("send failed");p+=k;n-=size_t(k);}}
void reply(int fd,uint32_t id,uint32_t status,const uint8_t*p,size_t n,uint64_t cycles,uint64_t us){
  std::array<uint8_t,40> h{}; std::memcpy(h.data(),"HPR1",4); put32(h.data()+4,id); put32(h.data()+8,status); put32(h.data()+12,uint32_t(n));
  put64(h.data()+16,cycles); put64(h.data()+24,us); put64(h.data()+32,fnv(p,n)); send_all(fd,h.data(),h.size()); if(n) send_all(fd,p,n);
}
struct HardwareFailure : std::runtime_error { using std::runtime_error::runtime_error; };

uint32_t dop_ld(uint32_t rid,uint32_t cid){ return (0x20u<<26)|(cid<<10)|rid; }
uint32_t dop_st(uint32_t rid,uint32_t cid){ return (0x21u<<26)|(cid<<10)|rid; }
uint32_t dop_pbs(uint32_t dst,uint32_t src,uint32_t gid,bool flush){ return (3u<<30)|((flush?1u:0u)<<29)|(gid<<14)|(src<<7)|dst; }

struct KeySet {
  std::vector<xrt::bo> bsk, ksk;
  bool bsk_ok[PC_NB]{}, ksk_ok[PC_NB]{}; bool complete=false;
  KeySet(xrt::device& device, int mem_grp){
    for (int q=0;q<PC_NB;q++){ bsk.emplace_back(device, BSK_PC_BYTES, xrt::bo::flags::normal, mem_grp); ksk.emplace_back(device, KSK_PC_BYTES, xrt::bo::flags::normal, mem_grp); }
  }
};

struct Hpu {
  xrt::device device; xrt::uuid uuid; xrt::ip ip; int mem_grp=-1;
  std::vector<std::unique_ptr<KeySet>> slots; xrt::bo glwe, ct;
  int active_slot=-1;
  std::mutex mtx; // serializes all hardware access (key switch + batch)
  explicit Hpu(const char* xclbin_path) : device(0) {
    uuid = device.load_xclbin(xclbin_path);
    xrt::xclbin xcl{std::string(xclbin_path)};
    for (const auto& m : xcl.get_mems()) {
      if (m.get_used() && m.get_tag().rfind("DDR",0)==0) { mem_grp = m.get_index(); break; }
    }
    if (mem_grp < 0) throw HardwareFailure("no used DDR memory in xclbin");
    ip = xrt::ip(device, uuid, "hpu_mini_krnl:{hpu_mini_1}");
    uint32_t magic = ip.read_register(MAGIC);
    if (magic != 0x4850554Du) throw HardwareFailure("hpu_mini MAGIC mismatch: 0x"+std::to_string(magic));
    slots.resize(MAX_SLOTS);
    glwe = xrt::bo(device, GLWE_REGION, xrt::bo::flags::normal, mem_grp);
    ct = xrt::bo(device, CT_SLOTS*CT_STRIDE, xrt::bo::flags::normal, mem_grp);
    std::memset(glwe.map<uint8_t*>(),0,GLWE_REGION); glwe.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    std::memset(ct.map<uint8_t*>(),0,CT_SLOTS*CT_STRIDE); ct.sync(XCL_BO_SYNC_BO_TO_DEVICE);
    write64(CT_LO, ct.address()); write64(GLWE_LO, glwe.address());
    // BPIP timeout counts cycles while ciphertexts wait for a batch; the DOp pushes below are serial
    // AXI-Lite writes (~2 us each), so 10000 cycles (50 us) truncated 32-ct requests into 24+8.
    // Every request carries the flush bit on its last PBS, so the timeout is only a safety net.
    ip.write_register(BPIP_CTRL, 1); ip.write_register(BPIP_TIMEOUT, BPIP_TIMEOUT_DEFAULT);
    ip.write_register(KEY_CTRL, 0); ip.write_register(ERRORREG, 0);
    std::cout << "hpu_mini MAGIC ok, VERSION=" << ip.read_register(VERSION) << " mem_grp=" << mem_grp
              << " ct=0x" << std::hex << ct.address() << " glwe=0x" << glwe.address() << std::dec << " key_slots=" << MAX_SLOTS << std::endl;
  }
  void write64(uint32_t lo_reg, uint64_t v){ ip.write_register(lo_reg, uint32_t(v)); ip.write_register(lo_reg+4, uint32_t(v>>32)); }
  KeySet& slot(uint32_t s){
    if(s>=MAX_SLOTS) throw std::runtime_error("key slot out of range");
    if(!slots[s]){ slots[s] = std::make_unique<KeySet>(device, mem_grp);
      std::cout << "KEY_SLOT " << s << " allocated bsk0=0x" << std::hex << slots[s]->bsk[0].address() << " ksk0=0x" << slots[s]->ksk[0].address() << std::dec << std::endl; }
    return *slots[s];
  }
  void commit(uint32_t s){
    KeySet& k = slot(s);
    for(int q=0;q<PC_NB;q++) if(!k.bsk_ok[q]||!k.ksk_ok[q]) throw std::runtime_error("keys incomplete for slot "+std::to_string(s)+" pc "+std::to_string(q));
    k.complete = true;
    if(active_slot==int(s)) active_slot=-1; // re-uploaded keys: force a cache reload on next use
  }
  // caller holds mtx
  void activate(uint32_t s){
    if(active_slot==int(s)) return;
    KeySet& k = slot(s);
    if(!k.complete) throw std::runtime_error("key slot "+std::to_string(s)+" not committed");
    ip.write_register(KEY_CTRL, 0);                      // keys unavailable while switching
    for(int q=0;q<PC_NB;q++){ write64(BSK_BASE+8*q, k.bsk[q].address()); write64(KSK_BASE+8*q, k.ksk[q].address()); }
    // Pulse all three resets: bit 8 clears the BSK cache directly; the KSK cache is cleared by the
    // pe_pbs sequencer (reset_cache -> reset_ks, bit 10), not by bit 9. Official driver order is
    // reset first then avail=0; in hpu_mini both land in the same register write.
    ip.write_register(KEY_CTRL, 7u<<8);
    auto t0 = std::chrono::steady_clock::now();
    while((ip.read_register(KEY_STATUS)&3u)!=3u){
      if (std::chrono::steady_clock::now()-t0 > std::chrono::seconds(2)) throw HardwareFailure("timeout waiting key cache reset");
      std::this_thread::sleep_for(std::chrono::microseconds(20));
    }
    ip.write_register(ERRORREG, 0);
    ip.write_register(KEY_CTRL, 0x3);
    active_slot = int(s);
  }
  void wait_count(uint32_t reg, uint32_t target, const char* what){
    auto t0 = std::chrono::steady_clock::now();
    for(;;){
      if (ip.read_register(reg) >= target) return;
      uint32_t err = ip.read_register(ERRORREG);
      if (err) throw HardwareFailure(std::string("hpu error register 0x")+std::to_string(err)+" during "+what);
      if (std::chrono::steady_clock::now()-t0 > std::chrono::seconds(10)) throw HardwareFailure(std::string("timeout waiting ")+what);
      std::this_thread::sleep_for(std::chrono::microseconds(50));
    }
  }
  uint64_t cycles64(){
    uint32_t hi = ip.read_register(CYCLE_HI), lo = ip.read_register(CYCLE_LO), hi2 = ip.read_register(CYCLE_HI);
    if(hi2 != hi) lo = ip.read_register(CYCLE_LO);
    return (uint64_t(hi2)<<32) | lo;
  }
  // n PBS pipelined: slots[0..n) -> R[0..n) -> PBS(gid) -> R[32..32+n) -> slots[32..32+n)
  // returns cycles of the PBS phase (first PBS DOp pushed -> last pep ack); total = LD+PBS+ST
  uint64_t pbs_batch(uint32_t key_slot, uint32_t gid, uint32_t nct, const uint8_t* in, uint8_t* out, uint64_t& total_cycles){
    if(nct<1 || nct>BATCH_MAX) throw std::runtime_error("bad batch size");
    std::lock_guard<std::mutex> lock(mtx);
    activate(key_slot);
    auto* base = ct.map<uint8_t*>();
    for(uint32_t i=0;i<nct;i++){
      std::memcpy(base+i*CT_STRIDE, in+i*CT_BYTES, CT_BYTES); std::memset(base+i*CT_STRIDE+CT_BYTES, 0, CT_STRIDE-CT_BYTES);
      std::memset(base+(OUT_BASE+i)*CT_STRIDE, 0xA5, CT_STRIDE);
    }
    ct.sync(XCL_BO_SYNC_BO_TO_DEVICE, nct*CT_STRIDE, 0);
    ct.sync(XCL_BO_SYNC_BO_TO_DEVICE, nct*CT_STRIDE, OUT_BASE*CT_STRIDE);
    uint32_t ld0 = ip.read_register(PEM_LD_ACK), st0 = ip.read_register(PEM_ST_ACK), pep0 = ip.read_register(PEP_ACK);
    uint64_t t_start = cycles64();
    for(uint32_t i=0;i<nct;i++) ip.write_register(DOP_PUSH, dop_ld(i, i));
    wait_count(PEM_LD_ACK, ld0+nct, "LD batch");
    uint64_t c0 = cycles64();
    for(uint32_t i=0;i<nct;i++) ip.write_register(DOP_PUSH, dop_pbs(OUT_BASE+i, i, gid, i==nct-1));
    wait_count(PEP_ACK, pep0+nct, "PBS batch");
    uint64_t c1 = cycles64();
    for(uint32_t i=0;i<nct;i++) ip.write_register(DOP_PUSH, dop_st(OUT_BASE+i, OUT_BASE+i));
    wait_count(PEM_ST_ACK, st0+nct, "ST batch");
    total_cycles = cycles64() - t_start;
    ct.sync(XCL_BO_SYNC_BO_FROM_DEVICE, nct*CT_STRIDE, OUT_BASE*CT_STRIDE);
    for(uint32_t i=0;i<nct;i++) std::memcpy(out+i*CT_BYTES, base+(OUT_BASE+i)*CT_STRIDE, CT_BYTES);
    return c1 - c0;
  }
  std::vector<uint8_t> regdump(){
    static const uint32_t regs[] = {MAGIC,VERSION,STATUS,ISSUED,ACK_TOTAL,ERRORREG,BPIP_CTRL,BPIP_TIMEOUT,KEY_STATUS,PEM_LD_ACK,PEM_ST_ACK,PEA_ACK,PEP_ACK,LOCAL_ACK,LAST_PBS_CYCLES,CYCLE_LO,CYCLE_HI};
    std::vector<uint8_t> out; for(uint32_t r: regs){ std::array<uint8_t,8> e{}; put32(e.data(), r); put32(e.data()+4, ip.read_register(r)); out.insert(out.end(), e.begin(), e.end()); }
    return out;
  }
};

std::mutex log_mtx;
template<class F> void logline(F f){ std::lock_guard<std::mutex> l(log_mtx); f(std::cout); std::cout<<std::endl; }

void serve_client(Hpu& hpu, int fd_raw){
  Fd client(fd_raw); int fd = client.v;
  timeval timeout{120,0}; setsockopt(fd,SOL_SOCKET,SO_RCVTIMEO,&timeout,sizeof(timeout)); setsockopt(fd,SOL_SOCKET,SO_SNDTIMEO,&timeout,sizeof(timeout));
  int one=1; setsockopt(fd,IPPROTO_TCP,TCP_NODELAY,&one,sizeof(one));
  std::vector<uint8_t> payload, outbuf(BATCH_MAX*CT_BYTES);
  try { for(;;){
    std::array<uint8_t,40> h{}; if(!receive(fd,h.data(),h.size())) break;
    uint32_t id=get32(h.data()+4), cmd=get32(h.data()+8), n=get32(h.data()+12); uint64_t arg0=get64(h.data()+16), arg1=get64(h.data()+24), digest=get64(h.data()+32);
    if(std::memcmp(h.data(),"HPQ1",4)||n>MAX_PAYLOAD){ reply(fd,id,1,nullptr,0,0,0); break; }
    if(payload.size()<n) payload.resize(n);
    if(n && !receive(fd,payload.data(),n)) throw std::runtime_error("missing payload");
    if(fnv(payload.data(),n)!=digest){ reply(fd,id,2,nullptr,0,0,0); continue; }
    auto t0=std::chrono::steady_clock::now();
    auto us=[&]{ return uint64_t(std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now()-t0).count()); };
    try {
      switch(cmd){
        case 1: { std::lock_guard<std::mutex> l(hpu.mtx); auto d=hpu.regdump(); reply(fd,id,0,d.data(),d.size(),0,us()); break; }
        case 2: case 3: {
          size_t need = cmd==2 ? BSK_PC_BYTES : KSK_PC_BYTES;
          if(arg0>=PC_NB || n!=need || arg1>=MAX_SLOTS){ reply(fd,id,4,nullptr,0,0,0); break; }
          std::lock_guard<std::mutex> l(hpu.mtx);
          KeySet& k = hpu.slot(uint32_t(arg1));
          auto& bo = cmd==2 ? k.bsk[arg0] : k.ksk[arg0];
          std::memcpy(bo.map<uint8_t*>(), payload.data(), n); bo.sync(XCL_BO_SYNC_BO_TO_DEVICE);
          (cmd==2 ? k.bsk_ok : k.ksk_ok)[arg0]=true; k.complete=false;
          if(hpu.active_slot==int(arg1)) hpu.active_slot=-1;
          reply(fd,id,0,nullptr,0,0,us()); logline([&](std::ostream&o){o<<"KEY "<<(cmd==2?"BSK":"KSK")<<" slot="<<arg1<<" pc="<<arg0<<" bytes="<<n;}); break; }
        case 4: {
          if(arg0>=256 || n!=LUT_BYTES){ reply(fd,id,4,nullptr,0,0,0); break; }
          std::lock_guard<std::mutex> l(hpu.mtx);
          std::memcpy(hpu.glwe.map<uint8_t*>()+arg0*LUT_BYTES, payload.data(), n); hpu.glwe.sync(XCL_BO_SYNC_BO_TO_DEVICE, LUT_BYTES, arg0*LUT_BYTES);
          reply(fd,id,0,nullptr,0,0,us()); logline([&](std::ostream&o){o<<"LUT gid="<<arg0;}); break; }
        case 5: { std::lock_guard<std::mutex> l(hpu.mtx); hpu.commit(uint32_t(arg0)); auto d=hpu.regdump(); reply(fd,id,0,d.data(),d.size(),0,us()); logline([&](std::ostream&o){o<<"KEYS_COMMITTED slot="<<arg0;}); break; }
        case 6: {
          uint32_t gid = uint32_t(arg0 & 0xFFFF), ks = uint32_t(arg0 >> 16);
          if(n!=CT_BYTES || gid>=256 || ks>=MAX_SLOTS){ reply(fd,id,4,nullptr,0,0,0); break; }
          uint64_t total=0; uint64_t cycles = hpu.pbs_batch(ks, gid, 1, payload.data(), outbuf.data(), total);
          reply(fd,id,0,outbuf.data(),CT_BYTES,cycles,us());
          logline([&](std::ostream&o){o<<"PBS_DONE id="<<id<<" slot="<<ks<<" gid="<<gid<<" hw_cycles="<<cycles<<" us="<<us();}); break; }
        case 7: { std::lock_guard<std::mutex> l(hpu.mtx); hpu.active_slot=-1; hpu.ip.write_register(KEY_CTRL, 0x3|(7u<<8)); reply(fd,id,0,nullptr,0,0,us()); break; }
        case 8: { std::lock_guard<std::mutex> l(hpu.mtx); auto d=hpu.regdump(); reply(fd,id,0,d.data(),d.size(),0,us()); break; }
        case 10: { // REG_WRITE, only the quasi-static batching registers
          if(!(arg0==BPIP_CTRL || arg0==BPIP_TIMEOUT) || arg1>0xFFFFFFFFull){ reply(fd,id,4,nullptr,0,0,0); break; }
          std::lock_guard<std::mutex> l(hpu.mtx); hpu.ip.write_register(uint32_t(arg0), uint32_t(arg1)); auto d=hpu.regdump();
          reply(fd,id,0,d.data(),d.size(),0,us()); logline([&](std::ostream&o){o<<"REG_WRITE 0x"<<std::hex<<arg0<<" = 0x"<<arg1<<std::dec;}); break; }
        case 9: {
          uint32_t gid = uint32_t(arg0 & 0xFFFF), ks = uint32_t(arg0 >> 16);
          if(gid>=256 || ks>=MAX_SLOTS || arg1<1 || arg1>BATCH_MAX || n!=arg1*CT_BYTES){ reply(fd,id,4,nullptr,0,0,0); break; }
          uint64_t total=0; uint64_t cycles = hpu.pbs_batch(ks, gid, uint32_t(arg1), payload.data(), outbuf.data(), total);
          reply(fd,id,0,outbuf.data(),n,cycles,us());
          logline([&](std::ostream&o){o<<"PBS_BATCH_DONE id="<<id<<" slot="<<ks<<" gid="<<gid<<" n="<<arg1<<" pbs_cycles="<<cycles<<" total_cycles="<<total<<" us="<<us();}); break; }
        default: reply(fd,id,1,nullptr,0,0,0); break;
      }
    } catch(const HardwareFailure& e){ std::vector<uint8_t> d; { std::lock_guard<std::mutex> l(hpu.mtx); hpu.active_slot=-1; d=hpu.regdump(); } try{reply(fd,id,3,d.data(),d.size(),0,us());}catch(...){}
        logline([&](std::ostream&o){o<<"HARDWARE FAILURE: "<<e.what();}); break; }
      catch(const std::exception& e){ logline([&](std::ostream&o){o<<"request error: "<<e.what();}); try{reply(fd,id,4,nullptr,0,0,us());}catch(...){} }
  }} catch(const std::exception& e){ logline([&](std::ostream&o){o<<"client closed: "<<e.what();}); }
}
}

int main(int argc, char** argv){ try {
  if(argc<2||argc>4) throw std::runtime_error("Usage: hpu_server IMAGE.xclbin [port=5002] [bind_ipv4=0.0.0.0]");
  unsigned long port = argc>2 ? std::stoul(argv[2]) : 5002; if(port<1||port>65535) throw std::runtime_error("invalid port");
  Hpu hpu(argv[1]);
  Fd listener(socket(AF_INET,SOCK_STREAM,0)); if(listener.v<0) throw std::runtime_error("socket failed");
  int one=1; setsockopt(listener.v,SOL_SOCKET,SO_REUSEADDR,&one,sizeof(one));
  sockaddr_in addr{}; addr.sin_family=AF_INET; addr.sin_port=htons(uint16_t(port));
  if(inet_pton(AF_INET, argc>3?argv[3]:"0.0.0.0", &addr.sin_addr)!=1) throw std::runtime_error("invalid bind IPv4");
  if(bind(listener.v,reinterpret_cast<sockaddr*>(&addr),sizeof(addr))||listen(listener.v,16)) throw std::runtime_error("bind/listen failed");
  std::cout << "HPU_SERVER_READY port=" << port << std::endl;
  for(;;){
    int fd=accept(listener.v,nullptr,nullptr); if(fd<0){ if(errno==EINTR) continue; throw std::runtime_error("accept failed"); }
    std::thread(serve_client, std::ref(hpu), fd).detach();
  }
} catch(const std::exception& e){ std::cerr<<"FATAL: "<<e.what()<<std::endl; return 1; } }
