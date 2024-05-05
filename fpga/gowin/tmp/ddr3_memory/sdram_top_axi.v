module sdram_top_axi(
  input         clock_25M,
  input         clock_50M,
  input         reset,
  output        in_awready,
  input         in_awvalid,
  input  [31:0] in_awaddr,
  input  [3:0]  in_awid,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
  input         in_bready,
  output        in_bvalid,
  output [1:0]  in_bresp,
  output [3:0]  in_bid,
  output        in_arready,
  input         in_arvalid,
  input  [31:0] in_araddr,
  input  [3:0]  in_arid,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [1:0]  in_rresp,
  output [31:0] in_rdata,
  output        in_rlast,
  output [3:0]  in_rid,

  input           sdram_MEMORY_CLK,    // Memory clock
  input           sdram_CLK_IN,        // Clock in
  input           sdram_RSTN,          // Reset
  input           sdram_LOCK,          // PLL lock
  output          sdram_STOP,          // PLL stop
  output          sdram_INIT,          // Initialized
  output  [2:0]   sdram_BANK,
  output          sdram_CS_N,
  output          sdram_RAS_N,
  output          sdram_CAS_N,
  output          sdram_WE_N,
  output          sdram_CK,
  output          sdram_CK_N,
  output          sdram_CKE,
  output          sdram_RESET_N,
  output          sdram_ODT,
  output  [13:0]  sdram_ADDR,
  output  [1:0]   sdram_DM,
  inout   [15:0]  sdram_DQ,
  inout   [1:0]   sdram_DQS,
  inout   [1:0]   sdram_DQS_N
);

 wire            HCLK;
 wire            HRESETN;
 wire    [31:0]  HADDR;
 wire    [2:0]   HSIZE;
 wire            HWRITE;
 wire    [1:0]   HTRANS;
 wire    [2:0]   HBURST;
 wire    [63:0]  HWDATA;
 wire            HREADY_O;
 wire    [1:0]   HRESP;
 wire    [63:0]  HRDATA;

axi2ahb_bridge_top axi2ahb_bridge_top(
  .aclk(clock_25M),
  .aresetn(~reset),
  .awid({{4'b0},in_awid}),
  .awaddr(in_awaddr),
  .awlen(in_awlen),
  .awsize(in_awsize),
  .awburst(in_awburst),
  .awvalid(in_awvalid),
  .awready(in_awready),
  .wid(8'b0),
  .wdata({{32'b0},in_wdata}),
  .wstrb({{4'b0},in_wstrb}),
  .wlast(in_wlast),
  .wvalid(in_wvalid),
  .wready(in_wready),
  .arid({{4'b0},in_arid}),
  .araddr(in_araddr),
  .arlen(in_arlen),
  .arsize(in_arsize),
  .arburst(in_arburst),
  .arvalid(in_arvalid),
  .arready(in_arready),
  .bid({{4'b0},in_bid}),
  .bresp(in_bresp),
  .bvalid(in_bvalid),
  .bready(in_bready),
  .rid({{4'b0},in_rid}),
  .rdata({{32'b0},in_rdata}),
  .rresp(in_rresp),
  .rlast(in_rlast),
  .rvalid(in_rvalid),
  .rready(in_rready),

  .hclk(HCLK),
  .hresetn(HRESETN),
  .haddr(HADDR),
  .htrans(HTRANS),
  .hwrite(HWRITE),
  .hsize(HSIZE),
  .hburst(HBURST),
  .hwdata(HWDATA),
  .hbusreq(1'b1),
  .hlock(1'b0),
  .hrdata(HRDATA),
  .hready(HREADY_O),
  .hresp(HRESP),
  .hgrant(1'b1),
  .hmaster(1'b0)
);

// gw_ahb_ddr3_top instantiation
gw_ahb_ddr3_top u_gw_ahb_ddr3_top
(
    // DDR3 I/F
    .DDR3_MEMORY_CLK(clock_50M),  // Memory clock 400MHz
    .DDR3_CLK_IN(sdram_MEMORY_CLK),          // Clock input 50MHz
    .DDR3_RSTN(sdram_RSTN),              // Reset input
    .DDR3_LOCK(sdram_LOCK),              // PLL lock
    .DDR3_STOP(sdram_STOP),              // PLL stop
    .DDR3_INIT(sdram_INIT),              // Initialized
    .DDR3_BANK(sdram_BANK),              // Bank select
    .DDR3_CS_N(sdram_CS_N),              // Chip select
    .DDR3_RAS_N(sdram_RAS_N),            // Row address strobe
    .DDR3_CAS_N(sdram_CAS_N),            // Column address strobe
    .DDR3_WE_N(sdram_WE_N),              // Write enable
    .DDR3_CK(sdram_CK),                  // Clock output
    .DDR3_CK_N(sdram_CK_N),              // Clock output
    .DDR3_CKE(sdram_CKE),                // Clock enable
    .DDR3_RESET_N(sdram_RESET_N),        // Reset output
    .DDR3_ODT(sdram_ODT),                // On-die termination
    .DDR3_ADDR(sdram_ADDR),              // Address bus
    .DDR3_DM(sdram_DM),                  // Data mask
    .DDR3_DQ(sdram_DQ),                  // Data bus
    .DDR3_DQS(sdram_DQS),                // Data strobe
    .DDR3_DQS_N(sdram_DQS_N),            // Data strobe
    // AHB bus I/F
    .HCLK(HCLK),
    .HRESETN(HRESETN),
    .HADDR(HADDR),
    .HSIZE(HSIZE),
    .HWRITE(HWRITE),
    .HTRANS(HTRANS),
    .HBURST(HBURST),
    .HWDATA(HWDATA),
    .HREADY_O(HREADY),
    .HRESP(HRESP),
    .HRDATA(HRDATA)
);

endmodule