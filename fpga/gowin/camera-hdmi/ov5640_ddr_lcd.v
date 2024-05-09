
`timescale 1ns / 1ps

module ov5640_ddr_lcd(
	
	input                                        sys_clk_50m,
	input                                        sys_nrst,
	
	inout  [31:0]                                ddr3_dq,
	inout  [3:0]                                 ddr3_dqs_n,
	inout  [3:0]                                 ddr3_dqs_p,
	
	output  [13:0]                               ddr3_addr,
	output  [2:0]                                ddr3_ba,
	output                                       ddr3_ras_n,
	output                                       ddr3_cas_n,
	output                                       ddr3_we_n,
	output                                       ddr3_reset_n,
	output  [0:0]                                ddr3_ck_p,
	output  [0:0]                                ddr3_ck_n,
	output  [0:0]                                ddr3_cke,
	output  [0:0]                                ddr3_cs_n,
	output  [3:0]                                ddr3_dm,
	output  [0:0]                                ddr3_odt,
	
	output										ddr_done,
	output										cmos_pll_lk,
	output										ddr_pll_lk,
	
	input				hdmi_pclk,
	output				hdmi_hs,
	output				hdmi_vs,
	output				hdmi_de,
	output	[23:0]		hdmi_d,
	
	output                                       cmos_pwdn,
	output                                       cmos_mclk,
	output                                       cmos_scl,         //cmos i2c clock
	inout                                        cmos_sda,         //cmos i2c data
	input                                        cmos_vsync,       //cmos vsync
	input                                        cmos_href,        //cmos hsync refrence
	input                                        cmos_pclk,        //cmos pxiel clock
	input   [7:0]                                cmos_d,           //cmos data
	output                                       cmos_reset       //cmos reset
);
	
	wire				phy_clk;
	wire				phy_rst;
	
	wire				Cmos1_Config_Done;
	wire				initial_en;
	
	wire				sys_we;
	wire	[255:0]		sys_data_in;
	wire				sys_rd;
	wire	[255:0]		sys_data_out;
	
	cmos_pll cmos_pll_inst0(
		.lock		(cmos_pll_lk),
		.clkout0	(cmos_mclk),
		.clkin		(phy_clk),
		.reset		(phy_rst)
	);
	
	power_on_delay power_on_delay_inst(
		.clk_50M                 (cmos_mclk),
		.reset_n                 (sys_nrst),	
		.camera1_rstn            (cmos_reset),
		.camera_pwnd             (cmos_pwdn),
		.initial_en              (initial_en)		
	);
	
	reg_config reg_config_inst1(
		.clk_25M                 (cmos_mclk),
		.camera_rstn             (cmos_reset),
		.initial_en              (initial_en),
		.i2c_sclk                (cmos_scl),
		.i2c_sdat                (cmos_sda),
		.reg_conf_done           (Cmos1_Config_Done)
	);
	
	camera_capture camera_capture_inst(
		.rst_n                   (sys_nrst),	       //external reset
		.init_done               (ddr_done & Cmos1_Config_Done),	   // init done
		.camera_pclk             (cmos_pclk),	   //cmos pxiel clock
		.camera_href             (cmos_href),	   //cmos hsync refrence
		.camera_vsync            (cmos_vsync),    //cmos vsync
		.camera_data             (cmos_d),        //cmos data
		.ddr_wren                (sys_we),         //ddr write enable
		.ddr_data_camera         (sys_data_in)    //ddr write data
	);
	
	lcd_disp	lcd_disp_inst(
		//global clock
		.clk				   (hdmi_pclk),			    //lcd clock
		.nrst				   (sys_nrst),		        //global reset
		
		.hs					   (hdmi_hs),
		.vs					   (hdmi_vs),
		.de				       (hdmi_de),
		.rgb_r			       (hdmi_d[16+:8]),
		.rgb_g			       (hdmi_d[ 8+:8]),
		.rgb_b			       (hdmi_d[ 0+:8]),

		//user interface
		.ddr_rden   		   (sys_rd),
		.ddr_data  		       (sys_data_out),
		.ddr_init_done	       (ddr_done)
	);
	
	ddr_2fifo_top ddr_2fifo_top_inst(
		
		//global clock
		.sys_clk_50m					(sys_clk_50m),
		.sys_nrst                       (sys_nrst),
		
		.phy_clk                        (phy_clk),
		.phy_rst                        (phy_rst),
		
		.init_calib_complete            (ddr_done),
		.ddr_pll_lk			            (ddr_pll_lk),
		
		.clk_read				        (hdmi_pclk),
		.clk_write				        (cmos_pclk),
		
		//ddr interface
		.ddr3_addr                      (ddr3_addr),   //ddr address    
		.ddr3_ba                        (ddr3_ba),     //ddr bank address
		.ddr3_cas_n                     (ddr3_cas_n),  //ddr column address strobe
		.ddr3_ck_n                      (ddr3_ck_n),   //ddr clock enable 
		.ddr3_ck_p                      (ddr3_ck_p),   //ddr positive clock    
		.ddr3_cke                       (ddr3_cke),    //ddr negative clock 
		.ddr3_ras_n                     (ddr3_ras_n),  //ddr row address strobe    
		.ddr3_we_n                      (ddr3_we_n),   //ddr write enable
		.ddr3_dq                        (ddr3_dq),     //ddr data    
		.ddr3_dqs_n                     (ddr3_dqs_n),  //ddr data positive clock    
		.ddr3_dqs_p                     (ddr3_dqs_p),  //ddr data negative clock    
		.ddr3_reset_n                   (ddr3_reset_n),//ddr reset
		.ddr3_cs_n                      (ddr3_cs_n),   //ddr chip select        
		.ddr3_dm                        (ddr3_dm),     //ddr data enable
		.ddr3_odt                       (ddr3_odt),     //ddr On-Die Termination
		
		//user interface
		.vin_vs                         (cmos_vsync),
		.vout_vs                        (hdmi_vs), 
		.frame_write_done		        (),
		.frame_read_done  	            (),
		.sys_we	                        (sys_we),              //fifo write enable
		.sys_data_in	                (sys_data_in),         //fifo data input	
		.sys_rd	                        (sys_rd),	           //fifo read enable
		.sys_data_out	                (sys_data_out)	       //fifo data output
	);

endmodule
