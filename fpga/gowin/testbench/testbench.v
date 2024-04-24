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
    $fsdbDumpMDA(0);
  end
  `endif
  
  reg   [3:0] gpio_in;
  wire  [5:0] gpio_out;

  //gpio_in[0] 是重置按钮
  initial
  begin
    gpio_in = 4'b0;
    #60000 gpio_in = 4'b1;
    #5000 gpio_in = 4'b0;
    #600000000 $display("************ Test TIMEOUT ***************");
    $finish;
  end

  reg         uart_rx;
  wire        uart_tx;
  
  initial
  begin
    uart_rx = 1'b0;
  end

  SoCFull ldut (
    .clock      (clk),
    .reset      (1'h0),
    .externalPins_gpio_in    (gpio_in),	
    .externalPins_uart_rx    (uart_rx),
    .externalPins_gpio_out   (gpio_out),
    .externalPins_uart_tx    (uart_tx)
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