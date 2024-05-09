`timescale 1 ns / 1 ns
module dcfifo_ctrl
(
	//global clock
	input				    clk_ref,		      //??????
	input 			        clk_write,		      //fifo��???????
	input				    clk_read,		      //fifo?????????
	input 			        rst_n,			      //????��
	
	//burst length
	input		[9:0]	 	wr_length,		      //ddr?????????
	input		[9:0]	 	rd_length,		      //ddr��???????
	input		[24:0]   	wr_addr,		      //ddr��???
	input		[24:0]   	wr_max_addr,	      //ddr???��???
	input		[24:0]   	rd_addr,		      //ddr?????
	input		[24:0] 	    rd_max_addr,	      //ddr???????	
	input				 	vout_vs,		      //
    input				 	vin_vs,		          //
	
	//wrfifo:  fifo 2 ddr
	input 			 	   wrf_wrreq,		      //��??ddr???????fifo????????,???fifo��???
	input		[255:0]    wrf_din,		         //��??ddr???????fifo��???????��??sdram?????
	output 	reg	 	       ddr_wr_req,	         //��??ddr???????
	input 			 	   ddr_wr_ack,	         //��??ddr??????,???fifo?????
	output	    [255:0]    ddr_din,		         //��??ddr???????fifo???????????
	output	reg	[24:0] 	   ddr_wraddr,	        //��??ddr?????????
    input                  ddr_wr_finish,       //��??ddr???????
	
	//rdfifo: sdram 2 fifo
	input 				   rdf_rdreq,		      //???ddr???????fifo???????
	output	    [255:0]    rdf_dout,		      //???ddr???????fifo???????????sdram?????
	output 	reg			   ddr_rd_req,	          //???ddr???????
	input 				   ddr_rd_ack,	          //???ddr??????,???fifo????��??��???
	input		[255:0]    ddr_dout,		      //???ddr???????fifo????????
	output	reg	[24:0] 	   ddr_rdaddr,	          //???ddr???????????{bank[1:0],row[11:0],column[7:0]} 
   input                   ddr_rd_finish,         //??ddr???????
	
	//sdram address control	
	input				   ddr_init_done,	       //ddr???????????
	output	reg		       frame_write_done,	   //ddr write one frame
	output	reg		       frame_read_done	       //ddr read one frame
	
);


//------------------------------------------------
//????sdram??��?????????��???
reg vin_vs_d0;
reg vin_vs_d1;
reg vin_vs_d2;

reg vout_vs_d0;
reg vout_vs_d1;
reg vout_vs_d2;
always@(posedge clk_ref)
begin
    vin_vs_d0 <= vin_vs;
    vin_vs_d1 <= vin_vs_d0;
    vin_vs_d2 <= vin_vs_d1;
end

always@(posedge clk_ref)
begin
    vout_vs_d0 <= vout_vs;
    vout_vs_d1 <= vout_vs_d0;
    vout_vs_d2 <= vout_vs_d1;
end

wire	wr_load_flag = (~vin_vs_d2) & vin_vs_d1;	    //��???????????????��
wire	rd_load_flag = (~vout_vs_d2) & vout_vs_d1;	//?????????????????��

//------------------------------------------------
//ddr��?????????��?????
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		ddr_wraddr <= 25'd0;	
		frame_write_done <= 1'b0;
		end			
	else if(wr_load_flag)						//????ddr��??????
		begin
		ddr_wraddr <= wr_addr;	
		frame_write_done <= 1'b0;	
		end		
	else if(ddr_wr_finish)						//???��?????
		begin
		if(ddr_wraddr < wr_max_addr - wr_length)
			begin
			ddr_wraddr <= ddr_wraddr + wr_length;   //ddr????????
			frame_write_done <= 1'b0;
			end
		else
			begin
			ddr_wraddr <= ddr_wraddr;		//??????????????
			frame_write_done <= 1'b1;
			end
		end
	else
		begin
		ddr_wraddr <= ddr_wraddr;			//??????
		frame_write_done <= frame_write_done;
		end
end

//------------------------------------------------
//ddr????????????(???)
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		ddr_rdaddr <= 25'd0;
		frame_read_done <= 0;
		end
	else if(rd_load_flag)						//????ddr????????
		begin
		ddr_rdaddr <= rd_addr;
		frame_read_done <= 0;
		end
	else if(ddr_rd_finish)						//???��?????
		begin
		if(ddr_rdaddr < rd_max_addr - rd_length)
			begin
			ddr_rdaddr <= ddr_rdaddr + rd_length;
			frame_read_done <= 0;
			end
		else
			begin
			ddr_rdaddr <= ddr_rdaddr;		//??????????????
			frame_read_done <= 1;
			end
		end
	else
		begin
		ddr_rdaddr <= ddr_rdaddr;			//??????
		frame_read_done <= frame_read_done;
		end
end


//-------------------------------------
//ddr ??��?????????
wire	[9:0] 	wrf_use;
wire	[9:0] 	rdf_use;
reg wr_flag;
reg rd_flag;
always@(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)	
		begin
		ddr_wr_req <= 0;
		wr_flag <= 0;
		end
	else if(wr_load_flag)
	begin
	   wr_flag <= 0;
	   ddr_wr_req <= 0;
	end
	else if(ddr_init_done == 1'b1)
		begin						      //��?????????????????????
		if( (wrf_use >= wr_length) & !wr_flag)	//��??FIFO??????????????burst????,��DDR???	       
			begin					      //wrfifo?????????
			ddr_wr_req <= 1;		//��ddr???
			wr_flag <= 1;
			end
		else if(ddr_wr_finish)//??FIFO???????????��??burst????,??DDR???	
			begin					//rdfifo?????????
			ddr_wr_req <= 0;		//��ddr????
			wr_flag <= 0;
			end
		end
	else
		begin
		ddr_wr_req <= 0;			//��ddr????
		end
end


always@(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)	
		begin
		ddr_rd_req <= 0;
		rd_flag <= 0;
		end
	else if(rd_load_flag)
	begin
    ddr_rd_req <= 0;
    rd_flag <= 0;
    end
	else if(ddr_init_done == 1'b1)
		begin						      //��?????????????????????
		 if( (rdf_use <= rd_length) &  !rd_flag)//??FIFO???????????��??burst????,??DDR???	
			begin					//rdfifo?????????
			ddr_rd_req <= 1;		//??ddrm???
			rd_flag <= 1;
			end
		else if(ddr_rd_finish)
			begin
			ddr_rd_req <= 0;		//??ddr????
			rd_flag <= 0;
			end
		end
	else
		begin
		ddr_rd_req <= 0;			//??ddr????
		end
end

wire fifo_wr_rst = (~rst_n) | wr_load_flag;
wire fifo_rd_rst = (~rst_n) | rd_load_flag;


rwfifo	u_wrfifo(
	
	.Reset	(fifo_wr_rst),			//wrfifo?????????????????| wr_load_flag

	//input 2 fifo
	.WrClk		    (clk_write),		//wrfifo��???
	.WrEn		    (wrf_wrreq),		//wrfifo��??????
	.Data		    (wrf_din),			//wrfifo????????????
	//fifo 2sdram
	.RdClk		    (clk_ref),			//wrfifo?????100MHz
	.RdEn		    (ddr_wr_ack),		//wrfifo????????
	.Q			(ddr_din),		//wrfifo???????????
	//user port
   .Full		(), // output full
   .Empty		(), // output empty
   .Rnum		(wrf_use),			//wrfifo?��????????
   .Wnum		()			
);	


//------------------------------------------------
//????ddr???????????fifo???
rwfifo	u_rdfifo
(
	.Reset		    (fifo_rd_rst),		//rdfifo?????????   
	//sdram 2 fifo
	.WrClk		    (clk_ref),       	//rdfifo��???
	.WrEn		    (ddr_rd_ack),  	//rdfifo��??????
	.Data		    (ddr_dout),  		//rdfifo????????????
	//fifo 2 output 
	.RdClk		    (clk_read),         //rdfifo?????50MHz
	.RdEn		    (rdf_rdreq),     	//rdfifo????????
	.Q			(rdf_dout),			//rdfifo???????????
	//user port
	.Full           (), // output full
    .Empty	(), // output empty
	.Rnum	(),                //rdfifo?��????????
	.Wnum	(rdf_use)          //rdfifo?��????????
);


endmodule
