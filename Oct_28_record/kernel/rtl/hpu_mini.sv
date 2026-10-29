// ==============================================================================================
// hpu_mini : minimal KS+PBS core for VCK190 (step2 of OSig HPU bring-up)
// ----------------------------------------------------------------------------------------------
// Assembles the unmodified Zama HPU sub-modules:
//   * hpu_with_pe : regfile + pe_mem (DDR<->regfile LD/ST) + pe_alu (linear ops)
//   * pe_pbs      : monolithic KS + blind-rotation + sample-extract processing element
// and adds a thin control shell:
//   * AXI4-Lite register block (configuration, key addresses, status, profiling)
//   * DOp FIFO + router replacing the instruction scheduler (software-ordered execution)
// No HPU RTL is modified. Target config: pem1_glwe1_bsk4_ksk4, PSI16 GF64,
// msg2_carry2_pfail128_132b_tuniform_144a47, REGF reg64_coef32_seq4.
// ==============================================================================================

module hpu_mini
  import common_definition_pkg::*;
  import param_tfhe_pkg::*;
  import top_common_param_pkg::*;
  import hpu_common_param_pkg::*;
  import hpu_common_instruction_pkg::*;
  import axi_if_common_param_pkg::*;
  import axi_if_bsk_axi_pkg::*;
  import axi_if_ksk_axi_pkg::*;
  import axi_if_glwe_axi_pkg::*;
  import axi_if_ct_axi_pkg::*;
  import regf_common_param_pkg::*;
  import pem_common_param_pkg::*;
  import pea_common_param_pkg::*;
  import pep_common_param_pkg::*;
#(
  parameter int AXIL_ADD_W  = 12,
  parameter int AXIL_DATA_W = 32,
  parameter int DOP_FIFO_DEPTH = 64 // power of 2
)
(
  input  logic ap_clk,
  input  logic ap_rst_n,

  // ------------------------------------------------------------------------------------------
  // AXI4-Lite control
  // ------------------------------------------------------------------------------------------
  input  logic [AXIL_ADD_W-1:0]      s_axi_control_awaddr,
  input  logic                       s_axi_control_awvalid,
  output logic                       s_axi_control_awready,
  input  logic [AXIL_DATA_W-1:0]     s_axi_control_wdata,
  input  logic [AXIL_DATA_W/8-1:0]   s_axi_control_wstrb,
  input  logic                       s_axi_control_wvalid,
  output logic                       s_axi_control_wready,
  output logic [1:0]                 s_axi_control_bresp,
  output logic                       s_axi_control_bvalid,
  input  logic                       s_axi_control_bready,
  input  logic [AXIL_ADD_W-1:0]      s_axi_control_araddr,
  input  logic                       s_axi_control_arvalid,
  output logic                       s_axi_control_arready,
  output logic [AXIL_DATA_W-1:0]     s_axi_control_rdata,
  output logic [1:0]                 s_axi_control_rresp,
  output logic                       s_axi_control_rvalid,
  input  logic                       s_axi_control_rready,

  // ------------------------------------------------------------------------------------------
  // m_axi_pem : ciphertext load/store (full AXI4), PEM_PC = 1
  // ------------------------------------------------------------------------------------------
  output logic [axi_if_ct_axi_pkg::AXI4_ID_W-1:0]    m_axi_pem_awid,
  output logic [axi_if_ct_axi_pkg::AXI4_ADD_W-1:0]   m_axi_pem_awaddr,
  output logic [AXI4_LEN_W-1:0]                      m_axi_pem_awlen,
  output logic [AXI4_SIZE_W-1:0]                     m_axi_pem_awsize,
  output logic [AXI4_BURST_W-1:0]                    m_axi_pem_awburst,
  output logic                                       m_axi_pem_awvalid,
  input  logic                                       m_axi_pem_awready,
  output logic [axi_if_ct_axi_pkg::AXI4_DATA_W-1:0]  m_axi_pem_wdata,
  output logic [axi_if_ct_axi_pkg::AXI4_STRB_W-1:0]  m_axi_pem_wstrb,
  output logic                                       m_axi_pem_wlast,
  output logic                                       m_axi_pem_wvalid,
  input  logic                                       m_axi_pem_wready,
  input  logic [axi_if_ct_axi_pkg::AXI4_ID_W-1:0]    m_axi_pem_bid,
  input  logic [AXI4_RESP_W-1:0]                     m_axi_pem_bresp,
  input  logic                                       m_axi_pem_bvalid,
  output logic                                       m_axi_pem_bready,
  output logic [axi_if_ct_axi_pkg::AXI4_ID_W-1:0]    m_axi_pem_arid,
  output logic [axi_if_ct_axi_pkg::AXI4_ADD_W-1:0]   m_axi_pem_araddr,
  output logic [AXI4_LEN_W-1:0]                      m_axi_pem_arlen,
  output logic [AXI4_SIZE_W-1:0]                     m_axi_pem_arsize,
  output logic [AXI4_BURST_W-1:0]                    m_axi_pem_arburst,
  output logic                                       m_axi_pem_arvalid,
  input  logic                                       m_axi_pem_arready,
  input  logic [axi_if_ct_axi_pkg::AXI4_ID_W-1:0]    m_axi_pem_rid,
  input  logic [axi_if_ct_axi_pkg::AXI4_DATA_W-1:0]  m_axi_pem_rdata,
  input  logic [AXI4_RESP_W-1:0]                     m_axi_pem_rresp,
  input  logic                                       m_axi_pem_rlast,
  input  logic                                       m_axi_pem_rvalid,
  output logic                                       m_axi_pem_rready,

  // ------------------------------------------------------------------------------------------
  // m_axi_glwe : GLWE LUT fetch (read-only), GLWE_PC = 1
  // ------------------------------------------------------------------------------------------
  output logic [axi_if_glwe_axi_pkg::AXI4_ID_W-1:0]   m_axi_glwe_arid,
  output logic [axi_if_glwe_axi_pkg::AXI4_ADD_W-1:0]  m_axi_glwe_araddr,
  output logic [AXI4_LEN_W-1:0]                       m_axi_glwe_arlen,
  output logic [AXI4_SIZE_W-1:0]                      m_axi_glwe_arsize,
  output logic [AXI4_BURST_W-1:0]                     m_axi_glwe_arburst,
  output logic                                        m_axi_glwe_arvalid,
  input  logic                                        m_axi_glwe_arready,
  input  logic [axi_if_glwe_axi_pkg::AXI4_ID_W-1:0]   m_axi_glwe_rid,
  input  logic [axi_if_glwe_axi_pkg::AXI4_DATA_W-1:0] m_axi_glwe_rdata,
  input  logic [AXI4_RESP_W-1:0]                      m_axi_glwe_rresp,
  input  logic                                        m_axi_glwe_rlast,
  input  logic                                        m_axi_glwe_rvalid,
  output logic                                        m_axi_glwe_rready,

  // ------------------------------------------------------------------------------------------
  // m_axi_bsk0..3 : BSK streaming (read-only), BSK_PC = 4
  // ------------------------------------------------------------------------------------------
`define HPU_MINI_BSK_PORT(i) \
  output logic [axi_if_bsk_axi_pkg::AXI4_ID_W-1:0]    m_axi_bsk``i``_arid, \
  output logic [axi_if_bsk_axi_pkg::AXI4_ADD_W-1:0]   m_axi_bsk``i``_araddr, \
  output logic [AXI4_LEN_W-1:0]                       m_axi_bsk``i``_arlen, \
  output logic [AXI4_SIZE_W-1:0]                      m_axi_bsk``i``_arsize, \
  output logic [AXI4_BURST_W-1:0]                     m_axi_bsk``i``_arburst, \
  output logic                                        m_axi_bsk``i``_arvalid, \
  input  logic                                        m_axi_bsk``i``_arready, \
  input  logic [axi_if_bsk_axi_pkg::AXI4_ID_W-1:0]    m_axi_bsk``i``_rid, \
  input  logic [axi_if_bsk_axi_pkg::AXI4_DATA_W-1:0]  m_axi_bsk``i``_rdata, \
  input  logic [AXI4_RESP_W-1:0]                      m_axi_bsk``i``_rresp, \
  input  logic                                        m_axi_bsk``i``_rlast, \
  input  logic                                        m_axi_bsk``i``_rvalid, \
  output logic                                        m_axi_bsk``i``_rready,

`define HPU_MINI_KSK_PORT(i) \
  output logic [axi_if_ksk_axi_pkg::AXI4_ID_W-1:0]    m_axi_ksk``i``_arid, \
  output logic [axi_if_ksk_axi_pkg::AXI4_ADD_W-1:0]   m_axi_ksk``i``_araddr, \
  output logic [AXI4_LEN_W-1:0]                       m_axi_ksk``i``_arlen, \
  output logic [AXI4_SIZE_W-1:0]                      m_axi_ksk``i``_arsize, \
  output logic [AXI4_BURST_W-1:0]                     m_axi_ksk``i``_arburst, \
  output logic                                        m_axi_ksk``i``_arvalid, \
  input  logic                                        m_axi_ksk``i``_arready, \
  input  logic [axi_if_ksk_axi_pkg::AXI4_ID_W-1:0]    m_axi_ksk``i``_rid, \
  input  logic [axi_if_ksk_axi_pkg::AXI4_DATA_W-1:0]  m_axi_ksk``i``_rdata, \
  input  logic [AXI4_RESP_W-1:0]                      m_axi_ksk``i``_rresp, \
  input  logic                                        m_axi_ksk``i``_rlast, \
  input  logic                                        m_axi_ksk``i``_rvalid, \
  output logic                                        m_axi_ksk``i``_rready,

  `HPU_MINI_BSK_PORT(0)
  `HPU_MINI_BSK_PORT(1)
  `HPU_MINI_BSK_PORT(2)
  `HPU_MINI_BSK_PORT(3)
  `HPU_MINI_KSK_PORT(0)
  `HPU_MINI_KSK_PORT(1)
  `HPU_MINI_KSK_PORT(2)
  `HPU_MINI_KSK_PORT(3)

  output logic interrupt // unused for now, tied low
);

