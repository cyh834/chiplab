/* =====================================================================
    ____         _                 ____                      
   | __ )  _ __ (_)  __ _  _ __   / ___|  _   _  _ __    ___ 
   |  _ \ | '__|| | / _` || '_ \  \___ \ | | | || '_ \  / _ \
   | |_) || |   | || (_| || | | |  ___) || |_| || | | ||  __/
   |____/ |_|   |_| \__,_||_| |_| |____/  \__,_||_| |_| \___|
   
   =====================================================================
   Date: 2024-01
   Author: Brian Sune
   Contact: briansune@gmail.com
   Revision: 1.0.0
   FPGA: XC7A100
   Tab Size: 4 spaces
   =====================================================================
*/

`timescale 1 ns / 1 ps

module lcd_disp(
	
	input wire					clk,
	input wire					nrst,
	
	// output wire					bclk,
	output wire					hs,
	output wire					vs,
	output wire					de,
	output wire		[7 : 0]		rgb_r,
	output wire		[7 : 0]		rgb_g,
	output wire		[7 : 0]		rgb_b,
	
	input wire		[255 : 0]	ddr_data,
	output reg					ddr_rden,
	input wire					ddr_init_done
);
	
	//=============================================================
	//1080P
	//=============================================================
	localparam H_ACTIVE = 16'd1920;
	localparam H_FP = 16'd88;
	localparam H_SYNC = 16'd44;
	localparam H_BP = 16'd148; 
	localparam V_ACTIVE = 16'd1080;
	localparam V_FP 	= 16'd4;
	localparam V_SYNC  = 16'd5;
	localparam V_BP	= 16'd36;
	localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
	localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;
	
	//=============================================================
	// Regs & Wires
	//=============================================================
	reg				hs_reg;
	reg				vs_reg;
	reg				hs_reg_d0;
	reg				vs_reg_d0;
	reg		[11:0]	h_cnt;
	reg		[11:0]	v_cnt;
	reg		[11:0]	active_x;
	reg		[11:0]	active_y;
	reg		[7:0]	rgb_r_reg;
	reg		[7:0]	rgb_g_reg;
	reg		[7:0]	rgb_b_reg;
	
	reg				h_fifo_en;
	
	reg				h_active;
	reg				v_active;
	
	reg				h_active2;
	reg				v_active2;
	
	reg				video_active_d0;
	
	wire			video_active;
	wire			video_active2;
	
	//=============================================================
	//	Assignments
	//=============================================================
	assign hs = hs_reg_d0;
	assign vs = vs_reg_d0;
	assign de = video_active_d0;
	
	
	assign video_active = h_active & v_active;
	assign video_active2 = h_active2 & v_active2;
	
	assign rgb_r = rgb_r_reg;
	assign rgb_g = rgb_g_reg;
	assign rgb_b = rgb_b_reg;
	
	always@(posedge clk or negedge nrst)begin
		
		if(!nrst)begin
			hs_reg_d0 <= 1'b0;
			vs_reg_d0 <= 1'b0;
			video_active_d0 <= 1'b0;
		end else begin
			hs_reg_d0 <= hs_reg;
			vs_reg_d0 <= vs_reg;
			video_active_d0 <= video_active;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
		
		if(!nrst)begin
			h_cnt <= 12'd0;
		end else if(h_cnt == H_TOTAL - 1)begin
			h_cnt <= 12'd0;
		end else begin
			h_cnt <= h_cnt + 12'd1;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
	
		if(!nrst)begin
			active_x <= 12'd0;
		end else if(h_cnt >= H_FP + H_SYNC + H_BP - 1)begin
			active_x <= h_cnt - (H_FP[11:0] + H_SYNC[11:0] + H_BP[11:0] - 12'd1);
		end else begin
			active_x <= active_x;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
	
		if(!nrst)begin
			v_cnt <= 12'd0;
		end else if(h_cnt == H_FP  - 1)begin
			if(v_cnt == V_TOTAL - 1)begin
				v_cnt <= 12'd0;
			end else begin
				v_cnt <= v_cnt + 12'd1;
			end
		end else begin
			v_cnt <= v_cnt;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
	
		if(!nrst)begin
			hs_reg <= 1'b0;
		end else if(h_cnt == H_FP - 1)begin
			hs_reg <= 1'b1;
		end else if(h_cnt == H_FP + H_SYNC - 1)begin
			hs_reg <= 1'b0;
		end else begin
			hs_reg <= hs_reg;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
	
		if(!nrst)begin
			h_active <= 1'b0;
		end else if(h_cnt == H_FP + H_SYNC + H_BP - 1)begin
			h_active <= 1'b1;
		end else if(h_cnt == H_TOTAL - 1)begin
			h_active <= 1'b0;
		end else begin
			h_active <= h_active;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
	
		if(!nrst)begin
			h_active2 <= 1'b0;
		end else if(h_cnt == H_FP + H_SYNC + H_BP - 1)begin
			h_active2 <= 1'b1;
		end else if(h_cnt == H_FP + H_SYNC + H_BP + 1024 - 1)begin
			h_active2 <= 1'b0;
		end else begin
			h_active2 <= h_active2;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
		
		if(!nrst)begin
			vs_reg <= 1'd0;
		end else if((v_cnt == V_FP - 1) && (h_cnt == H_FP - 1))begin
			vs_reg <= 1'b1;
		end else if((v_cnt == V_FP + V_SYNC - 1) && (h_cnt == H_FP - 1))begin
			vs_reg <= 1'b0;	
		end else begin
			vs_reg <= vs_reg;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
		
		if(!nrst)begin
			v_active <= 1'd0;
		end else if((v_cnt == V_FP + V_SYNC + V_BP - 1) && (h_cnt == H_FP - 1))begin
			v_active <= 1'b1;
		end else if((v_cnt == V_TOTAL - 1) && (h_cnt == H_FP - 1))begin
			v_active <= 1'b0;	
		end else begin
			v_active <= v_active;
		end
	end
	
	always@(posedge clk or negedge nrst)begin
		
		if(!nrst)begin
			v_active2 <= 1'd0;
		end else if((v_cnt == V_FP + V_SYNC + V_BP - 1) && (h_cnt == H_FP - 1))begin
			v_active2 <= 1'b1;
		end else if((v_cnt == V_FP + V_SYNC + V_BP + 768 - 1) && (h_cnt == H_FP - 1))begin
			v_active2 <= 1'b0;	
		end else begin
			v_active2 <= v_active2;
		end
	end
	
	// ======================================================================
	// Prefetch data
	// ======================================================================
	reg				first_read;
	
	always@(posedge clk or negedge nrst)begin
		
		if(!nrst)begin
			first_read <= 1'd0;
		end else if(
			(v_cnt == V_FP + V_SYNC + V_BP - 1 - 1) && 
			(h_cnt == H_FP + H_SYNC + H_BP - 1 - 1)
		)begin
			first_read <= 1'b1;	
		end else begin
			first_read <= 1'b0;
		end
	end
	
	reg		[3 : 0]			num_counter;
	reg		[255 : 0]		ddr_data_reg;
	
	wire	[15 : 0]		switch_wire;
	
	assign switch_wire = ddr_data_reg[240 - {num_counter, 4'b0000} +: 16];
	
	always@(posedge clk or negedge nrst)begin
	
		if(!nrst)begin
			rgb_r_reg <= 8'h00;
			rgb_g_reg <= 8'h00;
			rgb_b_reg <= 8'h00;
			
			ddr_rden <= 1'b0;
			num_counter <= 4'd0;
			
			ddr_data_reg<=256'd0;
			
		end else begin
			if(first_read==1'b1)begin
				ddr_rden<=1'b1;
			end else if(video_active2)begin
				
				num_counter <= num_counter + 1'b1;
				
				if(num_counter == 4'b0000)begin
					ddr_rden<=1'b1;
				end else begin
					ddr_rden<=1'b0;
				end
				
				if(num_counter == 4'b1111)begin
					ddr_data_reg<=ddr_data;
				end
				
				rgb_b_reg[2 : 0] <= 3'b000;
				rgb_g_reg[1 : 0] <= 2'b00;
				rgb_r_reg[2 : 0] <= 3'b000;
				
				rgb_b_reg[7 : 3] <= switch_wire[15 : 11];
				rgb_g_reg[7 : 2] <= switch_wire[10 : 5];
				rgb_r_reg[7 : 3] <= switch_wire[4 : 0];
				
			end else begin
				rgb_r_reg <= 8'h00;
				rgb_g_reg <= 8'h00;
				rgb_b_reg <= 8'h00;
				
				num_counter<=4'd0;
				ddr_rden<=1'b0;
				ddr_data_reg<=ddr_data;
			end
		end
	end
	
endmodule

/* =====================================================================
   End of File
   =====================================================================
*/
