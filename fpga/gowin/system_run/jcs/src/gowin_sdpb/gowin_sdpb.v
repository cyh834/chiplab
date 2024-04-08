//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.02
//Part Number: GW5AST-LV138FPG676AC2/I1
//Device: GW5AST-138B
//Device Version: B
//Created Time: Sun Apr  7 03:05:03 2024

module Gowin_SDPB (dout, clka, cea, clkb, ceb, oce, reset, ada, din, adb, byte_ena);

output [31:0] dout;
input clka;
input cea;
input clkb;
input ceb;
input oce;
input reset;
input [2:0] ada;
input [31:0] din;
input [2:0] adb;
input [3:0] byte_ena;

wire gw_gnd;

assign gw_gnd = 1'b0;

SDPB sdpb_inst_0 (
    .DO(dout[31:0]),
    .CLKA(clka),
    .CEA(cea),
    .CLKB(clkb),
    .CEB(ceb),
    .OCE(oce),
    .RESET(reset),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ada[2:0],gw_gnd,byte_ena[3:0]}),
    .DI(din[31:0]),
    .ADB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,adb[2:0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam sdpb_inst_0.READ_MODE = 1'b0;
defparam sdpb_inst_0.BIT_WIDTH_0 = 32;
defparam sdpb_inst_0.BIT_WIDTH_1 = 32;
defparam sdpb_inst_0.BLK_SEL_0 = 3'b000;
defparam sdpb_inst_0.BLK_SEL_1 = 3'b000;
defparam sdpb_inst_0.RESET_MODE = "SYNC";

endmodule //Gowin_SDPB