// ============================================================================================== --
// Sanity checks on selected configuration
// ============================================================================================== --
  initial begin
    assert (PEM_PC == 1)  else $fatal(1, "hpu_mini expects PEM_PC==1");
    assert (GLWE_PC == 1) else $fatal(1, "hpu_mini expects GLWE_PC==1");
    assert (BSK_PC == 4)  else $fatal(1, "hpu_mini expects BSK_PC==4");
    assert (KSK_PC == 4)  else $fatal(1, "hpu_mini expects KSK_PC==4");
    assert (PE_INST_W == 32) else $fatal(1, "hpu_mini expects 32b DOps");
  end

// ============================================================================================== --
// Clock / reset
// ============================================================================================== --
  logic clk;
  logic s_rst_n;
  logic [1:0] rst_sync = 2'b00; // defined reset from t0 in simulation
  assign clk = ap_clk;
  always_ff @(posedge clk) rst_sync <= {rst_sync[0], ap_rst_n};
  assign s_rst_n = rst_sync[1];

  assign interrupt = 1'b0;

// ============================================================================================== --
// Configuration registers (written over AXI4-Lite)
// ============================================================================================== --
  logic [63:0]                      r_ct_mem_addr;
  logic [63:0]                      r_gid_offset;
  logic [BSK_PC-1:0][63:0]          r_bsk_addr;
  logic [KSK_PC-1:0][63:0]          r_ksk_addr;
  logic                             r_bsk_avail;
  logic                             r_ksk_avail;
  logic                             r_use_bpip;
  logic                             r_use_bpip_opportunism;
  logic [31:0]                      r_bpip_timeout;
  logic                             p_reset_bsk_cache;   // 1-cycle pulses
  logic                             p_reset_ksk_cache;
  logic                             p_reset_cache;
  logic                             bsk_rst_done_sticky;
  logic                             ksk_rst_done_sticky;

  // status / profiling
  logic [31:0] issued_cnt;
  logic [31:0] ack_cnt_total;
  logic [31:0] pem_ld_ack_cnt, pem_st_ack_cnt, pea_ack_cnt, pep_ack_cnt;
  logic [31:0] error_sticky;
  logic [63:0] cycle_cnt;
  logic [31:0] last_pbs_cycles;   // cycles between pep inst issue and inst_ack

