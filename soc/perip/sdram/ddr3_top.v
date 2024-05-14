`timescale 1ps / 1ps

module ddr3_top (
  input  [14:0] O_ddr_addr,
  input  [2:0]  O_ddr_ba,
  input         O_ddr_cs_n,
                O_ddr_ras_n,
                O_ddr_cas_n,
                O_ddr_we_n,
                O_ddr_clk,
                O_ddr_clk_n,
                O_ddr_cke,
                O_ddr_odt,
                O_ddr_reset_n,
  input  [3:0]  O_ddr_dqm,
  inout  [31:0] dq,
  inout  [3:0]  dqs,
                dqs_n
);
`ifdef den1024Mb
    `include "1024Mb_ddr3_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_ddr3_parameters.vh"
`elsif den4096Mb
    `include "4096Mb_ddr3_parameters.vh"
`elsif den8192Mb
    `include "8192Mb_ddr3_parameters.vh"
`else
    // NOTE: Intentionally cause a compile fail here to force the users
    //       to select the correct component density before continuing
    ERROR: You must specify component density with +define+den____Mb.
`endif

reg rst;
always @(posedge O_ddr_clk) begin
  // rst <= #200000000 ~O_ddr_reset_n;
  rst <= O_ddr_reset_n;
end

generate 
  genvar o;
    for(o = 0; o < 2; o = o + 1'b1) begin:ddr3_model
        ddr3 ddr3_model(
          .rst_n            (rst),
          .ck               (O_ddr_clk),
          .ck_n             (O_ddr_clk_n),
          .cke              (O_ddr_cke),
          .cs_n             (O_ddr_cs_n),
          .ras_n            (O_ddr_ras_n),
          .cas_n            (O_ddr_cas_n),
          .we_n             (O_ddr_we_n),
          .dm_tdqs          (O_ddr_dqm[o*2+:2]),
          .ba               (O_ddr_ba),
          .addr             (O_ddr_addr[ADDR_BITS-1:0]),
          .dq               (dq[o*16+:16]),
          .dqs              (dqs[o*2+:2]),
          .dqs_n            (dqs_n[o*2+:2]),
          .tdqs_n           (),
          .odt              (ddr_odt)
        );
      end
endgenerate

  //ddr3 U1R0 (O_ddr_reset_n, O_ddr_clk, O_ddr_clk_n, O_ddr_cke, O_ddr_cs_n, O_ddr_ras_n, O_ddr_cas_n, O_ddr_we_n, O_ddr_dqm[1:0], O_ddr_ba, O_ddr_addr[ADDR_BITS-1:0], dq [15: 0], dqs[1:0], dqs_n[1:0], , O_ddr_odt);
  //ddr3 U1R1 (O_ddr_reset_n, O_ddr_clk, O_ddr_clk_n, O_ddr_cke, O_ddr_cs_n, O_ddr_ras_n, O_ddr_cas_n, O_ddr_we_n, O_ddr_dqm[3:2], O_ddr_ba, O_ddr_addr[ADDR_BITS-1:0], dq [31:16], dqs[3:2], dqs_n[3:2], , O_ddr_odt);
endmodule