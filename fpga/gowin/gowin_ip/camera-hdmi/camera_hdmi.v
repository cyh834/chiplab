module top(
	
	// ===================================================
	input                       clk,
	input                       rst_n,
	// ===================================================
	
	// ===================================================
	// DDR3 PHY
	// ===================================================
	inout  [31:0]				ddr3_dq,
	inout  [3:0]				ddr3_dqs_n,
	inout  [3:0]				ddr3_dqs_p,
	output  [13:0]				ddr3_addr,
	output  [2:0]				ddr3_ba,
	output						ddr3_ras_n,
	output						ddr3_cas_n,
	output						ddr3_we_n,
	output						ddr3_reset_n,
	output  					ddr3_ck_p,
	output  					ddr3_ck_n,
	output  					ddr3_cke,
	output  					ddr3_cs_n,
	output  [3:0]				ddr3_dm,
	output  					ddr3_odt,
	// ===================================================
	
	output		[3 : 0]			led,
	
	output						tmds_clk_n_0,
	output						tmds_clk_p_0,
	output		[2 : 0]			tmds_d_n_0,
	output		[2 : 0]			tmds_d_p_0,
	
	// ===================================================
	//cmos1 interface
	// ===================================================
	output [2 : 0]				iic_mux,
	
	output						cmos_xclk,
	output						cmos_pwdn,
	output						cmos_scl,
	inout						cmos_sda,
	input						cmos_vsync,
	input						cmos_href,
	input						cmos_pclk,
	input   [7:0]				cmos_db,
	output						cmos_rst_n
	// ===================================================
);
	
	assign iic_mux = 3'b101;
	
	wire				cmos_pclk_g;
	
	wire				hdmi_hs;
	wire				hdmi_vs;
	wire				hdmi_de;
	wire	[23:0]		hdmi_d;
	
	wire				clk_p;
	wire				clk_p5;
	
	wire	[3 : 0]		led_bar;
	
	assign led = ~led_bar;
	
	bufg bufg_pclk(
		.clkout		(cmos_pclk_g),
		.hclkin		(cmos_pclk),
		.resetn		(rst_n)
	);
	
	ov5640_ddr_lcd u_ov5640_ddr_lcd(
		
		.sys_clk_50m					(clk),
		.sys_nrst						(rst_n),

		.ddr3_dq						(ddr3_dq),       
		.ddr3_dqs_n						(ddr3_dqs_n),    
		.ddr3_dqs_p						(ddr3_dqs_p),
		.ddr3_addr						(ddr3_addr),       
		.ddr3_ba						(ddr3_ba),    
		.ddr3_ras_n						(ddr3_ras_n),     
		.ddr3_cas_n						(ddr3_cas_n),       
		.ddr3_we_n						(ddr3_we_n),    
		.ddr3_reset_n					(ddr3_reset_n),  
		.ddr3_ck_p						(ddr3_ck_p),  
		.ddr3_ck_n						(ddr3_ck_n),  
		.ddr3_cke						(ddr3_cke), 
		.ddr3_cs_n						(ddr3_cs_n),   
		.ddr3_dm						(ddr3_dm), 
		.ddr3_odt						(ddr3_odt), 

		.ddr_done						(led_bar[0]),
		.cmos_pll_lk					(led_bar[1]),
		.ddr_pll_lk						(led_bar[2]),
		
		.hdmi_pclk						(clk_p),
		.hdmi_hs						(hdmi_hs),
		.hdmi_vs						(hdmi_vs),
		.hdmi_de						(hdmi_de),
		.hdmi_d							(hdmi_d),
		
		.cmos_scl						(cmos_scl),
		.cmos_sda						(cmos_sda),
		
		.cmos_pclk						(cmos_pclk_g),
		.cmos_mclk						(cmos_xclk),
		.cmos_vsync						(cmos_vsync),      
		.cmos_href						(cmos_href),  
		.cmos_d							(cmos_db),
		
		.cmos_pwdn						(cmos_pwdn),
		.cmos_reset						(cmos_rst_n)
	);
	
	tmds_pll tmds_pll_inst0(
		.lock		(led_bar[3]),
		.clkout0	(clk_p5),
		.clkout1	(clk_p),
		.clkin		(clk),
		.reset		(~rst_n)
    );
	
	dvi_tx_top dvi_tx_top_inst0(
		
		.pixel_clock		(clk_p),
		.ddr_bit_clock		(clk_p5),
		.reset				(~rst_n),
		
		.den				(hdmi_de),
		.hsync				(hdmi_hs),
		.vsync				(hdmi_vs),
		.pixel_data			(hdmi_d),
		
		.tmds_clk			({tmds_clk_p_0, tmds_clk_n_0}),
		.tmds_d0			({tmds_d_p_0[0], tmds_d_n_0[0]}),
		.tmds_d1			({tmds_d_p_0[1], tmds_d_n_0[1]}),
		.tmds_d2			({tmds_d_p_0[2], tmds_d_n_0[2]})
	);

endmodule