// ============================================================================================== --
// DOp FIFO (simple synchronous FIFO, distributed RAM)
// ============================================================================================== --
  localparam int DOP_PTR_W = $clog2(DOP_FIFO_DEPTH);

  logic [31:0] dop_mem [DOP_FIFO_DEPTH-1:0];
  logic [DOP_PTR_W:0] dop_wptr, dop_rptr;
  logic dop_push, dop_pop;
  logic [31:0] dop_push_data;
  logic dop_empty, dop_full;
  logic [31:0] dop_head;

  assign dop_empty = (dop_wptr == dop_rptr);
  assign dop_full  = (dop_wptr[DOP_PTR_W] != dop_rptr[DOP_PTR_W])
                   && (dop_wptr[DOP_PTR_W-1:0] == dop_rptr[DOP_PTR_W-1:0]);
  assign dop_head  = dop_mem[dop_rptr[DOP_PTR_W-1:0]];

  always_ff @(posedge clk) begin
    if (!s_rst_n) begin
      dop_wptr <= '0;
      dop_rptr <= '0;
    end else begin
      if (dop_push && !dop_full) dop_wptr <= dop_wptr + 1;
      if (dop_pop  && !dop_empty) dop_rptr <= dop_rptr + 1;
    end
  end
  always_ff @(posedge clk) begin
    if (dop_push && !dop_full) dop_mem[dop_wptr[DOP_PTR_W-1:0]] <= dop_push_data;
  end

// ============================================================================================== --
// DOp router : replaces the instruction scheduler (software orders execution)
// ============================================================================================== --
  logic [PE_INST_W-1:0] isc_pem_insn, isc_pea_insn, isc_pep_insn;
  logic isc_pem_vld, isc_pem_rdy;
  logic isc_pea_vld, isc_pea_rdy;
  logic isc_pep_vld, isc_pep_rdy;
  logic pem_isc_load_ack, pem_isc_store_ack;
  logic pea_isc_ack;
  logic pep_inst_ack;
  logic pep_inst_load_blwe_ack;
  logic [LWE_K_W-1:0] pep_inst_ack_br_loop;

  logic local_ack; // SYNC / unsupported kinds consumed locally

  typedef enum logic [1:0] {RT_IDLE, RT_DISPATCH} rt_state_e;
  rt_state_e rt_state;

  logic [1:0] head_kind;
  assign head_kind = dop_head[31:30];

  logic head_is_sync;
  assign head_is_sync = (dop_head[31:26] == DOP_SYNC);

  assign isc_pem_insn = dop_head;
  assign isc_pea_insn = dop_head;
  assign isc_pep_insn = dop_head;

  always_comb begin
    isc_pem_vld = 1'b0;
    isc_pea_vld = 1'b0;
    isc_pep_vld = 1'b0;
    local_ack   = 1'b0;
    dop_pop     = 1'b0;
    if (rt_state == RT_DISPATCH && !dop_empty) begin
      if (head_is_sync || head_kind == DOPT_UCORE) begin
        local_ack = 1'b1;
        dop_pop   = 1'b1;
      end else begin
        unique case (head_kind)
          DOPT_ARITH: begin isc_pea_vld = 1'b1; dop_pop = isc_pea_rdy; end
          DOPT_LS:    begin isc_pem_vld = 1'b1; dop_pop = isc_pem_rdy; end
          DOPT_PBS:   begin isc_pep_vld = 1'b1; dop_pop = isc_pep_rdy; end
          default:    begin local_ack   = 1'b1; dop_pop = 1'b1;       end
        endcase
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!s_rst_n) rt_state <= RT_DISPATCH; // always dispatching; FSM kept for future gating
    else          rt_state <= RT_DISPATCH;
  end

// ============================================================================================== --
// Counters
// ============================================================================================== --
  logic [31:0] local_ack_cnt;
  logic        pbs_timer_run;
  logic [31:0] pbs_timer;

  always_ff @(posedge clk) begin
    if (!s_rst_n) begin
      issued_cnt      <= '0;
      pem_ld_ack_cnt  <= '0;
      pem_st_ack_cnt  <= '0;
      pea_ack_cnt     <= '0;
      pep_ack_cnt     <= '0;
      local_ack_cnt   <= '0;
      cycle_cnt       <= '0;
      pbs_timer_run   <= 1'b0;
      pbs_timer       <= '0;
      last_pbs_cycles <= '0;
    end else begin
      cycle_cnt <= cycle_cnt + 1;
      if (dop_pop && !dop_empty) issued_cnt <= issued_cnt + 1;
      if (pem_isc_load_ack)  pem_ld_ack_cnt <= pem_ld_ack_cnt + 1;
      if (pem_isc_store_ack) pem_st_ack_cnt <= pem_st_ack_cnt + 1;
      if (pea_isc_ack)       pea_ack_cnt    <= pea_ack_cnt + 1;
      if (pep_inst_ack)      pep_ack_cnt    <= pep_ack_cnt + 1;
      if (local_ack)         local_ack_cnt  <= local_ack_cnt + 1;
      // crude PBS latency probe: from pep instruction accept to its ack
      if (isc_pep_vld && isc_pep_rdy) begin
        pbs_timer_run <= 1'b1;
        pbs_timer     <= '0;
      end else if (pbs_timer_run) begin
        pbs_timer <= pbs_timer + 1;
        if (pep_inst_ack) begin
          pbs_timer_run   <= 1'b0;
          last_pbs_cycles <= pbs_timer;
        end
      end
    end
  end
  assign ack_cnt_total = pem_ld_ack_cnt + pem_st_ack_cnt + pea_ack_cnt + pep_ack_cnt + local_ack_cnt;

