module sdram_top_axi(
  //axi interface
  input         clock,
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

  //dmi
  output          dmi_clk,
  output          dmi_memory_clk,
  output          dmi_pll_lock,
  output          dmi_rst_n,
  output [2:0]    dmi_cmd,
  output          dmi_cmd_en,
  output [28:0]   dmi_addr,
  output [255:0]  dmi_wr_data,
  output          dmi_wr_data_en,
  output          dmi_wr_data_end,
  output [31:0]   dmi_wr_data_mask,
  output          dmi_sr_req,
  output          dmi_ref_req,
  output          dmi_burst,
  input           dmi_pll_stop,
  input           dmi_clk_out,
  input           dmi_ddr_rst,
  input           dmi_init_calib_complete,
  input           dmi_cmd_ready,
  input           dmi_wr_data_rdy,
  input [255:0]   dmi_rd_data,
  input           dmi_rd_data_valid,
  input           dmi_rd_data_end,
  input           dmi_sr_ack,
  input           dmi_ref_ack
);
  
    assign in_awready = 1'b0;
    assign in_wready = 1'b0;
    assign in_bvalid = 1'b0;
    assign in_bresp = 2'b00;
    assign in_bid = 4'b0;
    assign in_arready = 1'b0;
    assign in_rvalid = 1'b0;
    assign in_rresp = 2'b00;
    assign in_rdata = 32'h0;
    assign in_rlast = 1'b0;
    assign in_rid = 4'b0;
  
    assign dmi_clk = 0;
    assign dmi_memory_clk = 0;
    assign dmi_pll_lock = 0;
    assign dmi_rst_n = 0;
    assign dmi_cmd = 0;
    assign dmi_cmd_en = 0;
    assign dmi_addr = 0;
    assign dmi_wr_data = 0;
    assign dmi_wr_data_en = 0;
    assign dmi_wr_data_end = 0;
    assign dmi_wr_data_mask = 0;
    assign dmi_sr_req = 0;
    assign dmi_ref_req = 0;
    assign dmi_burst = 0;

    
endmodule