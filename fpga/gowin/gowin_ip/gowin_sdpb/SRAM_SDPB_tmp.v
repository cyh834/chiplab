//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9.03
//Part Number: GW5AST-LV138FPG676AC2/I1
//Device: GW5AST-138B
//Device Version: B
//Created Time: Tue May 14 14:16:15 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    SRAM_SDPB your_instance_name(
        .dout(dout), //output [31:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .oce(oce), //input oce
        .reset(reset), //input reset
        .ada(ada), //input [15:0] ada
        .din(din), //input [31:0] din
        .adb(adb), //input [15:0] adb
        .byte_ena(byte_ena) //input [3:0] byte_ena
    );

//--------Copy end-------------------