// ============================================================================================== --
// AXI4-Lite slave
// ============================================================================================== --
  logic aw_hs, w_hs, ar_hs;
  logic [AXIL_ADD_W-1:0] awaddr_q, araddr_q;
  logic aw_pend, w_pend;
  logic [31:0] wdata_q;

  // write address / data capture
  assign s_axi_control_awready = !aw_pend;
  assign s_axi_control_wready  = !w_pend;
  assign aw_hs = s_axi_control_awvalid && s_axi_control_awready;
  assign w_hs  = s_axi_control_wvalid  && s_axi_control_wready;

  logic do_write;
  assign do_write = (aw_pend || aw_hs) && (w_pend || w_hs) && (!s_axi_control_bvalid || s_axi_control_bready);

  logic [AXIL_ADD_W-1:0] wr_addr;
  logic [31:0]           wr_data;
  assign wr_addr = aw_pend ? awaddr_q : s_axi_control_awaddr;
  assign wr_data = w_pend  ? wdata_q  : s_axi_control_wdata;

  always_ff @(posedge clk) begin
    if (!s_rst_n) begin
      aw_pend <= 1'b0;
      w_pend  <= 1'b0;
      s_axi_control_bvalid <= 1'b0;
    end else begin
      if (aw_hs) begin awaddr_q <= s_axi_control_awaddr; aw_pend <= 1'b1; end
      if (w_hs)  begin wdata_q  <= s_axi_control_wdata;  w_pend  <= 1'b1; end
      if (do_write) begin
        aw_pend <= 1'b0;
        w_pend  <= 1'b0;
        s_axi_control_bvalid <= 1'b1;
      end
      if (s_axi_control_bvalid && s_axi_control_bready) s_axi_control_bvalid <= 1'b0;
    end
  end
  assign s_axi_control_bresp = 2'b00;

  // register writes
  assign dop_push      = do_write && (wr_addr[AXIL_ADD_W-1:2] == 'h18>>2);
  assign dop_push_data = wr_data;

  always_ff @(posedge clk) begin
    if (!s_rst_n) begin
      r_ct_mem_addr <= '0;
      r_gid_offset  <= '0;
      r_bsk_addr    <= '0;
      r_ksk_addr    <= '0;
      r_bsk_avail   <= 1'b0;
      r_ksk_avail   <= 1'b0;
      r_use_bpip    <= 1'b1;
      r_use_bpip_opportunism <= 1'b0;
      r_bpip_timeout <= 32'd2000;
      p_reset_bsk_cache <= 1'b0;
      p_reset_ksk_cache <= 1'b0;
      p_reset_cache     <= 1'b0;
      error_sticky      <= '0;
    end else begin
      p_reset_bsk_cache <= 1'b0;
      p_reset_ksk_cache <= 1'b0;
      p_reset_cache     <= 1'b0;
      if (do_write) begin
        unique case (wr_addr[AXIL_ADD_W-1:2])
          'h020>>2: r_ct_mem_addr[31:0]  <= wr_data;
          'h024>>2: r_ct_mem_addr[63:32] <= wr_data;
          'h030>>2: r_gid_offset[31:0]   <= wr_data;
          'h034>>2: r_gid_offset[63:32]  <= wr_data;
          'h038>>2: {r_use_bpip_opportunism, r_use_bpip} <= wr_data[1:0];
          'h03C>>2: r_bpip_timeout <= wr_data;
          'h040>>2: r_bsk_addr[0][31:0]  <= wr_data;
          'h044>>2: r_bsk_addr[0][63:32] <= wr_data;
          'h048>>2: r_bsk_addr[1][31:0]  <= wr_data;
          'h04C>>2: r_bsk_addr[1][63:32] <= wr_data;
          'h050>>2: r_bsk_addr[2][31:0]  <= wr_data;
          'h054>>2: r_bsk_addr[2][63:32] <= wr_data;
          'h058>>2: r_bsk_addr[3][31:0]  <= wr_data;
          'h05C>>2: r_bsk_addr[3][63:32] <= wr_data;
          'h060>>2: r_ksk_addr[0][31:0]  <= wr_data;
          'h064>>2: r_ksk_addr[0][63:32] <= wr_data;
          'h068>>2: r_ksk_addr[1][31:0]  <= wr_data;
          'h06C>>2: r_ksk_addr[1][63:32] <= wr_data;
          'h070>>2: r_ksk_addr[2][31:0]  <= wr_data;
          'h074>>2: r_ksk_addr[2][63:32] <= wr_data;
          'h078>>2: r_ksk_addr[3][31:0]  <= wr_data;
          'h07C>>2: r_ksk_addr[3][63:32] <= wr_data;
          'h080>>2: begin
            r_bsk_avail <= wr_data[0];
            r_ksk_avail <= wr_data[1];
            p_reset_bsk_cache <= wr_data[8];
            p_reset_ksk_cache <= wr_data[9];
            p_reset_cache     <= wr_data[10];
          end
          'h01C>>2: error_sticky <= '0; // write clears
          default: ;
        endcase
      end
      // error accumulation
      error_sticky <= error_sticky | pep_error_32;
      if (do_write && (wr_addr[AXIL_ADD_W-1:2] == 'h01C>>2)) error_sticky <= '0;
    end
  end

  // read channel
  logic [31:0] rd_mux;
  assign s_axi_control_arready = !s_axi_control_rvalid || s_axi_control_rready;
  assign ar_hs = s_axi_control_arvalid && s_axi_control_arready;

  always_ff @(posedge clk) begin
    if (!s_rst_n) begin
      s_axi_control_rvalid <= 1'b0;
    end else begin
      if (ar_hs) begin
        s_axi_control_rvalid <= 1'b1;
        araddr_q <= s_axi_control_araddr;
      end else if (s_axi_control_rvalid && s_axi_control_rready) begin
        s_axi_control_rvalid <= 1'b0;
      end
    end
  end

  always_comb begin
    unique case (araddr_q[AXIL_ADD_W-1:2])
      'h000>>2: rd_mux = 32'h4850_554D;             // "HPUM"
      'h004>>2: rd_mux = 32'h0000_0001;             // version
      'h00C>>2: rd_mux = {14'd0, dop_wptr - dop_rptr, dop_full, dop_empty};
      'h010>>2: rd_mux = issued_cnt;
      'h014>>2: rd_mux = ack_cnt_total;
      'h01C>>2: rd_mux = error_sticky;
      'h020>>2: rd_mux = r_ct_mem_addr[31:0];
      'h024>>2: rd_mux = r_ct_mem_addr[63:32];
      'h030>>2: rd_mux = r_gid_offset[31:0];
      'h034>>2: rd_mux = r_gid_offset[63:32];
      'h038>>2: rd_mux = {30'd0, r_use_bpip_opportunism, r_use_bpip};
      'h03C>>2: rd_mux = r_bpip_timeout;
      'h080>>2: rd_mux = {30'd0, r_ksk_avail, r_bsk_avail};
      'h084>>2: rd_mux = {30'd0, ksk_rst_done_sticky, bsk_rst_done_sticky};
      'h090>>2: rd_mux = pem_ld_ack_cnt;
      'h094>>2: rd_mux = pem_st_ack_cnt;
      'h098>>2: rd_mux = pea_ack_cnt;
      'h09C>>2: rd_mux = pep_ack_cnt;
      'h0A0>>2: rd_mux = local_ack_cnt;
      'h0A8>>2: rd_mux = last_pbs_cycles;
      'h0B0>>2: rd_mux = cycle_cnt[31:0];
      'h0B4>>2: rd_mux = cycle_cnt[63:32];
      default:  rd_mux = 32'hDEAD_BEEF;
    endcase
  end
  assign s_axi_control_rdata = rd_mux;
  assign s_axi_control_rresp = 2'b00;

