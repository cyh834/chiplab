/*
xilinx_sram:
module data_bank_sram(
    input  [ 7:0]          addra   ,
    input                  clka    ,
    input  [31:0]          dina    ,
    output [31:0]          douta   ,
    input                  ena     ,
    input  [ 3:0]          wea      
);

gowin_sp:
module SP_256x32(
    .dout(dout_o), //output [31:0] dout
    .clk(clk_i), //input clk
    .oce(oce_i), //input oce
    .ce(ce_i), //input ce
    .reset(reset_i), //input reset
    .wre(wre_i), //input wre
    .ad(ad_i), //input [7:0] ad
    .din(din_i), //input [31:0] din
    .byte_en(byte_en_i) //input [3:0] byte_en
);
*/

module data_bank_sram(
    //xilinx_sram
    input  [ 7:0]          addra   ,
    input                  clka    ,
    input  [31:0]          dina    ,
    output [31:0]          douta   ,
    input                  ena     ,
    input  [ 3:0]          wea   
);
    wire wre;
    assign wre = |wea;

    //gowin_sp_256x32
    SP_256x32 sp0(
        .dout(douta), //output [31:0] dout
        .clk(clka), //input clk
        .oce(1'b1), //input oce
        .ce(ena), //input ce
        .reset(1'b0), //input reset
        .wre(wre), //input wre
        .ad(addra), //input [7:0] ad
        .din(dina), //input [31:0] din
        .byte_en(wea) //input [3:0] byte_en
    );

endmodule

module tagv_sram(
    //xilinx_sram
    input  [ 7:0]          addra   ,
    input                  clka    ,
    input  [20:0]          dina    ,
    output [20:0]          douta   ,
    input                  ena     ,
    input                  wea   
);
    //gowin_sp_256x21
    SP_256x21 sp0(
        .dout(douta), //output [20:0] dout
        .clk(clka), //input clk
        .oce(1'b1), //input oce
        .ce(ena), //input ce
        .reset(1'b0), //input reset
        .wre(wea), //input wre
        .ad(addra), //input [7:0] ad
        .din(dina), //input [20:0] din
        .byte_en(3'b111) //input [2:0] byte_en
    );

endmodule
