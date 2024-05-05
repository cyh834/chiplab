`timescale 1 ns / 1 ns
module dcfifo_ctrl
(
	//global clock
	input				    clk_ref,		      //ȫ��ʱ��
	input 			        clk_write,		      //fifoд����ʱ��
	input				    clk_read,		      //fifo������ʱ��
	input 			        rst_n,			      //ȫ�ָ�λ
	
	//burst length
	input		[9:0]	 	wr_length,		      //ddr��ͻ������
	input		[9:0]	 	rd_length,		      //ddrдͻ������
	input		[24:0]   	wr_addr,		      //ddrд��ַ
	input		[24:0]   	wr_max_addr,	      //ddr���д��ַ
	input		[24:0]   	rd_addr,		      //ddr����ַ
	input		[24:0] 	    rd_max_addr,	      //ddr������ַ	
	input				 	vout_vs,		      //
    input				 	vin_vs,		          //
	
	//wrfifo:  fifo 2 ddr
	input 			 	   wrf_wrreq,		      //д��ddr���ݻ���fifo��������,��Ϊfifoд�ź�
	input		[255:0]    wrf_din,		         //д��ddr���ݻ���fifoд�����ߣ�д��sdram���ݣ�
	output 	reg	 	       ddr_wr_req,	         //д��ddr�����ź�
	input 			 	   ddr_wr_ack,	         //д��ddr��Ӧ�ź�,��Ϊfifo���ź�
	output	    [255:0]    ddr_din,		         //д��ddr���ݻ���fifo�����������
	output	reg	[24:0] 	   ddr_wraddr,	        //д��ddrʱ��ַ�ݴ���
    input                  ddr_wr_finish,       //д��ddr�������
	
	//rdfifo: sdram 2 fifo
	input 				   rdf_rdreq,		      //��ȡddr���ݻ���fifo�������
	output	    [255:0]    rdf_dout,		      //��ȡddr���ݻ���fifo������ߣ���ȡsdram���ݣ�
	output 	reg			   ddr_rd_req,	          //��ȡddr�����ź�
	input 				   ddr_rd_ack,	          //��ȡddr��Ӧ�ź�,��Ϊfifo����д��Ч�ź�
	input		[255:0]    ddr_dout,		      //��ȡddr���ݻ���fifo��������
	output	reg	[24:0] 	   ddr_rdaddr,	          //��ȡddrʱ��ַ�ݴ�����{bank[1:0],row[11:0],column[7:0]} 
   input                   ddr_rd_finish,         //��ddr�������
	
	//sdram address control	
	input				   ddr_init_done,	       //ddr��ʼ������ź�
	output	reg		       frame_write_done,	   //ddr write one frame
	output	reg		       frame_read_done	       //ddr read one frame
	
);


//------------------------------------------------
//?ͬ��sdram��д��ַ��ʼֵ��λ�ź�
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

wire	wr_load_flag = (~vin_vs_d2) & vin_vs_d1;	    //д��ַ���������ر�־λ
wire	rd_load_flag = (~vout_vs_d2) & vout_vs_d1;	//����ַ���������ر�־λ

//------------------------------------------------
//ddrд��ַ����ģ�飨���ȣ�
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		ddr_wraddr <= 25'd0;	
		frame_write_done <= 1'b0;
		end			
	else if(wr_load_flag)						//����ddrд�����ַ
		begin
		ddr_wraddr <= wr_addr;	
		frame_write_done <= 1'b0;	
		end		
	else if(ddr_wr_finish)						//ͻ��д�����
		begin
		if(ddr_wraddr < wr_max_addr - wr_length)
			begin
			ddr_wraddr <= ddr_wraddr + wr_length;   //ddr�ĵ�ַ����
			frame_write_done <= 1'b0;
			end
		else
			begin
			ddr_wraddr <= ddr_wraddr;		//��ֹ����������ַ
			frame_write_done <= 1'b1;
			end
		end
	else
		begin
		ddr_wraddr <= ddr_wraddr;			//�����ַ
		frame_write_done <= frame_write_done;
		end
end

//------------------------------------------------
//ddr����ַ����ģ��(���)
always @(posedge clk_ref or negedge rst_n)
begin
	if(!rst_n)
		begin
		ddr_rdaddr <= 25'd0;
		frame_read_done <= 0;
		end
	else if(rd_load_flag)						//����ddr��ȡ����ַ
		begin
		ddr_rdaddr <= rd_addr;
		frame_read_done <= 0;
		end
	else if(ddr_rd_finish)						//ͻ��д�����
		begin
		if(ddr_rdaddr < rd_max_addr - rd_length)
			begin
			ddr_rdaddr <= ddr_rdaddr + rd_length;
			frame_read_done <= 0;
			end
		else
			begin
			ddr_rdaddr <= ddr_rdaddr;		//��ֹ����������ַ
			frame_read_done <= 1;
			end
		end
	else
		begin
		ddr_rdaddr <= ddr_rdaddr;			//�����ַ
		frame_read_done <= frame_read_done;
		end
end


//-------------------------------------
//ddr ��д�źŲ���ģ��
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
		begin						      //д�����ȣ������ڷ�ֹ���ݶ�ʧ
		if( (wrf_use >= wr_length) & !wr_flag)	//д��FIFO��������������burst����,дDDR��ʼ	       
			begin					      //wrfifo��ͻ������
			ddr_wr_req <= 1;		//дddrʹ��
			wr_flag <= 1;
			end
		else if(ddr_wr_finish)//��FIFO�����������С��burst����,��DDR��ʼ	
			begin					//rdfifo��ͻ������
			ddr_wr_req <= 0;		//дddr����
			wr_flag <= 0;
			end
		end
	else
		begin
		ddr_wr_req <= 0;			//дddr����
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
		begin						      //д�����ȣ������ڷ�ֹ���ݶ�ʧ
		 if( (rdf_use <= rd_length) &  !rd_flag)//��FIFO�����������С��burst����,��DDR��ʼ	
			begin					//rdfifo��ͻ������
			ddr_rd_req <= 1;		//��ddrmʹ��
			rd_flag <= 1;
			end
		else if(ddr_rd_finish)
			begin
			ddr_rd_req <= 0;		//��ddr����
			rd_flag <= 0;
			end
		end
	else
		begin
		ddr_rd_req <= 0;			//��ddr����
		end
end

wire fifo_wr_rst = (~rst_n) | wr_load_flag;
wire fifo_rd_rst = (~rst_n) | rd_load_flag;


rwfifo	u_wrfifo(
	
	.Reset	(fifo_wr_rst),			//wrfifo�첽�����źţ�����Ҫ��| wr_load_flag

	//input 2 fifo
	.WrClk		    (clk_write),		//wrfifoдʱ��
	.WrEn		    (wrf_wrreq),		//wrfifoдʹ���ź�
	.Data		    (wrf_din),			//wrfifo������������
	//fifo 2sdram
	.RdClk		    (clk_ref),			//wrfifo��ʱ��100MHz
	.RdEn		    (ddr_wr_ack),		//wrfifo��ʹ���ź�
	.Q			(ddr_din),		//wrfifo�����������
	//user port
   .Full		(), // output full
   .Empty		(), // output empty
   .Rnum		(wrf_use),			//wrfifo�洢��������
   .Wnum		()			
);	


//------------------------------------------------
//����ddr�������ݻ���fifoģ��
rwfifo	u_rdfifo
(
	.Reset		    (fifo_rd_rst),		//rdfifo�첽�����ź�   
	//sdram 2 fifo
	.WrClk		    (clk_ref),       	//rdfifoдʱ��
	.WrEn		    (ddr_rd_ack),  	//rdfifoдʹ���ź�
	.Data		    (ddr_dout),  		//rdfifo������������
	//fifo 2 output 
	.RdClk		    (clk_read),         //rdfifo��ʱ��50MHz
	.RdEn		    (rdf_rdreq),     	//rdfifo��ʹ���ź�
	.Q			(rdf_dout),			//rdfifo�����������
	//user port
	.Full           (), // output full
    .Empty	(), // output empty
	.Rnum	(),                //rdfifo�洢��������
	.Wnum	(rdf_use)          //rdfifo�洢��������
);


endmodule