// ============================================================================================== --
// pe_pbs reset-done stickies
// ============================================================================================== --
  logic reset_bsk_cache_done, reset_ksk_cache_done;
  always_ff @(posedge clk) begin
    if (!s_rst_n) begin
      bsk_rst_done_sticky <= 1'b0;
      ksk_rst_done_sticky <= 1'b0;
    end else begin
      if (p_reset_bsk_cache)      bsk_rst_done_sticky <= 1'b0;
      else if (reset_bsk_cache_done) bsk_rst_done_sticky <= 1'b1;
      if (p_reset_ksk_cache)      ksk_rst_done_sticky <= 1'b0;
      else if (reset_ksk_cache_done) ksk_rst_done_sticky <= 1'b1;
    end
  end

// ============================================================================================== --
// regfile interconnect signals : pe_pbs <-> hpu_with_pe
// ============================================================================================== --
  logic                                   pep_regf_wr_req_vld;
  logic                                   pep_regf_wr_req_rdy;
  logic [REGF_WR_REQ_W-1:0]               pep_regf_wr_req;
  logic [REGF_COEF_NB-1:0]                pep_regf_wr_data_vld;
  logic [REGF_COEF_NB-1:0]                pep_regf_wr_data_rdy;
  logic [REGF_COEF_NB-1:0][MOD_Q_W-1:0]   pep_regf_wr_data;
  logic                                   regf_pep_wr_ack;
  logic                                   pep_regf_rd_req_vld;
  logic                                   pep_regf_rd_req_rdy;
  logic [REGF_RD_REQ_W-1:0]               pep_regf_rd_req;
  logic [REGF_COEF_NB-1:0]                regf_pep_rd_data_avail;
  logic [REGF_COEF_NB-1:0][MOD_Q_W-1:0]   regf_pep_rd_data;
  logic                                   regf_pep_rd_last_word;
  logic                                   regf_pep_rd_is_body;
  logic                                   regf_pep_rd_last_mask;

// ============================================================================================== --
// AXI wiring : internal arrayed <-> external flattened
// ============================================================================================== --
  // PEM (PC=1)
  logic [PEM_PC-1:0][axi_if_ct_axi_pkg::AXI4_ID_W-1:0]   pem_awid, pem_bid, pem_arid, pem_rid;
  logic [PEM_PC-1:0][axi_if_ct_axi_pkg::AXI4_ADD_W-1:0]  pem_awaddr, pem_araddr;
  logic [PEM_PC-1:0][AXI4_LEN_W-1:0]                     pem_awlen, pem_arlen;
  logic [PEM_PC-1:0][AXI4_SIZE_W-1:0]                    pem_awsize, pem_arsize;
  logic [PEM_PC-1:0][AXI4_BURST_W-1:0]                   pem_awburst, pem_arburst;
  logic [PEM_PC-1:0]                                     pem_awvalid, pem_awready, pem_wlast, pem_wvalid, pem_wready;
  logic [PEM_PC-1:0][axi_if_ct_axi_pkg::AXI4_DATA_W-1:0] pem_wdata, pem_rdata;
  logic [PEM_PC-1:0][axi_if_ct_axi_pkg::AXI4_STRB_W-1:0] pem_wstrb;
  logic [PEM_PC-1:0][AXI4_RESP_W-1:0]                    pem_bresp, pem_rresp;
  logic [PEM_PC-1:0]                                     pem_bvalid, pem_bready, pem_arvalid, pem_arready;
  logic [PEM_PC-1:0]                                     pem_rlast, pem_rvalid, pem_rready;

  assign m_axi_pem_awid    = pem_awid[0];
  assign m_axi_pem_awaddr  = pem_awaddr[0];
  assign m_axi_pem_awlen   = pem_awlen[0];
  assign m_axi_pem_awsize  = pem_awsize[0];
  assign m_axi_pem_awburst = pem_awburst[0];
  assign m_axi_pem_awvalid = pem_awvalid[0];
  assign pem_awready[0]    = m_axi_pem_awready;
  assign m_axi_pem_wdata   = pem_wdata[0];
  assign m_axi_pem_wstrb   = pem_wstrb[0];
  assign m_axi_pem_wlast   = pem_wlast[0];
  assign m_axi_pem_wvalid  = pem_wvalid[0];
  assign pem_wready[0]     = m_axi_pem_wready;
  assign pem_bid[0]        = m_axi_pem_bid;
  assign pem_bresp[0]      = m_axi_pem_bresp;
  assign pem_bvalid[0]     = m_axi_pem_bvalid;
  assign m_axi_pem_bready  = pem_bready[0];
  assign m_axi_pem_arid    = pem_arid[0];
  assign m_axi_pem_araddr  = pem_araddr[0];
  assign m_axi_pem_arlen   = pem_arlen[0];
  assign m_axi_pem_arsize  = pem_arsize[0];
  assign m_axi_pem_arburst = pem_arburst[0];
  assign m_axi_pem_arvalid = pem_arvalid[0];
  assign pem_arready[0]    = m_axi_pem_arready;
  assign pem_rid[0]        = m_axi_pem_rid;
  assign pem_rdata[0]      = m_axi_pem_rdata;
  assign pem_rresp[0]      = m_axi_pem_rresp;
  assign pem_rlast[0]      = m_axi_pem_rlast;
  assign pem_rvalid[0]     = m_axi_pem_rvalid;
  assign m_axi_pem_rready  = pem_rready[0];

  // BSK (PC=4)
  logic [BSK_PC-1:0][axi_if_bsk_axi_pkg::AXI4_ID_W-1:0]   bsk_arid, bsk_rid;
  logic [BSK_PC-1:0][axi_if_bsk_axi_pkg::AXI4_ADD_W-1:0]  bsk_araddr;
  logic [BSK_PC-1:0][AXI4_LEN_W-1:0]                      bsk_arlen;
  logic [BSK_PC-1:0][AXI4_SIZE_W-1:0]                     bsk_arsize;
  logic [BSK_PC-1:0][AXI4_BURST_W-1:0]                    bsk_arburst;
  logic [BSK_PC-1:0]                                      bsk_arvalid, bsk_arready;
  logic [BSK_PC-1:0][axi_if_bsk_axi_pkg::AXI4_DATA_W-1:0] bsk_rdata;
  logic [BSK_PC-1:0][AXI4_RESP_W-1:0]                     bsk_rresp;
  logic [BSK_PC-1:0]                                      bsk_rlast, bsk_rvalid, bsk_rready;

