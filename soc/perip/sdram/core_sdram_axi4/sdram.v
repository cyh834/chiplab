module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [13:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq
);

  reg state = 0;
  reg sel = 0;
  wire cmd_a = {cs,ras,cas,we} == 4'b0011;
  wire cmd_m = {cs,ras,cas,we} == 4'b0000;
  always @(posedge clk) begin
    if({cs,ras,cas,we} == 4'b0011)begin//激活
      state <= 1;
      sel <= a[13];
    end
  end
  wire css =  (cmd_a | cmd_m )? a[13] : sel;


 sdram32Cell s0(
   .clk(clk),
   .cke(cke),
   .cs(cs|css),
   .ras(ras),
   .cas(cas),
   .we(we),
   .a(a[12:0]),
   .ba(ba),
   .dqm(dqm),
   .dq(dq)
 );
 sdram32Cell s1(
   .clk(clk),
   .cke(cke),
   .cs(cs|(~css)),
   .ras(ras),
   .cas(cas),
   .we(we),
   .a(a[12:0]),
   .ba(ba),
   .dqm(dqm),
   .dq(dq)
 );

endmodule

module sdram32Cell(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq
);
  sdramCell s0(
    .clk(clk),
    .cke(cke),
    .cs(cs),
    .ras(ras),
    .cas(cas),
    .we(we),
    .a(a),
    .ba(ba),
    .dqm(dqm[1:0]),
    .dq(dq[15:0])
  );

  sdramCell s1(
    .clk(clk),
    .cke(cke),
    .cs(cs),
    .ras(ras),
    .cas(cas),
    .we(we),
    .a(a),
    .ba(ba),
    .dqm(dqm[3:2]),
    .dq(dq[31:16])
  );


endmodule

module sdramCell(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 1:0] dqm,
  inout [15:0] dq
);
  //16个存储单元    4个bank    8192行    512列
  reg [16-1:0] sdram [0:4-1][0:8192-1][0:512-1];

  wire [8:0] op;
  sdram_decode sdram_decode(
    .cmd({cs,ras,cas,we}),
    .op(op)
  );

  localparam IDLE = 2'b00, RowActive = 2'b01, Read = 2'b10 , Write = 2'b11;
  reg [1:0] state = IDLE;
  reg [47:0] rdata;
  reg [3:0] cnt;
  reg [12:0] addr;
  reg [1:0] bank;
  reg [12:0] mode;

  reg [1:0] bank_buf;
  reg [12:0] row_buf;
  wire [2:0] cl = mode[6:4];
  wire [3:0] bl = 1 << mode[2:0];

  wire [15:0] test_0 = sdram[bank_buf][row_buf][a[8:0]];
  wire [15:0] test_1 = sdram[bank_buf][row_buf][a[8:0]+1];
  wire [15:0] test_2 = sdram[bank_buf][row_buf][a[8:0]+2];
  wire [15:0] test_3 = sdram[bank_buf][row_buf][a[8:0]+3];

  /*  mode:
    [12:10] reserved
    [9:9]  burst mode
    [8:7]  operating mode
    [6:4]  cas_latency  ***
    [3:3]  burst_type
    [2:0]  burst_length ***
  */
  wire [24:0]ad = {row_buf,bank_buf,a[8:0],1'b0};
  wire [15:0] mask = {{8{~dqm[1]}},{8{~dqm[0]}}};
  always @(posedge clk) begin
      case (state)
        IDLE : begin
            if(cke)begin
              if(op[2]) begin//激活目标存储体的一行
                bank_buf <= ba;
                row_buf  <= a;
                state <= RowActive;
              end
              else if(op[8])begin //设置Mode寄存器
                mode <= a;
              end
            end
        end
        RowActive : begin
          if(cke)begin
            if(op[3])begin //读出目标存储体的一列
              bank <= ba;
              rdata[15:0] <= sdram[bank_buf][row_buf][a[8:0]] & mask; 
              if(cnt == bl + cl - 1)begin
                cnt <= 0;
                state <= RowActive;
              end
              else begin
                addr <= a + 1;
                cnt <= 1;
                state <= Read;
              end
            end
            else if(op[4])begin //写入目标存储体的一列
              bank <= ba;
              sdram[bank_buf][row_buf][a[8:0]] <= (dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask));
              if(cnt == bl - 1)begin
                cnt <= 0;
                state <= RowActive;
              end
              else begin
                addr <= a + 1;
                cnt <= 1;
                state <= Write;
              end
              //$display("state %h write %h: %h",state,ad,(dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask)));
            end
            else if(op[2]) begin//激活目标存储体的一行
              bank_buf <= ba;
              row_buf  <= a;
              state <= RowActive;
            end
          end
        end
        Read : begin
          if(cke)begin
            if(op[3])begin //读出目标存储体的一列
              addr <= a + 1;
              bank <= ba;
              rdata[15:0] <= sdram[bank_buf][row_buf][a[8:0]] & mask; 
              cnt <= 1;
              state <= Read;
            end
            else if(op[4])begin //写入目标存储体的一列
              addr <= a + 1;
              bank <= ba;
              sdram[bank_buf][row_buf][a[8:0]] <= (dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask));
              //$display("state %h write %h: %h",state,sdram[bank_buf][row_buf][a[8:0]],(dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask)));
              cnt <= 1;
              state <= Write;
            end
            else if(op[5])begin //停止当前的突发传输
              state <= RowActive;
              cnt <= 0;
            end
          end
          if(cnt == (bl+cl-1))begin
            state <= RowActive;
            cnt <= 0;
            rdata <= 0;
          end
          else if(cnt == bl)begin
            cnt <= cnt + 1;
            rdata <= {rdata[31:0],16'b0};
          end
          else begin
            if(cnt != bl-1)begin
              addr <= addr + 1;
            end
            cnt <= cnt + 1;
            rdata <= {rdata[31:0],sdram[bank_buf][row_buf][addr[8:0]] & mask};
          end

        end
        Write : begin
          if(cke)begin
            if(op[3])begin //读出目标存储体的一列
              addr <= a + 1;
              bank <= ba;
              rdata[15:0] <= sdram[bank_buf][row_buf][a[8:0]] & mask; 
              cnt <= 1;
              state <= Read;
            end
            else if(op[4])begin //写入目标存储体的一列
              addr <= a + 1;
              bank <= ba;
              sdram[bank_buf][row_buf][a[8:0]] <= (dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask));
              //$display("state %h write %h: %h",state,sdram[bank_buf][row_buf][a[8:0]],(dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask)));
              cnt <= 1;
              state <= Write;
            end
            else if(op[5])begin //停止当前的突发传输
              state <= RowActive;
              cnt <= 0;
            end
          end
          if(cnt == bl - 1)begin
            sdram[bank_buf][row_buf][addr[8:0]] <= (dq & mask) | (sdram[bank_buf][row_buf][addr[8:0]]&(~mask));
            //$display("state %h write %h: %h",state,sdram[bank_buf][row_buf][a[8:0]],(dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask)));
            state <= RowActive;
            addr <= 0;
            cnt <= 0;
          end
          else begin
            cnt <= cnt + 1;
            addr <= addr + 1;
            sdram[bank_buf][row_buf][addr[8:0]] <= (dq & mask) | (sdram[bank_buf][row_buf][addr[8:0]]&(~mask));
            //$display("state %h write %h: %h",state,sdram[bank_buf][row_buf][a[8:0]],(dq & mask) | (sdram[bank_buf][row_buf][a[8:0]]&(~mask)));
          end
        end
        default :
          state <= IDLE;
      endcase
  end

  assign dq = (state != Read) ? 16'bz :
              (cl == 3'b001 ) ? rdata[15:0]  :
              (cl == 3'b010 ) ? rdata[31:16] :
              (cl == 3'b011 ) ? rdata[47:32] : 16'bz;

endmodule

module sdram_decode (
  //cmd:{cs,ras,cas,we}
  input  [3:0] cmd,
  output [8:0] op 
);

  // op[6],op[7]视作nop 
  assign op[0] = cmd[3];           //无命令
  assign op[1] = cmd == 4'b0111;   //NOP
  assign op[2] = cmd == 4'b0011;   //激活目标存储体的一行
  assign op[3] = cmd == 4'b0101;   //读出目标存储体的一列
  assign op[4] = cmd == 4'b0100;   //写入目标存储体的一列
  assign op[5] = cmd == 4'b0110;   //停止当前的突发传输
  assign op[6] = cmd == 4'b0010;   //关闭存储体中已激活的行(预充电)
  assign op[7] = cmd == 4'b0001;   //刷新
  assign op[8] = cmd == 4'b0000;   //设置Mode寄存器

endmodule