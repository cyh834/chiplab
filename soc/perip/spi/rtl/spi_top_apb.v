// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h1c000000,
  parameter flash_addr_end   = 32'h2bffffff,
  parameter spi_ss_num       = 8
) (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

//状态机
reg [3:0] state;
localparam IDLE  = 4'h0;
localparam TX0   = 4'h1;
localparam TX1   = 4'h2;
localparam DIV   = 4'h3;
localparam SS    = 4'h4;
localparam CTRL  = 4'h5;
localparam START = 4'h6;
localparam WAIT  = 4'h7;
localparam RETURN= 4'h8;
localparam DONE  = 4'h9;

//地址
localparam SPI_MASTER_BASE = 32'h10001000;
localparam SPI_MASTER_END  = 32'h10001fff;
localparam SPI_RX0     = 5'h0 ;
localparam SPI_RX1     = 5'h4 ;
localparam SPI_TX0     = 5'h0 ;
localparam SPI_TX1     = 5'h4 ;
localparam SPI_CTRL    = 5'h10;
localparam SPI_DIVIDER = 5'h14;
localparam SPI_SS      = 5'h18;
localparam CTRL_GO_BSY = 32'h100;

//访问flash
wire xip = (in_paddr >= flash_addr_start) && (in_paddr <= flash_addr_end);
//访问其他
wire normal = ~xip;//(in_paddr >= SPI_MASTER_BASE) || (in_paddr >= (SPI_MASTER_END));
reg [4:0]  addr;
reg [31:0] wdata;
reg [31:0] rdata;
reg [3:0]  strb;
reg        wen;
reg        sel;
reg        cyc;
reg        ack;

reg        pready;

assign in_prdata = (state == DONE) ? {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]} : rdata;
assign in_pready = xip ? pready : 1'b1;


always @(posedge clock or posedge reset) begin
  if(reset) begin
    pready <= 1'b0;
  end
  else if(state === RETURN) begin
    pready <= ack;
  end
  else begin
    pready <= 1'b0;
  end
end

always @(posedge clock or posedge reset) begin
  if(reset) begin
    state <= IDLE;
  end
  else begin
    case (state)
      IDLE: begin
        if (in_psel && in_penable && xip) begin
            assert(in_pwrite == 1'b0);
            state <= TX0;
        end
      end
      TX0: begin
        if(ack) begin
          state <= TX1;
        end
      end
      TX1: begin
        if(ack) begin
          state <= DIV;
        end
      end
      DIV: begin
        if(ack) begin
          state <= SS;
        end
      end
      SS: begin
        if(ack) begin
          state <= CTRL;
        end
      end
      CTRL: begin
        if(ack) begin
          state <= START;
        end
      end
      START: begin
        if(ack) begin
          state <= WAIT;
        end
      end
      WAIT: begin
        if(ack && ((rdata&CTRL_GO_BSY) == 32'h0)) begin
          state <= RETURN;
        end
      end
      RETURN: begin
        if(ack) begin
          state <= DONE;
        end
      end
      DONE: begin
        state <= IDLE;
      end
      default : begin
        state <= IDLE;
      end
    endcase
  end
end

always @(*) begin
  case (state)
    IDLE: begin
      if(normal) begin
        addr = in_paddr[4:0];
        wdata = in_pwdata;
        strb = in_pstrb;
        wen = in_pwrite;
        sel = in_psel;
        cyc = in_penable;
      end
      else begin
        addr = 5'h0;
        wdata = 32'h0;
        strb = 4'h0;
        wen = 1'b0;
        sel = 1'b0;
        cyc = 1'b0;
      end
    end
    TX0: begin
      addr = SPI_TX0;
      wdata = 32'h0;
      strb = 4'hf;
      wen = 1'b1;
      sel = 1'b1;
      cyc = 1'b1;
    end
    TX1:begin
      addr = SPI_TX1;
      wdata = 32'h03000000 | (in_paddr & 32'h00fffffc);
      strb = 4'hf;
      wen = 1'b1;
      sel = 1'b1;
      cyc = 1'b1;
    end
    DIV:begin
      addr = SPI_DIVIDER;
      wdata = 32'h0;
      strb = 4'hf;
      wen = 1'b1;
      sel = 1'b1;
      cyc = 1'b1;
    end
    SS:begin
      addr = SPI_SS;
      wdata = 32'h1;
      strb = 4'hf;
      wen = 1'b1;
      sel = 1'b1;
      cyc = 1'b1;
    end
    CTRL:begin
      addr = SPI_CTRL;
      wdata = 32'h2440;
      strb = 4'hf;
      wen = 1'b1;
      sel = 1'b1;
      cyc = 1'b1;
    end
    START:begin
      addr = SPI_CTRL;
      wdata = 32'h2540;
      strb = 4'hf;
      wen = 1'b1;
      sel = 1'b1;
      cyc = 1'b1;
    end
    WAIT:begin
      addr = SPI_CTRL;
      wdata = 32'h2540;
      strb = 4'h0;
      wen = 1'b0;
      sel = 1'b1;
      cyc = 1'b1;
    end
    RETURN: begin
      addr = SPI_RX0;
      wdata = 32'h2540;
      strb = 4'h0;
      wen = 1'h0;
      sel = 1'h1;
      cyc = 1'h1;
    end
    default: begin
      addr = 5'h0;
      wdata = 32'h0;
      strb = 4'h0;
      wen = 1'b0;
      sel = 1'b0;
      cyc = 1'b0;
    end
  endcase
end


spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(addr),
  .wb_dat_i(wdata),
  .wb_dat_o(rdata),
  .wb_sel_i(strb),
  .wb_we_i (wen),
  .wb_stb_i(sel),
  .wb_cyc_i(cyc),
  .wb_ack_o(ack),
  .wb_err_o(in_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

`endif // FAST_FLASH

endmodule