`define HPU_MINI_BSK_WIRE(i) \
  assign m_axi_bsk``i``_arid    = bsk_arid[i]; \
  assign m_axi_bsk``i``_araddr  = bsk_araddr[i]; \
  assign m_axi_bsk``i``_arlen   = bsk_arlen[i]; \
  assign m_axi_bsk``i``_arsize  = bsk_arsize[i]; \
  assign m_axi_bsk``i``_arburst = bsk_arburst[i]; \
  assign m_axi_bsk``i``_arvalid = bsk_arvalid[i]; \
  assign bsk_arready[i]         = m_axi_bsk``i``_arready; \
  assign bsk_rid[i]             = m_axi_bsk``i``_rid; \
  assign bsk_rdata[i]           = m_axi_bsk``i``_rdata; \
  assign bsk_rresp[i]           = m_axi_bsk``i``_rresp; \
  assign bsk_rlast[i]           = m_axi_bsk``i``_rlast; \
  assign bsk_rvalid[i]          = m_axi_bsk``i``_rvalid; \
  assign m_axi_bsk``i``_rready  = bsk_rready[i];

  `HPU_MINI_BSK_WIRE(0)
  `HPU_MINI_BSK_WIRE(1)
  `HPU_MINI_BSK_WIRE(2)
  `HPU_MINI_BSK_WIRE(3)

  // KSK (PC=4)
  logic [KSK_PC-1:0][axi_if_ksk_axi_pkg::AXI4_ID_W-1:0]   ksk_arid, ksk_rid;
  logic [KSK_PC-1:0][axi_if_ksk_axi_pkg::AXI4_ADD_W-1:0]  ksk_araddr;
  logic [KSK_PC-1:0][AXI4_LEN_W-1:0]                      ksk_arlen;
  logic [KSK_PC-1:0][AXI4_SIZE_W-1:0]                     ksk_arsize;
  logic [KSK_PC-1:0][AXI4_BURST_W-1:0]                    ksk_arburst;
  logic [KSK_PC-1:0]                                      ksk_arvalid, ksk_arready;
  logic [KSK_PC-1:0][axi_if_ksk_axi_pkg::AXI4_DATA_W-1:0] ksk_rdata;
  logic [KSK_PC-1:0][AXI4_RESP_W-1:0]                     ksk_rresp;
  logic [KSK_PC-1:0]                                      ksk_rlast, ksk_rvalid, ksk_rready;

`define HPU_MINI_KSK_WIRE(i) \
  assign m_axi_ksk``i``_arid    = ksk_arid[i]; \
  assign m_axi_ksk``i``_araddr  = ksk_araddr[i]; \
  assign m_axi_ksk``i``_arlen   = ksk_arlen[i]; \
  assign m_axi_ksk``i``_arsize  = ksk_arsize[i]; \
  assign m_axi_ksk``i``_arburst = ksk_arburst[i]; \
  assign m_axi_ksk``i``_arvalid = ksk_arvalid[i]; \
  assign ksk_arready[i]         = m_axi_ksk``i``_arready; \
  assign ksk_rid[i]             = m_axi_ksk``i``_rid; \
  assign ksk_rdata[i]           = m_axi_ksk``i``_rdata; \
  assign ksk_rresp[i]           = m_axi_ksk``i``_rresp; \
  assign ksk_rlast[i]           = m_axi_ksk``i``_rlast; \
  assign ksk_rvalid[i]          = m_axi_ksk``i``_rvalid; \
  assign m_axi_ksk``i``_rready  = ksk_rready[i];

  `HPU_MINI_KSK_WIRE(0)
  `HPU_MINI_KSK_WIRE(1)
  `HPU_MINI_KSK_WIRE(2)
  `HPU_MINI_KSK_WIRE(3)

// ============================================================================================== --
// pe_pbs error truncation for the sticky register
// ============================================================================================== --
  logic [PEP_ERROR_W-1:0] pep_error;
  logic [31:0] pep_error_32;
  generate
    if (PEP_ERROR_W >= 32) begin : gen_err_wide
      assign pep_error_32 = {|pep_error[PEP_ERROR_W-1:31], pep_error[30:0]};
    end else begin : gen_err_narrow
      assign pep_error_32 = 32'(pep_error);
    end
  endgenerate

