//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.02
//Part Number: GW5AST-LV138FPG676AC2/I1
//Device: GW5AST-138B
//Device Version: B
//Created Time: Thu Apr  4 20:19:26 2024

module SP_256x21 (dout, clk, oce, ce, reset, wre, ad, din, byte_en);

output [20:0] dout;
input clk;
input oce;
input ce;
input reset;
input wre;
input [7:0] ad;
input [20:0] din;
input [2:0] byte_en;

wire [10:0] sp_inst_0_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

SP sp_inst_0 (
    .DO({sp_inst_0_dout_w[10:0],dout[20:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({gw_gnd,gw_gnd,gw_gnd}),
    .AD({gw_gnd,ad[7:0],gw_gnd,gw_gnd,byte_en[2:0]}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[20:0]})
);

defparam sp_inst_0.READ_MODE = 1'b0;
defparam sp_inst_0.WRITE_MODE = 2'b01;
defparam sp_inst_0.BIT_WIDTH = 32;
defparam sp_inst_0.BLK_SEL = 3'b000;
defparam sp_inst_0.RESET_MODE = "SYNC";

endmodule //SP_256x21
