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

/*ddr��д�û��ӿ��ź�*/	
    output                   init_calib_complete,     //ddr initial done

	input                    wr_burst_req,            //DDR Burstд����         	
	input  [9:0]             wr_burst_len,	          //DDR Burstд����
	input [ADDR_WIDTH - 3 - 1:0] wr_burst_addr,           //DDR Burstд��ַ
    output                   wr_burst_data_req,	      //д����������	
	input [DATA_WIDTH - 1:0] wr_burst_data,           //DDR Burstд����
    output                   wr_burst_finish,         //DDR Burstд����ź�
	
	input                    rd_burst_req,            //DDR Burst������ 
	input  [9:0]             rd_burst_len,	          //DDR Burst������
	input [ADDR_WIDTH - 3 - 1:0] rd_burst_addr,           //DDR Burst����ַ		
    output                   rd_burst_data_valid,     //DDR Burst��������Ч		
	output[DATA_WIDTH - 1:0] rd_burst_data,           //DDR Burst������
    output                   rd_burst_finish,         //DDR Burst������ź�
	
/*ddr3�ӿ��ź�*/	
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
		.rst(rst),                                  /*��λ*/
		.mem_clk(ddr_clk_1x),                              /*�ӿ�ʱ��*/
		.rd_burst_req(rd_burst_req),                /*DDR Burst������*/
		.wr_burst_req(wr_burst_req),                /*DDR Burstд����*/
		.rd_burst_len(rd_burst_len),                /*DDR Burst�����ݳ���*/
		.wr_burst_len(wr_burst_len),                 /*DDR Burstд���ݳ���*/
		.rd_burst_addr(rd_burst_addr),               /*DDR Burst���׵�ַ*/
		.wr_burst_addr(wr_burst_addr),               /*DDR Burstд�׵�ַ*/
		.rd_burst_data_valid(rd_burst_data_valid),   /*DDR Burst����������Ч*/
		.wr_burst_data_req(wr_burst_data_req),       /*DDR Burstд�����ź�*/
		.rd_burst_data(rd_burst_data),               /*DDR Burst����������*/
		.wr_burst_data(wr_burst_data),               /*DDR Burstд�������*/
		.rd_burst_finish(rd_burst_finish),           /*DDR Burst�����*/
		.wr_burst_finish(wr_burst_finish),           /*DDR Burstд���*/

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