// ============================================================================================== --
// hpu_with_pe : regfile + pe_mem + pe_alu
// ============================================================================================== --
  pem_counter_inc_t pem_rif_counter_inc;
  pea_counter_inc_t pea_rif_counter_inc;
  pem_info_t        pem_rif_info;

  logic [PEM_PC_MAX-1:0][axi_if_ct_axi_pkg::AXI4_ADD_W-1:0] ct_mem_addr;
  generate
    for (genvar i=0; i<PEM_PC_MAX; i++) begin : gen_ct_addr
      assign ct_mem_addr[i] = r_ct_mem_addr[axi_if_ct_axi_pkg::AXI4_ADD_W-1:0];
    end
  endgenerate

  hpu_with_pe hpu_with_pe (
    .clk     (clk),
    .s_rst_n (s_rst_n),

    .m_axi4_pem_awid   (pem_awid),
    .m_axi4_pem_awaddr (pem_awaddr),
    .m_axi4_pem_awlen  (pem_awlen),
    .m_axi4_pem_awsize (pem_awsize),
    .m_axi4_pem_awburst(pem_awburst),
    .m_axi4_pem_awvalid(pem_awvalid),
    .m_axi4_pem_awready(pem_awready),
    .m_axi4_pem_wdata  (pem_wdata),
    .m_axi4_pem_wstrb  (pem_wstrb),
    .m_axi4_pem_wlast  (pem_wlast),
    .m_axi4_pem_wvalid (pem_wvalid),
    .m_axi4_pem_wready (pem_wready),
    .m_axi4_pem_bid    (pem_bid),
    .m_axi4_pem_bresp  (pem_bresp),
    .m_axi4_pem_bvalid (pem_bvalid),
    .m_axi4_pem_bready (pem_bready),
    .m_axi4_pem_arid   (pem_arid),
    .m_axi4_pem_araddr (pem_araddr),
    .m_axi4_pem_arlen  (pem_arlen),
    .m_axi4_pem_arsize (pem_arsize),
    .m_axi4_pem_arburst(pem_arburst),
    .m_axi4_pem_arvalid(pem_arvalid),
    .m_axi4_pem_arready(pem_arready),
    .m_axi4_pem_rid    (pem_rid),
    .m_axi4_pem_rdata  (pem_rdata),
    .m_axi4_pem_rresp  (pem_rresp),
    .m_axi4_pem_rlast  (pem_rlast),
    .m_axi4_pem_rvalid (pem_rvalid),
    .m_axi4_pem_rready (pem_rready),

    .isc_pem_insn     (isc_pem_insn),
    .isc_pem_vld      (isc_pem_vld),
    .isc_pem_rdy      (isc_pem_rdy),
    .pem_isc_load_ack (pem_isc_load_ack),
    .pem_isc_store_ack(pem_isc_store_ack),

    .isc_pea_insn (isc_pea_insn),
    .isc_pea_vld  (isc_pea_vld),
    .isc_pea_rdy  (isc_pea_rdy),
    .pea_isc_ack  (pea_isc_ack),

    .pep_regf_wr_req_vld   (pep_regf_wr_req_vld),
    .pep_regf_wr_req_rdy   (pep_regf_wr_req_rdy),
    .pep_regf_wr_req       (pep_regf_wr_req),
    .pep_regf_wr_data_vld  (pep_regf_wr_data_vld),
    .pep_regf_wr_data_rdy  (pep_regf_wr_data_rdy),
    .pep_regf_wr_data      (pep_regf_wr_data),
    .regf_pep_wr_ack       (regf_pep_wr_ack),
    .pep_regf_rd_req_vld   (pep_regf_rd_req_vld),
    .pep_regf_rd_req_rdy   (pep_regf_rd_req_rdy),
    .pep_regf_rd_req       (pep_regf_rd_req),
    .regf_pep_rd_data_avail(regf_pep_rd_data_avail),
    .regf_pep_rd_data      (regf_pep_rd_data),
    .regf_pep_rd_last_word (regf_pep_rd_last_word),
    .regf_pep_rd_is_body   (regf_pep_rd_is_body),
    .regf_pep_rd_last_mask (regf_pep_rd_last_mask),

    .pem_rif_counter_inc (pem_rif_counter_inc),
    .pea_rif_counter_inc (pea_rif_counter_inc),
    .pem_rif_info        (pem_rif_info),

    .ct_mem_addr (ct_mem_addr)
  );

