module ddr_ctrl #(
	parameter DATA_WIDTH = 256,
	parameter ADDR_WIDTH = 28
)
(
   // Differential system clocks
    input                    sys_clk_50m,
    input                    sys_nrst,
	
	output                   ddr_clk_1x,
	output                   rst,
	
	output                   ddr_pll_lk,

/*ddr读写用户接口信号*/	
    output                   init_calib_complete,     //ddr initial done

	input                    wr_burst_req,            //DDR Burst写请求         	
	input  [9:0]             wr_burst_len,	          //DDR Burst写长度
	input [ADDR_WIDTH - 3 - 1:0] wr_burst_addr,           //DDR Burst写地址
    output                   wr_burst_data_req,	      //写入数据请求	
	input [DATA_WIDTH - 1:0] wr_burst_data,           //DDR Burst写数据
    output                   wr_burst_finish,         //DDR Burst写完成信号
	
	input                    rd_burst_req,            //DDR Burst读请求 
	input  [9:0]             rd_burst_len,	          //DDR Burst读长度
	input [ADDR_WIDTH - 3 - 1:0] rd_burst_addr,           //DDR Burst读地址		
    output                   rd_burst_data_valid,     //DDR Burst读数据有效		
	output[DATA_WIDTH - 1:0] rd_burst_data,           //DDR Burst读数据
    output                   rd_burst_finish,         //DDR Burst读完成信号
	
/*ddr3接口信号*/	
    inout [31:0]             ddr3_dq,
    inout [3:0]              ddr3_dqs_n,
    inout [3:0]              ddr3_dqs_p,

    output [13:0]            ddr3_addr,
    output [2:0]             ddr3_ba,
    output                   ddr3_ras_n,
    output                   ddr3_cas_n,
    output                   ddr3_we_n,
    output                   ddr3_reset_n,
    output [0:0]             ddr3_ck_p,
    output [0:0]             ddr3_ck_n,
    output [0:0]             ddr3_cke,
    output [0:0]             ddr3_cs_n,
    output [3:0]             ddr3_dm,
    output [0:0]             ddr3_odt
);
	
	// Wire declarations
	wire	[ADDR_WIDTH-1:0]		app_addr;
	wire	[2:0]					app_cmd;
	wire							app_en;
	wire							app_rdy;
	
	wire	[DATA_WIDTH-1:0]		app_rd_data;
	wire							app_rd_data_end;
	wire							app_rd_data_valid;
	
	wire	[DATA_WIDTH-1:0]		app_wdf_data;
	wire							app_wdf_end;
	wire	[(DATA_WIDTH/8)-1:0]	app_wdf_mask;
	wire							app_wdf_wren;
	wire							app_wdf_rdy;
	
	mem_burst#(
		.MEM_DATA_BITS(DATA_WIDTH),
		.ADDR_BITS(ADDR_WIDTH)
	)mem_burst_m0(
		.rst(rst),                                  /*复位*/
		.mem_clk(ddr_clk_1x),                              /*接口时钟*/
		.rd_burst_req(rd_burst_req),                /*DDR Burst读请求*/
		.wr_burst_req(wr_burst_req),                /*DDR Burst写请求*/
		.rd_burst_len(rd_burst_len),                /*DDR Burst读数据长度*/
		.wr_burst_len(wr_burst_len),                 /*DDR Burst写数据长度*/
		.rd_burst_addr(rd_burst_addr),               /*DDR Burst读首地址*/
		.wr_burst_addr(wr_burst_addr),               /*DDR Burst写首地址*/
		.rd_burst_data_valid(rd_burst_data_valid),   /*DDR Burst读出数据有效*/
		.wr_burst_data_req(wr_burst_data_req),       /*DDR Burst写数据信号*/
		.rd_burst_data(rd_burst_data),               /*DDR Burst读出的数据*/
		.wr_burst_data(wr_burst_data),               /*DDR Burst写入的数据*/
		.rd_burst_finish(rd_burst_finish),           /*DDR Burst读完成*/
		.wr_burst_finish(wr_burst_finish),           /*DDR Burst写完成*/

		.app_addr(app_addr),
		.app_cmd(app_cmd),
		.app_en(app_en),
		.app_rdy(app_rdy),
		
		.app_wdf_data(app_wdf_data),
		.app_wdf_end(app_wdf_end),
		.app_wdf_mask(app_wdf_mask),
		.app_wdf_wren(app_wdf_wren),
		.app_wdf_rdy(app_wdf_rdy),
		
		.app_rd_data(app_rd_data),
		.app_rd_data_end(app_rd_data_end),
		.app_rd_data_valid(app_rd_data_valid),
		
		.init_calib_complete(init_calib_complete)
	);
	
	wire		ddr_pll_lock;
	wire		ddr_mem_clk;
	wire		ddr_pll_stop;
	
	assign ddr_pll_lk = ddr_pll_lock;
	
	ddr_pll ddr_pll_inst0(
		.lock		(ddr_pll_lock),
		.clkout0	(),
		.clkout1	(),
		.clkout2	(ddr_mem_clk),
		.clkin		(sys_clk_50m),
		.reset		(~sys_nrst),
		.enclk0		(1'b1),
		.enclk1		(1'b1),
		.enclk2		(ddr_pll_stop)
	);
	
	DDR3_Memory_Interface_Top ddr_m0(
		
		.clk					(sys_clk_50m),
		.pll_stop				(ddr_pll_stop),
		.memory_clk				(ddr_mem_clk),
		.pll_lock				(ddr_pll_lock),
		
		.rst_n					(sys_nrst),
		
		.cmd_ready				(app_rdy),
		.cmd					(app_cmd),
		.cmd_en					(app_en),
		.addr					(app_addr),
		
		.wr_data_rdy			(app_wdf_rdy),
		.wr_data				(app_wdf_data),
		.wr_data_en				(app_wdf_wren),
		.wr_data_end			(app_wdf_end),
		.wr_data_mask			(app_wdf_mask),
		
		.rd_data				(app_rd_data),
		.rd_data_valid			(app_rd_data_valid),
		.rd_data_end			(app_rd_data_end),
		
		.sr_req					(1'b0),
		.ref_req				(1'b0),
		.burst					(1'b0),
		.sr_ack					(),
		.ref_ack				(),
		
		.clk_out				(ddr_clk_1x),
		.ddr_rst				(rst),
		
		.init_calib_complete	(init_calib_complete),
		
		.O_ddr_addr				(ddr3_addr),
		.O_ddr_ba				(ddr3_ba),
		.O_ddr_cs_n				(ddr3_cs_n),
		.O_ddr_ras_n			(ddr3_ras_n),
		.O_ddr_cas_n			(ddr3_cas_n),
		.O_ddr_we_n				(ddr3_we_n),
		.O_ddr_clk				(ddr3_ck_p),
		.O_ddr_clk_n			(ddr3_ck_n),
		.O_ddr_cke				(ddr3_cke),
		.O_ddr_odt				(ddr3_odt),
		.O_ddr_reset_n			(ddr3_reset_n),
		.O_ddr_dqm				(ddr3_dm),
		.IO_ddr_dq				(ddr3_dq),
		.IO_ddr_dqs				(ddr3_dqs_p),
		.IO_ddr_dqs_n			(ddr3_dqs_n)
	);
	
endmodule 

