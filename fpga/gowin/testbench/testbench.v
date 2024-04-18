`define CPU ldut.asic.cpu.cpu

module tb();
  reg clk;

  initial begin
    clk = 1'b0;
    forever begin
      #(`CLOCK_PERIOD/2) clk = ~clk;
    end
  end

  `ifndef NO_DUMP
  initial
  begin
    $fsdbDumpfile("simv_soc.fsdb");
    $fsdbDumpvars(0, tb) ; 
  end
  `endif
  
  reg   [3:0] gpio_in;
  wire  [5:0] gpio_out;

  //gpio_in[0] 是重置按钮
  initial
  begin
    gpio_in = 4'b0;
    #100 gpio_in = 4'b1;
    #100 gpio_in = 4'b0;
  end

  reg         uart_rx;
  wire        uart_tx;
  
  initial
  begin
    uart_rx = 1'b0;
  end

  reg         flash_miso;
  wire        flash_sck;
  wire [7:0]  flash_ss;
  wire        flash_mosi;

  initial
  begin
    flash_miso = 1'b0;
  end

  soc_top ldut (
    .clock      (clk),
    .reset      (1'h0),
    .gpio_in    (gpio_in),	
    .uart_rx    (uart_rx),
    .flash_miso (flash_miso),
    .gpio_out   (gpio_out),
    .uart_tx    (uart_tx),
    .flash_sck  (flash_sck),
    .flash_ss   (flash_ss),
    .flash_mosi (flash_mosi)
  );

  initial begin
    $display("************ Test Start ***************");
    forever begin
      #(`CLOCK_PERIOD * 10000)
      if(`CPU.wb_stage.ws_excp && `CPU.wb_stage.ws_excp_num[5]) begin
      	$display("************ Test Success ***************");
	   $finish;
      end
    end
  end

endmodule