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

module tb_rwfifo;
	
	reg  	clka;
	reg  	clkb;
	reg  	sys_rst;
	
	wire	[255 : 0]	Q;
	
	reg		[255 : 0]	dum_din;
	reg					dum_wen;
	reg					dum_ren;
	
	wire	[9 : 0]	dum_wcnt;
	wire	[9 : 0]	dum_rcnt;
	
	
	initial begin
		
		forever begin
			#2.5 clka = ~clka;
		end
	end
	
	initial begin
		forever begin
			#2.8 clkb = ~clkb;
		end
	end
	
	integer lp0;
	
	initial begin
		fork begin
			
			#0 clka = 1'b0;
			clkb = 1'b0;
			sys_rst = 1'b1;
			dum_ren = 1'b0;
			dum_wen = 1'b0;
			dum_din = 256'd0;
			
			#1324 sys_rst = 1'b0;
			
			for(lp0=0;lp0<1024;lp0=lp0+1)begin
				#12 dum_din = {
					$urandom(),
					$urandom(),
					$urandom(),
					$urandom(),
					$urandom(),
					$urandom(),
					$urandom(),
					$urandom()
				};
				dum_wen = 1'b1;
				
				if(lp0 >= 233)begin
					dum_ren = 1'b1;
				end
				
				#12 dum_wen = 1'b0;
				dum_ren = 1'b0;
			end
			
		end join
	end
	
	rwfifo DUT(
		.WrClk				(clka),
		.Reset				(sys_rst),
		.Data				(dum_din),
		.WrEn				(dum_wen),
		.Wnum				(dum_wcnt),
		.RdClk				(clkb),
		.RdEn				(dum_ren),
		.Rnum				(dum_rcnt),
		.Q					(Q)
	);

endmodule

/* =====================================================================
   End of File
   =====================================================================
*/