// ============================================================================================== --
// pe_pbs : KS + blind rotation + sample extract
// ============================================================================================== --
  logic [PEP_INFO_W-1:0]        pep_rif_info;
  logic [PEP_COUNTER_INC_W-1:0] pep_rif_counter_inc;

  logic [BSK_PC_MAX-1:0][axi_if_bsk_axi_pkg::AXI4_ADD_W-1:0] bsk_mem_addr;
  logic [KSK_PC_MAX-1:0][axi_if_ksk_axi_pkg::AXI4_ADD_W-1:0] ksk_mem_addr;
  generate
    for (genvar i=0; i<BSK_PC_MAX; i++) begin : gen_bsk_addr
      assign bsk_mem_addr[i] = (i < BSK_PC) ? r_bsk_addr[i][axi_if_bsk_axi_pkg::AXI4_ADD_W-1:0] : '0;
    end
    for (genvar i=0; i<KSK_PC_MAX; i++) begin : gen_ksk_addr
      assign ksk_mem_addr[i] = (i < KSK_PC) ? r_ksk_addr[i][axi_if_ksk_axi_pkg::AXI4_ADD_W-1:0] : '0;
    end
  endgenerate

  pe_pbs #(
    .MOD_MULT_TYPE         (MOD_MULT_TYPE),
    .REDUCT_TYPE           (REDUCT_TYPE),
    .MULT_TYPE             (MULT_TYPE),
    .PHI_MULT_TYPE         (PHI_MULT_TYPE),
    .PP_MOD_MULT_TYPE      (PP_MOD_MULT_TYPE),
    .PP_MULT_TYPE          (PP_MULT_TYPE),
    .MODSW_2_PRECISION_W   (MODSW_2_PRECISION_W),
    .MODSW_2_MULT_TYPE     (MODSW_2_MULT_TYPE),
    .MODSW_MULT_TYPE       (MODSW_MULT_TYPE),
    .RAM_LATENCY           (RAM_LATENCY),
    .URAM_LATENCY          (URAM_LATENCY),
    .ROM_LATENCY           (ROM_LATENCY),
    .TWD_IFNL_FILE_PREFIX  (TWD_IFNL_FILE_PREFIX),
    .TWD_PHRU_FILE_PREFIX  (TWD_PHRU_FILE_PREFIX),
    .TWD_GF64_FILE_PREFIX  (TWD_GF64_FILE_PREFIX),
    .INST_FIFO_DEPTH       (PEP_INST_FIFO_DEPTH),
    .REGF_RD_LATENCY       (REGF_RD_LATENCY),
    .KS_IF_COEF_NB         (KS_IF_COEF_NB),
    .KS_IF_SUBW_NB         (KS_IF_SUBW_NB),
    .PHYS_RAM_DEPTH        (PHYS_RAM_DEPTH)
  ) pe_pbs (
    .clk     (clk),
    .s_rst_n (s_rst_n),

    .inst               (isc_pep_insn),
    .inst_vld           (isc_pep_vld),
    .inst_rdy           (isc_pep_rdy),
    .inst_ack           (pep_inst_ack),
    .inst_ack_br_loop   (pep_inst_ack_br_loop),
    .inst_load_blwe_ack (pep_inst_load_blwe_ack),

    .pep_regf_wr_req_vld   (pep_regf_wr_req_vld),
    .pep_regf_wr_req_rdy   (pep_regf_wr_req_rdy),
    .pep_regf_wr_req       (pep_regf_wr_req),
    .pep_regf_wr_data_vld  (pep_regf_wr_data_vld),
    .pep_regf_wr_data_rdy  (pep_regf_wr_data_rdy),
    .pep_regf_wr_data      (pep_regf_wr_data),
    .regf_pep_wr_ack       (regf_pep_wr_ack),
    .pep_regf_rd_req_vld   (pep_regf_rd_req_vld),
    .pep_regf_rd_req_rdy   (pep_regf_rd_req_rdy),
    .pep_regf_rd_req       (pep_regf_rd_req),
    .regf_pep_rd_data_avail(regf_pep_rd_data_avail),
    .regf_pep_rd_data      (regf_pep_rd_data),
    .regf_pep_rd_last_word (regf_pep_rd_last_word),
    .regf_pep_rd_is_body   (regf_pep_rd_is_body),
    .regf_pep_rd_last_mask (regf_pep_rd_last_mask),

    .reset_bsk_cache      (p_reset_bsk_cache),
    .reset_bsk_cache_done (reset_bsk_cache_done),
    .bsk_mem_avail        (r_bsk_avail),
    .bsk_mem_addr         (bsk_mem_addr),
    .reset_ksk_cache      (p_reset_ksk_cache),
    .reset_ksk_cache_done (reset_ksk_cache_done),
    .ksk_mem_avail        (r_ksk_avail),
    .ksk_mem_addr         (ksk_mem_addr),
    .reset_cache          (p_reset_cache),

    .gid_offset (r_gid_offset[axi_if_glwe_axi_pkg::AXI4_ADD_W-1:0]),

    .twd_omg_ru_r_pow ('0),

    .use_bpip             (r_use_bpip),
    .use_bpip_opportunism (r_use_bpip_opportunism),
    .bpip_timeout         (r_bpip_timeout[TIMEOUT_CNT_W-1:0]),

    .m_axi4_bsk_arid   (bsk_arid),
    .m_axi4_bsk_araddr (bsk_araddr),
    .m_axi4_bsk_arlen  (bsk_arlen),
    .m_axi4_bsk_arsize (bsk_arsize),
    .m_axi4_bsk_arburst(bsk_arburst),
    .m_axi4_bsk_arvalid(bsk_arvalid),
    .m_axi4_bsk_arready(bsk_arready),
    .m_axi4_bsk_rid    (bsk_rid),
    .m_axi4_bsk_rdata  (bsk_rdata),
    .m_axi4_bsk_rresp  (bsk_rresp),
    .m_axi4_bsk_rlast  (bsk_rlast),
    .m_axi4_bsk_rvalid (bsk_rvalid),
    .m_axi4_bsk_rready (bsk_rready),

    .m_axi4_ksk_arid   (ksk_arid),
    .m_axi4_ksk_araddr (ksk_araddr),
    .m_axi4_ksk_arlen  (ksk_arlen),
    .m_axi4_ksk_arsize (ksk_arsize),
    .m_axi4_ksk_arburst(ksk_arburst),
    .m_axi4_ksk_arvalid(ksk_arvalid),
    .m_axi4_ksk_arready(ksk_arready),
    .m_axi4_ksk_rid    (ksk_rid),
    .m_axi4_ksk_rdata  (ksk_rdata),
    .m_axi4_ksk_rresp  (ksk_rresp),
    .m_axi4_ksk_rlast  (ksk_rlast),
    .m_axi4_ksk_rvalid (ksk_rvalid),
    .m_axi4_ksk_rready (ksk_rready),

    .m_axi4_glwe_arid   (m_axi_glwe_arid),
    .m_axi4_glwe_araddr (m_axi_glwe_araddr),
    .m_axi4_glwe_arlen  (m_axi_glwe_arlen),
    .m_axi4_glwe_arsize (m_axi_glwe_arsize),
    .m_axi4_glwe_arburst(m_axi_glwe_arburst),
    .m_axi4_glwe_arvalid(m_axi_glwe_arvalid),
    .m_axi4_glwe_arready(m_axi_glwe_arready),
    .m_axi4_glwe_rid    (m_axi_glwe_rid),
    .m_axi4_glwe_rdata  (m_axi_glwe_rdata),
    .m_axi4_glwe_rresp  (m_axi_glwe_rresp),
    .m_axi4_glwe_rlast  (m_axi_glwe_rlast),
    .m_axi4_glwe_rvalid (m_axi_glwe_rvalid),
    .m_axi4_glwe_rready (m_axi_glwe_rready),

    .error (pep_error),

    .pep_rif_info        (pep_rif_info),
    .pep_rif_counter_inc (pep_rif_counter_inc)
  );

endmodule
