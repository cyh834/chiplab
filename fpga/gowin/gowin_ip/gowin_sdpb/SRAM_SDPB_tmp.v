//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9.02
//Part Number: GW5AST-LV138FPG676AC2/I1
//Device: GW5AST-138B
//Device Version: B
//Created Time: Sat May  4 16:22:30 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    SRAM_SDPB your_instance_name(
        .dout(dout_o), //output [31:0] dout
        .clka(clka_i), //input clka
        .cea(cea_i), //input cea
        .clkb(clkb_i), //input clkb
        .ceb(ceb_i), //input ceb
        .oce(oce_i), //input oce
        .reset(reset_i), //input reset
        .ada(ada_i), //input [15:0] ada
        .din(din_i), //input [31:0] din
        .adb(adb_i), //input [15:0] adb
        .byte_ena(byte_ena_i) //input [3:0] byte_ena
    );

//--------Copy end-------------------
