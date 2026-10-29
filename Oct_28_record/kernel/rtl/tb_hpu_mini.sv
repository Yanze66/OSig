// ==============================================================================================
// tb_hpu_mini : single-PBS acceptance simulation for the hpu_mini core.
// Preloads BSK/KSK/LUT/ciphertext DDR images produced by hpu_key_tool, then runs
//   LD r2,cid0 -> PBS_F r4<-r2 (gid=1 MsgOnly) -> ST r4,cid1
// and dumps the output ciphertext for host-side decryption.
// Select the test case with +CASE=<n> (default 4 = raw value 5, non-zero carry).
// Data directory is set by the TB_DATA_DIR macro (defaults to "data").
// ==============================================================================================
`timescale 1ns/1ps

module tb_hpu_mini;
  import axi_if_common_param_pkg::*;

`ifndef TB_DATA_DIR
  `define TB_DATA_DIR "data"
`endif

  localparam int CLK_HALF = 5; // 100 MHz
  localparam int AXIL_ADD_W = 12;

  localparam int PEM_MEM_ADD_W  = 16;
  localparam int GLWE_MEM_ADD_W = 22;
  localparam int BSK_MEM_ADD_W  = 24;
  localparam int KSK_MEM_ADD_W  = 24;

  localparam int BSK_WORDS = 450048;
  localparam int KSK_WORDS = 337920;
  localparam int LUT_WORDS = 512;
  localparam int CT_WORDS  = 513;
  localparam int CT_SLOT_WORDS = 20480/32; // 640

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #(CLK_HALF) clk = ~clk;

  // ------------------------------------------------------------------------------------------
  // AXI-Lite control signals
  // ------------------------------------------------------------------------------------------
  logic [AXIL_ADD_W-1:0] axil_awaddr;
  logic                  axil_awvalid, axil_awready;
  logic [31:0]           axil_wdata;
  logic [3:0]            axil_wstrb = 4'hF;
  logic                  axil_wvalid, axil_wready;
  logic [1:0]            axil_bresp;
  logic                  axil_bvalid;
  logic                  axil_bready = 1'b1;
  logic [AXIL_ADD_W-1:0] axil_araddr;
  logic                  axil_arvalid, axil_arready;
  logic [31:0]           axil_rdata;
  logic [1:0]            axil_rresp;
  logic                  axil_rvalid;
  logic                  axil_rready = 1'b1;

  task automatic axil_write(input logic [AXIL_ADD_W-1:0] addr, input logic [31:0] data);
    @(posedge clk);
    axil_awaddr  <= addr;
    axil_awvalid <= 1'b1;
    axil_wdata   <= data;
    axil_wvalid  <= 1'b1;
    fork
      begin : wait_aw
        do @(posedge clk); while (!(axil_awvalid && axil_awready));
        axil_awvalid <= 1'b0;
      end
      begin : wait_w
        do @(posedge clk); while (!(axil_wvalid && axil_wready));
        axil_wvalid <= 1'b0;
      end
    join
    do @(posedge clk); while (!axil_bvalid);
  endtask

  task automatic axil_read(input logic [AXIL_ADD_W-1:0] addr, output logic [31:0] data);
    @(posedge clk);
    axil_araddr  <= addr;
    axil_arvalid <= 1'b1;
    do @(posedge clk); while (!(axil_arvalid && axil_arready));
    axil_arvalid <= 1'b0;
    do @(posedge clk); while (!axil_rvalid);
    data = axil_rdata;
  endtask

  // ------------------------------------------------------------------------------------------
  // PEM memory (full read/write)
  // ------------------------------------------------------------------------------------------
  logic [axi_if_ct_axi_pkg::AXI4_ID_W-1:0]    pem_awid, pem_bid, pem_arid, pem_rid;
  logic [axi_if_ct_axi_pkg::AXI4_ADD_W-1:0]   pem_awaddr, pem_araddr;
  logic [AXI4_LEN_W-1:0]                      pem_awlen, pem_arlen;
  logic [AXI4_SIZE_W-1:0]                     pem_awsize, pem_arsize;
  logic [AXI4_BURST_W-1:0]                    pem_awburst, pem_arburst;
  logic pem_awvalid, pem_awready, pem_wlast, pem_wvalid, pem_wready;
  logic [axi_if_ct_axi_pkg::AXI4_DATA_W-1:0]  pem_wdata, pem_rdata;
  logic [axi_if_ct_axi_pkg::AXI4_STRB_W-1:0]  pem_wstrb;
  logic [AXI4_RESP_W-1:0]                     pem_bresp, pem_rresp;
  logic pem_bvalid, pem_bready, pem_arvalid, pem_arready, pem_rlast, pem_rvalid, pem_rready;

  axi4_mem #(
    .DATA_WIDTH(axi_if_ct_axi_pkg::AXI4_DATA_W),
    .ADDR_WIDTH(PEM_MEM_ADD_W),
    .ID_WIDTH  (axi_if_ct_axi_pkg::AXI4_ID_W),
    .WR_CMD_BUF_DEPTH(8), .RD_CMD_BUF_DEPTH(8),
    .WR_DATA_LATENCY(10), .RD_DATA_LATENCY(20),
    .USE_WR_RANDOM(1'b1), .USE_RD_RANDOM(1'b1)
  ) mem_pem (
    .clk(clk), .rst(!rst_n),
    .s_axi4_awid(pem_awid), .s_axi4_awaddr(pem_awaddr[PEM_MEM_ADD_W-1:0]), .s_axi4_awlen(pem_awlen),
    .s_axi4_awsize(pem_awsize), .s_axi4_awburst(pem_awburst),
    .s_axi4_awlock(1'b0), .s_axi4_awcache(4'h0), .s_axi4_awprot(3'h0), .s_axi4_awqos(4'h0), .s_axi4_awregion(4'h0),
    .s_axi4_awvalid(pem_awvalid), .s_axi4_awready(pem_awready),
    .s_axi4_wdata(pem_wdata), .s_axi4_wstrb(pem_wstrb), .s_axi4_wlast(pem_wlast),
    .s_axi4_wvalid(pem_wvalid), .s_axi4_wready(pem_wready),
    .s_axi4_bid(pem_bid), .s_axi4_bresp(pem_bresp), .s_axi4_bvalid(pem_bvalid), .s_axi4_bready(pem_bready),
    .s_axi4_arid(pem_arid), .s_axi4_araddr(pem_araddr[PEM_MEM_ADD_W-1:0]), .s_axi4_arlen(pem_arlen),
    .s_axi4_arsize(pem_arsize), .s_axi4_arburst(pem_arburst),
    .s_axi4_arlock(1'b0), .s_axi4_arcache(4'h0), .s_axi4_arprot(3'h0), .s_axi4_arqos(4'h0), .s_axi4_arregion(4'h0),
    .s_axi4_arvalid(pem_arvalid), .s_axi4_arready(pem_arready),
    .s_axi4_rid(pem_rid), .s_axi4_rdata(pem_rdata), .s_axi4_rresp(pem_rresp), .s_axi4_rlast(pem_rlast),
    .s_axi4_rvalid(pem_rvalid), .s_axi4_rready(pem_rready)
  );

  // ------------------------------------------------------------------------------------------
  // GLWE memory (read-only from DUT)
  // ------------------------------------------------------------------------------------------
  logic [axi_if_glwe_axi_pkg::AXI4_ID_W-1:0]   glwe_arid, glwe_rid;
  logic [axi_if_glwe_axi_pkg::AXI4_ADD_W-1:0]  glwe_araddr;
  logic [AXI4_LEN_W-1:0]  glwe_arlen;
  logic [AXI4_SIZE_W-1:0] glwe_arsize;
  logic [AXI4_BURST_W-1:0] glwe_arburst;
  logic glwe_arvalid, glwe_arready, glwe_rlast, glwe_rvalid, glwe_rready;
  logic [axi_if_glwe_axi_pkg::AXI4_DATA_W-1:0] glwe_rdata;
  logic [AXI4_RESP_W-1:0] glwe_rresp;

  axi4_mem #(
    .DATA_WIDTH(axi_if_glwe_axi_pkg::AXI4_DATA_W),
    .ADDR_WIDTH(GLWE_MEM_ADD_W),
    .ID_WIDTH  (axi_if_glwe_axi_pkg::AXI4_ID_W),
    .WR_CMD_BUF_DEPTH(8), .RD_CMD_BUF_DEPTH(8),
    .WR_DATA_LATENCY(10), .RD_DATA_LATENCY(20),
    .USE_WR_RANDOM(1'b0), .USE_RD_RANDOM(1'b1)
  ) mem_glwe (
    .clk(clk), .rst(!rst_n),
    .s_axi4_awid('0), .s_axi4_awaddr('0), .s_axi4_awlen('0), .s_axi4_awsize('0), .s_axi4_awburst(2'b01),
    .s_axi4_awlock(1'b0), .s_axi4_awcache(4'h0), .s_axi4_awprot(3'h0), .s_axi4_awqos(4'h0), .s_axi4_awregion(4'h0),
    .s_axi4_awvalid(1'b0), .s_axi4_awready(),
    .s_axi4_wdata('0), .s_axi4_wstrb('0), .s_axi4_wlast(1'b0), .s_axi4_wvalid(1'b0), .s_axi4_wready(),
    .s_axi4_bid(), .s_axi4_bresp(), .s_axi4_bvalid(), .s_axi4_bready(1'b1),
    .s_axi4_arid(glwe_arid), .s_axi4_araddr(glwe_araddr[GLWE_MEM_ADD_W-1:0]), .s_axi4_arlen(glwe_arlen),
    .s_axi4_arsize(glwe_arsize), .s_axi4_arburst(glwe_arburst),
    .s_axi4_arlock(1'b0), .s_axi4_arcache(4'h0), .s_axi4_arprot(3'h0), .s_axi4_arqos(4'h0), .s_axi4_arregion(4'h0),
    .s_axi4_arvalid(glwe_arvalid), .s_axi4_arready(glwe_arready),
    .s_axi4_rid(glwe_rid), .s_axi4_rdata(glwe_rdata), .s_axi4_rresp(glwe_rresp), .s_axi4_rlast(glwe_rlast),
    .s_axi4_rvalid(glwe_rvalid), .s_axi4_rready(glwe_rready)
  );

  // ------------------------------------------------------------------------------------------
  // BSK / KSK memories (read-only from DUT), 4 PCs each
  // ------------------------------------------------------------------------------------------
  logic [3:0][axi_if_bsk_axi_pkg::AXI4_ID_W-1:0]   bsk_arid, bsk_rid;
  logic [3:0][axi_if_bsk_axi_pkg::AXI4_ADD_W-1:0]  bsk_araddr;
  logic [3:0][AXI4_LEN_W-1:0]  bsk_arlen;
  logic [3:0][AXI4_SIZE_W-1:0] bsk_arsize;
  logic [3:0][AXI4_BURST_W-1:0] bsk_arburst;
  logic [3:0] bsk_arvalid, bsk_arready, bsk_rlast, bsk_rvalid, bsk_rready;
  logic [3:0][axi_if_bsk_axi_pkg::AXI4_DATA_W-1:0] bsk_rdata;
  logic [3:0][AXI4_RESP_W-1:0] bsk_rresp;

  logic [3:0][axi_if_ksk_axi_pkg::AXI4_ID_W-1:0]   ksk_arid, ksk_rid;
  logic [3:0][axi_if_ksk_axi_pkg::AXI4_ADD_W-1:0]  ksk_araddr;
  logic [3:0][AXI4_LEN_W-1:0]  ksk_arlen;
  logic [3:0][AXI4_SIZE_W-1:0] ksk_arsize;
  logic [3:0][AXI4_BURST_W-1:0] ksk_arburst;
  logic [3:0] ksk_arvalid, ksk_arready, ksk_rlast, ksk_rvalid, ksk_rready;
  logic [3:0][axi_if_ksk_axi_pkg::AXI4_DATA_W-1:0] ksk_rdata;
  logic [3:0][AXI4_RESP_W-1:0] ksk_rresp;

  generate
    for (genvar g=0; g<4; g++) begin : gen_bsk
      axi4_mem #(
        .DATA_WIDTH(axi_if_bsk_axi_pkg::AXI4_DATA_W),
        .ADDR_WIDTH(BSK_MEM_ADD_W),
        .ID_WIDTH  (axi_if_bsk_axi_pkg::AXI4_ID_W),
        .WR_CMD_BUF_DEPTH(8), .RD_CMD_BUF_DEPTH(8),
        .WR_DATA_LATENCY(10), .RD_DATA_LATENCY(20 + 7*g),
        .USE_WR_RANDOM(1'b0), .USE_RD_RANDOM(1'b1)
      ) mem_bsk (
        .clk(clk), .rst(!rst_n),
        .s_axi4_awid('0), .s_axi4_awaddr('0), .s_axi4_awlen('0), .s_axi4_awsize('0), .s_axi4_awburst(2'b01),
        .s_axi4_awlock(1'b0), .s_axi4_awcache(4'h0), .s_axi4_awprot(3'h0), .s_axi4_awqos(4'h0), .s_axi4_awregion(4'h0),
        .s_axi4_awvalid(1'b0), .s_axi4_awready(),
        .s_axi4_wdata('0), .s_axi4_wstrb('0), .s_axi4_wlast(1'b0), .s_axi4_wvalid(1'b0), .s_axi4_wready(),
        .s_axi4_bid(), .s_axi4_bresp(), .s_axi4_bvalid(), .s_axi4_bready(1'b1),
        .s_axi4_arid(bsk_arid[g]), .s_axi4_araddr(bsk_araddr[g][BSK_MEM_ADD_W-1:0]), .s_axi4_arlen(bsk_arlen[g]),
        .s_axi4_arsize(bsk_arsize[g]), .s_axi4_arburst(bsk_arburst[g]),
        .s_axi4_arlock(1'b0), .s_axi4_arcache(4'h0), .s_axi4_arprot(3'h0), .s_axi4_arqos(4'h0), .s_axi4_arregion(4'h0),
        .s_axi4_arvalid(bsk_arvalid[g]), .s_axi4_arready(bsk_arready[g]),
        .s_axi4_rid(bsk_rid[g]), .s_axi4_rdata(bsk_rdata[g]), .s_axi4_rresp(bsk_rresp[g]), .s_axi4_rlast(bsk_rlast[g]),
        .s_axi4_rvalid(bsk_rvalid[g]), .s_axi4_rready(bsk_rready[g])
      );
      initial begin
        if ($test$plusargs("GOLDEN"))
          $readmemh($sformatf("%s/key/bsk_%0d.hex", `TB_GOLDEN_DIR, g), mem_bsk.axi4_ram_ct_wr.mem, 0, BSK_WORDS-1);
        else
          $readmemh($sformatf("%s/bsk_pc%0d.memh", `TB_DATA_DIR, g), mem_bsk.axi4_ram_ct_wr.mem, 0, BSK_WORDS-1);
      end
    end
    for (genvar g=0; g<4; g++) begin : gen_ksk
      axi4_mem #(
        .DATA_WIDTH(axi_if_ksk_axi_pkg::AXI4_DATA_W),
        .ADDR_WIDTH(KSK_MEM_ADD_W),
        .ID_WIDTH  (axi_if_ksk_axi_pkg::AXI4_ID_W),
        .WR_CMD_BUF_DEPTH(8), .RD_CMD_BUF_DEPTH(8),
        .WR_DATA_LATENCY(10), .RD_DATA_LATENCY(20 + 7*g),
        .USE_WR_RANDOM(1'b0), .USE_RD_RANDOM(1'b1)
      ) mem_ksk (
        .clk(clk), .rst(!rst_n),
        .s_axi4_awid('0), .s_axi4_awaddr('0), .s_axi4_awlen('0), .s_axi4_awsize('0), .s_axi4_awburst(2'b01),
        .s_axi4_awlock(1'b0), .s_axi4_awcache(4'h0), .s_axi4_awprot(3'h0), .s_axi4_awqos(4'h0), .s_axi4_awregion(4'h0),
        .s_axi4_awvalid(1'b0), .s_axi4_awready(),
        .s_axi4_wdata('0), .s_axi4_wstrb('0), .s_axi4_wlast(1'b0), .s_axi4_wvalid(1'b0), .s_axi4_wready(),
        .s_axi4_bid(), .s_axi4_bresp(), .s_axi4_bvalid(), .s_axi4_bready(1'b1),
        .s_axi4_arid(ksk_arid[g]), .s_axi4_araddr(ksk_araddr[g][KSK_MEM_ADD_W-1:0]), .s_axi4_arlen(ksk_arlen[g]),
        .s_axi4_arsize(ksk_arsize[g]), .s_axi4_arburst(ksk_arburst[g]),
        .s_axi4_arlock(1'b0), .s_axi4_arcache(4'h0), .s_axi4_arprot(3'h0), .s_axi4_arqos(4'h0), .s_axi4_arregion(4'h0),
        .s_axi4_arvalid(ksk_arvalid[g]), .s_axi4_arready(ksk_arready[g]),
        .s_axi4_rid(ksk_rid[g]), .s_axi4_rdata(ksk_rdata[g]), .s_axi4_rresp(ksk_rresp[g]), .s_axi4_rlast(ksk_rlast[g]),
        .s_axi4_rvalid(ksk_rvalid[g]), .s_axi4_rready(ksk_rready[g])
      );
      initial begin
        if ($test$plusargs("GOLDEN"))
          $readmemh($sformatf("%s/key/ksk_%0d.hex", `TB_GOLDEN_DIR, g), mem_ksk.axi4_ram_ct_wr.mem, 0, KSK_WORDS-1);
        else
          $readmemh($sformatf("%s/ksk_pc%0d.memh", `TB_DATA_DIR, g), mem_ksk.axi4_ram_ct_wr.mem, 0, KSK_WORDS-1);
      end
    end
  endgenerate

  // ------------------------------------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------------------------------------
  hpu_mini dut (
    .ap_clk(clk), .ap_rst_n(rst_n),
    .s_axi_control_awaddr(axil_awaddr), .s_axi_control_awvalid(axil_awvalid), .s_axi_control_awready(axil_awready),
    .s_axi_control_wdata(axil_wdata), .s_axi_control_wstrb(axil_wstrb), .s_axi_control_wvalid(axil_wvalid), .s_axi_control_wready(axil_wready),
    .s_axi_control_bresp(axil_bresp), .s_axi_control_bvalid(axil_bvalid), .s_axi_control_bready(axil_bready),
    .s_axi_control_araddr(axil_araddr), .s_axi_control_arvalid(axil_arvalid), .s_axi_control_arready(axil_arready),
    .s_axi_control_rdata(axil_rdata), .s_axi_control_rresp(axil_rresp), .s_axi_control_rvalid(axil_rvalid), .s_axi_control_rready(axil_rready),

    .m_axi_pem_awid(pem_awid), .m_axi_pem_awaddr(pem_awaddr), .m_axi_pem_awlen(pem_awlen),
    .m_axi_pem_awsize(pem_awsize), .m_axi_pem_awburst(pem_awburst),
    .m_axi_pem_awvalid(pem_awvalid), .m_axi_pem_awready(pem_awready),
    .m_axi_pem_wdata(pem_wdata), .m_axi_pem_wstrb(pem_wstrb), .m_axi_pem_wlast(pem_wlast),
    .m_axi_pem_wvalid(pem_wvalid), .m_axi_pem_wready(pem_wready),
    .m_axi_pem_bid(pem_bid), .m_axi_pem_bresp(pem_bresp), .m_axi_pem_bvalid(pem_bvalid), .m_axi_pem_bready(pem_bready),
    .m_axi_pem_arid(pem_arid), .m_axi_pem_araddr(pem_araddr), .m_axi_pem_arlen(pem_arlen),
    .m_axi_pem_arsize(pem_arsize), .m_axi_pem_arburst(pem_arburst),
    .m_axi_pem_arvalid(pem_arvalid), .m_axi_pem_arready(pem_arready),
    .m_axi_pem_rid(pem_rid), .m_axi_pem_rdata(pem_rdata), .m_axi_pem_rresp(pem_rresp), .m_axi_pem_rlast(pem_rlast),
    .m_axi_pem_rvalid(pem_rvalid), .m_axi_pem_rready(pem_rready),

    .m_axi_glwe_arid(glwe_arid), .m_axi_glwe_araddr(glwe_araddr), .m_axi_glwe_arlen(glwe_arlen),
    .m_axi_glwe_arsize(glwe_arsize), .m_axi_glwe_arburst(glwe_arburst),
    .m_axi_glwe_arvalid(glwe_arvalid), .m_axi_glwe_arready(glwe_arready),
    .m_axi_glwe_rid(glwe_rid), .m_axi_glwe_rdata(glwe_rdata), .m_axi_glwe_rresp(glwe_rresp), .m_axi_glwe_rlast(glwe_rlast),
    .m_axi_glwe_rvalid(glwe_rvalid), .m_axi_glwe_rready(glwe_rready),

    .m_axi_bsk0_arid(bsk_arid[0]), .m_axi_bsk0_araddr(bsk_araddr[0]), .m_axi_bsk0_arlen(bsk_arlen[0]),
    .m_axi_bsk0_arsize(bsk_arsize[0]), .m_axi_bsk0_arburst(bsk_arburst[0]),
    .m_axi_bsk0_arvalid(bsk_arvalid[0]), .m_axi_bsk0_arready(bsk_arready[0]),
    .m_axi_bsk0_rid(bsk_rid[0]), .m_axi_bsk0_rdata(bsk_rdata[0]), .m_axi_bsk0_rresp(bsk_rresp[0]),
    .m_axi_bsk0_rlast(bsk_rlast[0]), .m_axi_bsk0_rvalid(bsk_rvalid[0]), .m_axi_bsk0_rready(bsk_rready[0]),
    .m_axi_bsk1_arid(bsk_arid[1]), .m_axi_bsk1_araddr(bsk_araddr[1]), .m_axi_bsk1_arlen(bsk_arlen[1]),
    .m_axi_bsk1_arsize(bsk_arsize[1]), .m_axi_bsk1_arburst(bsk_arburst[1]),
    .m_axi_bsk1_arvalid(bsk_arvalid[1]), .m_axi_bsk1_arready(bsk_arready[1]),
    .m_axi_bsk1_rid(bsk_rid[1]), .m_axi_bsk1_rdata(bsk_rdata[1]), .m_axi_bsk1_rresp(bsk_rresp[1]),
    .m_axi_bsk1_rlast(bsk_rlast[1]), .m_axi_bsk1_rvalid(bsk_rvalid[1]), .m_axi_bsk1_rready(bsk_rready[1]),
    .m_axi_bsk2_arid(bsk_arid[2]), .m_axi_bsk2_araddr(bsk_araddr[2]), .m_axi_bsk2_arlen(bsk_arlen[2]),
    .m_axi_bsk2_arsize(bsk_arsize[2]), .m_axi_bsk2_arburst(bsk_arburst[2]),
    .m_axi_bsk2_arvalid(bsk_arvalid[2]), .m_axi_bsk2_arready(bsk_arready[2]),
    .m_axi_bsk2_rid(bsk_rid[2]), .m_axi_bsk2_rdata(bsk_rdata[2]), .m_axi_bsk2_rresp(bsk_rresp[2]),
    .m_axi_bsk2_rlast(bsk_rlast[2]), .m_axi_bsk2_rvalid(bsk_rvalid[2]), .m_axi_bsk2_rready(bsk_rready[2]),
    .m_axi_bsk3_arid(bsk_arid[3]), .m_axi_bsk3_araddr(bsk_araddr[3]), .m_axi_bsk3_arlen(bsk_arlen[3]),
    .m_axi_bsk3_arsize(bsk_arsize[3]), .m_axi_bsk3_arburst(bsk_arburst[3]),
    .m_axi_bsk3_arvalid(bsk_arvalid[3]), .m_axi_bsk3_arready(bsk_arready[3]),
    .m_axi_bsk3_rid(bsk_rid[3]), .m_axi_bsk3_rdata(bsk_rdata[3]), .m_axi_bsk3_rresp(bsk_rresp[3]),
    .m_axi_bsk3_rlast(bsk_rlast[3]), .m_axi_bsk3_rvalid(bsk_rvalid[3]), .m_axi_bsk3_rready(bsk_rready[3]),

    .m_axi_ksk0_arid(ksk_arid[0]), .m_axi_ksk0_araddr(ksk_araddr[0]), .m_axi_ksk0_arlen(ksk_arlen[0]),
    .m_axi_ksk0_arsize(ksk_arsize[0]), .m_axi_ksk0_arburst(ksk_arburst[0]),
    .m_axi_ksk0_arvalid(ksk_arvalid[0]), .m_axi_ksk0_arready(ksk_arready[0]),
    .m_axi_ksk0_rid(ksk_rid[0]), .m_axi_ksk0_rdata(ksk_rdata[0]), .m_axi_ksk0_rresp(ksk_rresp[0]),
    .m_axi_ksk0_rlast(ksk_rlast[0]), .m_axi_ksk0_rvalid(ksk_rvalid[0]), .m_axi_ksk0_rready(ksk_rready[0]),
    .m_axi_ksk1_arid(ksk_arid[1]), .m_axi_ksk1_araddr(ksk_araddr[1]), .m_axi_ksk1_arlen(ksk_arlen[1]),
    .m_axi_ksk1_arsize(ksk_arsize[1]), .m_axi_ksk1_arburst(ksk_arburst[1]),
    .m_axi_ksk1_arvalid(ksk_arvalid[1]), .m_axi_ksk1_arready(ksk_arready[1]),
    .m_axi_ksk1_rid(ksk_rid[1]), .m_axi_ksk1_rdata(ksk_rdata[1]), .m_axi_ksk1_rresp(ksk_rresp[1]),
    .m_axi_ksk1_rlast(ksk_rlast[1]), .m_axi_ksk1_rvalid(ksk_rvalid[1]), .m_axi_ksk1_rready(ksk_rready[1]),
    .m_axi_ksk2_arid(ksk_arid[2]), .m_axi_ksk2_araddr(ksk_araddr[2]), .m_axi_ksk2_arlen(ksk_arlen[2]),
    .m_axi_ksk2_arsize(ksk_arsize[2]), .m_axi_ksk2_arburst(ksk_arburst[2]),
    .m_axi_ksk2_arvalid(ksk_arvalid[2]), .m_axi_ksk2_arready(ksk_arready[2]),
    .m_axi_ksk2_rid(ksk_rid[2]), .m_axi_ksk2_rdata(ksk_rdata[2]), .m_axi_ksk2_rresp(ksk_rresp[2]),
    .m_axi_ksk2_rlast(ksk_rlast[2]), .m_axi_ksk2_rvalid(ksk_rvalid[2]), .m_axi_ksk2_rready(ksk_rready[2]),
    .m_axi_ksk3_arid(ksk_arid[3]), .m_axi_ksk3_araddr(ksk_araddr[3]), .m_axi_ksk3_arlen(ksk_arlen[3]),
    .m_axi_ksk3_arsize(ksk_arsize[3]), .m_axi_ksk3_arburst(ksk_arburst[3]),
    .m_axi_ksk3_arvalid(ksk_arvalid[3]), .m_axi_ksk3_arready(ksk_arready[3]),
    .m_axi_ksk3_rid(ksk_rid[3]), .m_axi_ksk3_rdata(ksk_rdata[3]), .m_axi_ksk3_rresp(ksk_rresp[3]),
    .m_axi_ksk3_rlast(ksk_rlast[3]), .m_axi_ksk3_rvalid(ksk_rvalid[3]), .m_axi_ksk3_rready(ksk_rready[3]),

    .interrupt()
  );

  // ------------------------------------------------------------------------------------------
  // GLWE / PEM preload
  // ------------------------------------------------------------------------------------------
  int case_id = 4;
  int golden = 0;
  initial begin
    if ($test$plusargs("GOLDEN")) golden = 1;
    if (!$value$plusargs("CASE=%d", case_id)) case_id = 4;
    if (golden) begin
      int gfd;
      string gf;
      for (int gid=0; gid<256; gid++) begin
        gf = $sformatf("%s/glwe/glwe_%02x.hex", `TB_GOLDEN_DIR, gid);
        gfd = $fopen(gf, "r");
        if (gfd) begin
          $fclose(gfd);
          $readmemh(gf, mem_glwe.axi4_ram_ct_wr.mem, gid*512, gid*512+LUT_WORDS-1);
        end
      end
      $readmemh($sformatf("%s/blwe/input/blwe_0000_0.hex", `TB_GOLDEN_DIR), mem_pem.axi4_ram_ct_wr.mem, 0, CT_WORDS-1);
      $readmemh($sformatf("%s/blwe/input/blwe_0001_0.hex", `TB_GOLDEN_DIR), mem_pem.axi4_ram_ct_wr.mem, CT_SLOT_WORDS, CT_SLOT_WORDS+CT_WORDS-1);
      $display("[TB] GOLDEN stimulus preloaded");
    end else begin
      $readmemh($sformatf("%s/lut_gid0_None.memh",   `TB_DATA_DIR), mem_glwe.axi4_ram_ct_wr.mem, 0,    LUT_WORDS-1);
      $readmemh($sformatf("%s/lut_gid1_MsgOnly.memh",`TB_DATA_DIR), mem_glwe.axi4_ram_ct_wr.mem, 512,  512+LUT_WORDS-1);
      $readmemh($sformatf("%s/msgonly_in_%0d.memh", `TB_DATA_DIR, case_id), mem_pem.axi4_ram_ct_wr.mem, 0, CT_WORDS-1);
      $display("[TB] case %0d preloaded", case_id);
    end
  end

  // ------------------------------------------------------------------------------------------
  // Transaction probes
  // ------------------------------------------------------------------------------------------
  int pep_wr_beats = 0;
  always @(posedge clk) begin
    if (pem_awvalid && pem_awready)
      $display("[TB] PEM_AW addr=0x%h len=%0d t=%0t", pem_awaddr, pem_awlen, $time);
    if (pem_arvalid && pem_arready)
      $display("[TB] PEM_AR addr=0x%h len=%0d t=%0t", pem_araddr, pem_arlen, $time);
    if (dut.pep_regf_wr_req_vld && dut.pep_regf_wr_req_rdy)
      $display("[TB] PEP_REGF_WR_REQ raw=0x%h t=%0t", dut.pep_regf_wr_req, $time);
    if (dut.pep_regf_wr_data_vld[0] && dut.pep_regf_wr_data_rdy[0]) pep_wr_beats <= pep_wr_beats + 1;
    if (dut.regf_pep_wr_ack)
      $display("[TB] PEP_REGF_WR_ACK beats=%0d t=%0t", pep_wr_beats, $time);
    // data-path probes: where does X come from?
    if (dut.pep_regf_wr_data_vld[0] && dut.pep_regf_wr_data_rdy[0] && pep_wr_data_seen < 3) begin
      $display("[TB] PEP_WR_DATA[%0d] = 0x%h (unknown=%b) t=%0t",
               pep_wr_data_seen, dut.pep_regf_wr_data[0], $isunknown(dut.pep_regf_wr_data[0]), $time);
      pep_wr_data_seen <= pep_wr_data_seen + 1;
    end
    if (dut.hpu_with_pe.regf_pem_rd_data_avail[0] && pem_rd_data_seen < 3) begin
      $display("[TB] PEM_RD_DATA[%0d] = 0x%h (unknown=%b) t=%0t",
               pem_rd_data_seen, dut.hpu_with_pe.regf_pem_rd_data[0], $isunknown(dut.hpu_with_pe.regf_pem_rd_data[0]), $time);
      pem_rd_data_seen <= pem_rd_data_seen + 1;
    end
    if (pem_wvalid && pem_wready && pem_w_seen < 3) begin
      $display("[TB] PEM_WDATA[%0d] lane0=0x%h (unknown=%b) t=%0t",
               pem_w_seen, pem_wdata[63:0], $isunknown(pem_wdata), $time);
      pem_w_seen <= pem_w_seen + 1;
    end
  end
  int pep_wr_data_seen = 0;
  int pem_rd_data_seen = 0;
  int pem_w_seen = 0;
  // cumulative AR counters + first-sight X bisect probes
  int glwe_ar_cnt = 0, bsk_ar_cnt = 0, ksk_ar_cnt = 0;
  int decomp_x_cnt = 0, bsk_x_cnt = 0, nttacc_x_cnt = 0;
  int sxt0_x_cnt = 0, sxt1_x_cnt = 0;
  always @(posedge clk) begin
    if (glwe_arvalid && glwe_arready) glwe_ar_cnt <= glwe_ar_cnt + 1;
    if (bsk_arvalid[0] && bsk_arready[0]) bsk_ar_cnt <= bsk_ar_cnt + 1;
    if (ksk_arvalid[0] && ksk_arready[0]) ksk_ar_cnt <= ksk_ar_cnt + 1;
    // first-unknown bisect probes + unknown beat counters
    if (dut.pe_pbs.decomp_ntt_data_avail[0][0] && $isunknown(dut.pe_pbs.decomp_ntt_data[0][0])) begin
      decomp_x_cnt <= decomp_x_cnt + 1;
      if (decomp_x_cnt == 0) $display("[TB] FIRST_X decomp_ntt_data t=%0t", $time);
    end
    if (dut.pe_pbs.bsk_vld[0][0][0] && $isunknown(dut.pe_pbs.bsk[0][0][0])) begin
      bsk_x_cnt <= bsk_x_cnt + 1;
      if (bsk_x_cnt == 0) $display("[TB] FIRST_X bsk t=%0t", $time);
    end
    if (dut.pe_pbs.ntt_acc_data_avail[0][0] && $isunknown(dut.pe_pbs.ntt_acc_data[0][0])) begin
      nttacc_x_cnt <= nttacc_x_cnt + 1;
      if (nttacc_x_cnt == 0) $display("[TB] FIRST_X ntt_acc_data t=%0t", $time);
    end
    if ($isunknown(dut.pe_pbs.pe_pbs_with_entry_assembly.pe_pbs_with_entry_main.pep_mmacc_splitc_main.pep_mmacc_splitc_main_sxt.pep_mmacc_splitc_sxt_final.in0_data_data) &&
        dut.pe_pbs.pe_pbs_with_entry_assembly.pe_pbs_with_entry_main.pep_mmacc_splitc_main.pep_mmacc_splitc_main_sxt.pep_mmacc_splitc_sxt_final.in0_data_vld) begin
      sxt0_x_cnt <= sxt0_x_cnt + 1;
      if (sxt0_x_cnt == 0) $display("[TB] FIRST_X sxt_in0 t=%0t", $time);
    end
    if ($isunknown(dut.pe_pbs.pe_pbs_with_entry_assembly.pe_pbs_with_entry_main.pep_mmacc_splitc_main.pep_mmacc_splitc_main_sxt.pep_mmacc_splitc_sxt_final.in1_data_data) &&
        dut.pe_pbs.pe_pbs_with_entry_assembly.pe_pbs_with_entry_main.pep_mmacc_splitc_main.pep_mmacc_splitc_main_sxt.pep_mmacc_splitc_sxt_final.in1_data_vld) begin
      sxt1_x_cnt <= sxt1_x_cnt + 1;
      if (sxt1_x_cnt == 0) $display("[TB] FIRST_X sxt_in1 t=%0t", $time);
    end
  end

  // ------------------------------------------------------------------------------------------
  // KS result dump (one line per accepted beat, 204-bit hex)
  // ------------------------------------------------------------------------------------------
  int ks_fd;
  initial begin
    #1; // after case_id parse
    ks_fd = $fopen($sformatf("%s/ks_dump_case%0d.txt", `TB_DATA_DIR, case_id), "w");
  end
  always @(posedge clk) begin
    if (dut.pe_pbs.ks_seq_result_vld && dut.pe_pbs.ks_seq_result_rdy)
      $fdisplay(ks_fd, "%h", dut.pe_pbs.ks_seq_result);
  end

  // ------------------------------------------------------------------------------------------
  // Heartbeat / watchdog
  // ------------------------------------------------------------------------------------------
  initial begin
    forever begin
      #200us;
      $display("[TB] heartbeat t=%0t pep(vld=%b rdy=%b) ldb(vld=%b rdy=%b done=%b blwe_ack=%b) ks_cmd=%b ks_res(v=%b r=%b) br_cmd=%b bsk_ar=%b ksk_ar=%b glwe_ar=%b regf_rd(v=%b r=%b)",
        $time,
        dut.isc_pep_vld, dut.isc_pep_rdy,
        dut.pe_pbs.seq_ldb_vld, dut.pe_pbs.seq_ldb_rdy, dut.pe_pbs.ldb_seq_done, dut.pep_inst_load_blwe_ack,
        dut.pe_pbs.seq_ks_cmd_avail, dut.pe_pbs.ks_seq_result_vld, dut.pe_pbs.ks_seq_result_rdy,
        dut.pe_pbs.br_batch_cmd_avail,
        |bsk_arvalid, |ksk_arvalid, glwe_arvalid,
        dut.pep_regf_rd_req_vld, dut.pep_regf_rd_req_rdy);
    end
  end
  initial begin
    #40ms;
    $display("[TB] TIMEOUT");
    $fatal(1, "watchdog timeout");
  end

  // ------------------------------------------------------------------------------------------
  // Main sequence
  // ------------------------------------------------------------------------------------------
  logic [31:0] rd, err;
  int fd;

  task automatic poll_until(input logic [AXIL_ADD_W-1:0] addr, input logic [31:0] expect_val, input string what);
    logic [31:0] v;
    forever begin
      axil_read(addr, v);
      if (v >= expect_val) begin
        $display("[TB] %s done (cnt=%0d) t=%0t", what, v, $time);
        return;
      end
      axil_read(12'h01C, err);
      if (err != 0) $fatal(1, "[TB] ERROR register = 0x%08x during %s", err, what);
      repeat (500) @(posedge clk);
    end
  endtask

  initial begin
    axil_awvalid = 0; axil_wvalid = 0; axil_arvalid = 0;
    repeat (100) @(posedge clk);
    rst_n = 1'b1;
    repeat (100) @(posedge clk);

    axil_read(12'h000, rd);
    if (rd !== 32'h4850_554D) $fatal(1, "[TB] bad MAGIC 0x%08x", rd);
    $display("[TB] MAGIC ok");

    // configuration: all regions at base 0 of their own memories
    axil_write(12'h020, 32'h0); axil_write(12'h024, 32'h0); // ct
    axil_write(12'h030, 32'h0); axil_write(12'h034, 32'h0); // glwe
    for (int i=0; i<4; i++) begin
      axil_write(12'h040 + i*8, 32'h0); axil_write(12'h044 + i*8, 32'h0); // bsk
      axil_write(12'h060 + i*8, 32'h0); axil_write(12'h064 + i*8, 32'h0); // ksk
    end
    axil_write(12'h038, 32'h1);     // use_bpip
    axil_write(12'h03C, 32'd10000); // bpip timeout
    axil_write(12'h080, 32'h3);     // bsk_avail | ksk_avail
    $display("[TB] config done t=%0t", $time);

    if (golden) begin
      // replay official DOp stream: dop_patched_e0.hex, one 32-bit DOp per line
      int dfd, rc, n_ld, n_st, n_pea, n_pep;
      logic [31:0] dop;
      string dline;
      dfd = $fopen($sformatf("%s/dop/dop_patched_e0.hex", `TB_GOLDEN_DIR), "r");
      if (!dfd) $fatal(1, "[TB] cannot open golden dop stream");
      n_ld = 0; n_st = 0; n_pea = 0; n_pep = 0;
      while ($fgets(dline, dfd)) begin
        rc = $sscanf(dline, "%h", dop);
        if (rc != 1) continue;
        axil_write(12'h018, dop);
        $display("[TB] GOLDEN dop 0x%08x issued t=%0t", dop, $time);
        // conservative: wait for the matching ack before next dop
        unique case (dop[31:26])
          6'b10_0000: begin n_ld++;  poll_until(12'h090, n_ld,  "LD");  end
          6'b10_0001: begin n_st++;  poll_until(12'h094, n_st,  "ST");  end
          default: begin
            if (dop[31:30] == 2'b00)      begin n_pea++; poll_until(12'h098, n_pea, "PEA"); end
            else if (dop[31:30] == 2'b11) begin n_pep++; poll_until(12'h09C, n_pep, "PBS"); end
            // kind 01 (SYNC/UCORE): consumed locally, nothing to poll
          end
        endcase
      end
      $fclose(dfd);
      repeat (200) @(posedge clk);
      fd = $fopen($sformatf("%s/sim_out_golden.hex", `TB_DATA_DIR), "w");
      for (int w=0; w<CT_WORDS; w++)
        $fdisplay(fd, "%064x", mem_pem.axi4_ram_ct_wr.mem[2*CT_SLOT_WORDS + w]);
      $fclose(fd);
      $fclose(ks_fd);
      $display("[TB] GOLDEN_OUTPUT_DUMPED sim_out_golden.hex t=%0t", $time);
      $display("[TB] SIM_PASS");
      $finish;
    end

    // LD r2 <- cid0
    axil_write(12'h018, {6'b10_0000, 16'd0, 2'b00, 1'b0, 7'd2});
    poll_until(12'h090, 1, "LD");

    // PBS_F r4 <- r2, gid=1 (MsgOnly)
    axil_write(12'h018, {2'b11, 1'b1, 1'b0, 2'b00, 12'd1, 7'd2, 7'd4});
    poll_until(12'h09C, 1, "PBS");
    axil_read(12'h0A8, rd);
    $display("[TB] PBS cycles = %0d", rd);

    // ST r4 -> cid1
    axil_write(12'h018, {6'b10_0001, 16'd1, 2'b00, 1'b0, 7'd4});
    poll_until(12'h094, 1, "ST");

    repeat (200) @(posedge clk);

    // dump output ciphertext (slot 1 = word 640)
    fd = $fopen($sformatf("%s/sim_out_case%0d.hex", `TB_DATA_DIR, case_id), "w");
    for (int w=0; w<CT_WORDS; w++)
      $fdisplay(fd, "%064x", mem_pem.axi4_ram_ct_wr.mem[CT_SLOT_WORDS + w]);
    $fclose(fd);
    $display("[TB] OUTPUT_DUMPED sim_out_case%0d.hex t=%0t", case_id, $time);
    // scan pem memory for defined regions
    begin
      int run_start = -1;
      for (int w=0; w<2048; w++) begin
        logic [255:0] v = mem_pem.axi4_ram_ct_wr.mem[w];
        bit defined = !$isunknown(v);
        if (defined && run_start < 0) run_start = w;
        if ((!defined || w==2047) && run_start >= 0) begin
          $display("[TB] PEM_MEM defined words [%0d .. %0d]", run_start, defined ? w : w-1);
          run_start = -1;
        end
      end
    end
    $display("[TB] AR_COUNTS glwe=%0d bsk0=%0d ksk0=%0d", glwe_ar_cnt, bsk_ar_cnt, ksk_ar_cnt);
    $display("[TB] X_COUNTS decomp=%0d bsk=%0d nttacc=%0d sxt0=%0d sxt1=%0d", decomp_x_cnt, bsk_x_cnt, nttacc_x_cnt, sxt0_x_cnt, sxt1_x_cnt);
    $fclose(ks_fd);
    $display("[TB] SIM_PASS");
    $finish;
  end

endmodule
