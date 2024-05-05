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

 module reg_config(     
		  input clk_25M,
		  input camera_rstn,
		  input initial_en,
		  output reg_conf_done,
		  output i2c_sclk,
		  inout i2c_sdat
	  );

    reg clock_20k;
    reg [8:0]reg_index;
	
     reg [15:0]clock_20k_cnt;
     reg [1:0]config_step;
	  
     reg [31:0]i2c_data;
     reg [23:0]reg_data;
     reg start;
	  reg reg_conf_done_reg;
	  
     i2c_com u1(.clock_i2c(clock_20k),
               .camera_rstn(camera_rstn),
               .ack(ack),
               .i2c_data(i2c_data),
               .start(start),
               .tr_end(tr_end),
               .i2c_sclk(i2c_sclk),
               .i2c_sdat(i2c_sdat));

assign reg_conf_done=reg_conf_done_reg;
//产生i2c控制时钟-20khz    
always@(posedge clk_25M or negedge camera_rstn)   
begin
   if(!camera_rstn) begin
        clock_20k<=0;
        clock_20k_cnt<=0;
   end
   else if(clock_20k_cnt<1249)
      clock_20k_cnt<=clock_20k_cnt+1'b1;
   else begin
         clock_20k<=!clock_20k;
         clock_20k_cnt<=0;
   end
end


////iic寄存器配置过程控制    
always@(posedge clock_20k or negedge camera_rstn)    
begin
   if(!camera_rstn) begin
       config_step<=0;
       start<=0;
       reg_index<=0;
		 reg_conf_done_reg<=0;
   end
   else begin
      if(reg_conf_done_reg==1'b0) begin          //如果camera初始化未完成
			  if(reg_index<256) begin               //配置前302个寄存器
					 case(config_step)
					 0:begin
						i2c_data<={8'h78,reg_data};       //OV5640 IIC Device address is 0x78   
						start<=1;                         //i2c写开始
						config_step<=1;                  
					 end
					 1:begin
						if(tr_end) begin                  //i2c写结束               					
							 start<=0;
							 config_step<=2;
						end
					 end
					 2:begin
						  reg_index<=reg_index+1'b1;       //配置下一个寄存器
						  config_step<=0;
					 end
					 endcase
				end
			 else 
				reg_conf_done_reg<=1'b1;                //OV5640寄存器初始化完成
      end
   end
 end

////iic需要配置的寄存器值
always@(*)   
 begin
    case(reg_index)
		9'd0  : reg_data <= {24'h3103_03};
		9'd1  : reg_data <= {24'h3008_02};
		9'd2  : reg_data <= {24'h3017_ff};
		9'd3  : reg_data <= {24'h3018_ff};
		9'd4  : reg_data <= {24'h3034_1a};
		9'd5  : reg_data <= {24'h3037_14};
		9'd6  : reg_data <= {24'h3108_01};
		9'd7  : reg_data <= {24'h3630_36};
		9'd8  : reg_data <= {24'h3631_0e};
		9'd9  : reg_data <= {24'h3632_e2};
		9'd10 : reg_data <= {24'h3633_12};
		9'd11 : reg_data <= {24'h3621_e0};
		9'd12 : reg_data <= {24'h3704_a0};
		9'd13 : reg_data <= {24'h3703_5a};
		9'd14 : reg_data <= {24'h3715_78};
		9'd15 : reg_data <= {24'h3717_01};
		9'd16 : reg_data <= {24'h370b_60};
		9'd17 : reg_data <= {24'h3705_1a};
		9'd18 : reg_data <= {24'h3905_02};
		9'd19 : reg_data <= {24'h3906_10};
		9'd20 : reg_data <= {24'h3901_0a};
		9'd21 : reg_data <= {24'h3731_12};
		9'd22 : reg_data <= {24'h3600_08};
		9'd23 : reg_data <= {24'h3601_33};
		9'd24 : reg_data <= {24'h302d_60};
		9'd25 : reg_data <= {24'h3620_52};
		9'd26 : reg_data <= {24'h371b_20};
		9'd27 : reg_data <= {24'h471c_50};
		9'd28 : reg_data <= {24'h3a13_43};
		9'd29 : reg_data <= {24'h3a18_00};
		9'd30 : reg_data <= {24'h3a19_f8};
		9'd31 : reg_data <= {24'h3635_13};
		9'd32 : reg_data <= {24'h3636_03};
		9'd33 : reg_data <= {24'h3634_40};
		9'd34 : reg_data <= {24'h3622_01};
		9'd35 : reg_data <= {24'h3c01_34};
		9'd36 : reg_data <= {24'h3c04_28};
		9'd37 : reg_data <= {24'h3c05_98};
		9'd38 : reg_data <= {24'h3c06_00};
		9'd39 : reg_data <= {24'h3c07_07};
		9'd40 : reg_data <= {24'h3c08_00};
		9'd41 : reg_data <= {24'h3c09_1c};
		9'd42 : reg_data <= {24'h3c0a_9c};
		9'd43 : reg_data <= {24'h3c0b_40};
		9'd44 : reg_data <= {24'h3810_00};
		9'd45 : reg_data <= {24'h3811_10};
		9'd46 : reg_data <= {24'h3812_00};
		9'd47 : reg_data <= {24'h3708_64};
		9'd48 : reg_data <= {24'h4001_02};
		9'd49 : reg_data <= {24'h4005_1a};
		9'd50 : reg_data <= {24'h3000_00};
		9'd51 : reg_data <= {24'h3004_ff};
		9'd52 : reg_data <= {24'h300e_58};
		9'd53 : reg_data <= {24'h302e_00};
		9'd54 : reg_data <= {24'h4300_60};
		9'd55 : reg_data <= {24'h501f_01};
		9'd56 : reg_data <= {24'h440e_00};
		9'd57 : reg_data <= {24'h5000_a7};
		9'd58 : reg_data <= {24'h3a0f_30};
		9'd59 : reg_data <= {24'h3a10_28};
		9'd60 : reg_data <= {24'h3a1b_30};
		9'd61 : reg_data <= {24'h3a1e_26};
		9'd62 : reg_data <= {24'h3a11_60};
		9'd63 : reg_data <= {24'h3a1f_14};
		9'd64 : reg_data <= {24'h5800_23};
		9'd65 : reg_data <= {24'h5801_14};
		9'd66 : reg_data <= {24'h5802_0f};
		9'd67 : reg_data <= {24'h5803_0f};
		9'd68 : reg_data <= {24'h5804_12};
		9'd69 : reg_data <= {24'h5805_26};
		9'd70 : reg_data <= {24'h5806_0c};
		9'd71 : reg_data <= {24'h5807_08};
		9'd72 : reg_data <= {24'h5808_05};
		9'd73 : reg_data <= {24'h5809_05};
		9'd74 : reg_data <= {24'h580a_08};
		9'd75 : reg_data <= {24'h580b_0d};
		9'd76 : reg_data <= {24'h580c_08};
		9'd77 : reg_data <= {24'h580d_03};
		9'd78 : reg_data <= {24'h580e_00};
		9'd79 : reg_data <= {24'h580f_00};
		9'd80 : reg_data <= {24'h5810_03};
		9'd81 : reg_data <= {24'h5811_09};
		9'd82 : reg_data <= {24'h5812_07};
		9'd83 : reg_data <= {24'h5813_03};
		9'd84 : reg_data <= {24'h5814_00};
		9'd85 : reg_data <= {24'h5815_01};
		9'd86 : reg_data <= {24'h5816_03};
		9'd87 : reg_data <= {24'h5817_08};
		9'd88 : reg_data <= {24'h5818_0d};
		9'd89 : reg_data <= {24'h5819_08};
		9'd90 : reg_data <= {24'h581a_05};
		9'd91 : reg_data <= {24'h581b_06};
		9'd92 : reg_data <= {24'h581c_08};
		9'd93 : reg_data <= {24'h581d_0e};
		9'd94 : reg_data <= {24'h581e_29};
		9'd95 : reg_data <= {24'h581f_17};
		9'd96 : reg_data <= {24'h5820_11};
		9'd97 : reg_data <= {24'h5821_11};
		9'd98 : reg_data <= {24'h5822_15};
		9'd99 : reg_data <= {24'h5823_28};
		9'd100: reg_data <= {24'h5824_46};
		9'd101: reg_data <= {24'h5825_26};
		9'd102: reg_data <= {24'h5826_08};
		9'd103: reg_data <= {24'h5827_26};
		9'd104: reg_data <= {24'h5828_64};
		9'd105: reg_data <= {24'h5829_26};
		9'd106: reg_data <= {24'h582a_24};
		9'd107: reg_data <= {24'h582b_22};
		9'd108: reg_data <= {24'h582c_24};
		9'd109: reg_data <= {24'h582d_24};
		9'd110: reg_data <= {24'h582e_06};
		9'd111: reg_data <= {24'h582f_22};
		9'd112: reg_data <= {24'h5830_40};
		9'd113: reg_data <= {24'h5831_42};
		9'd114: reg_data <= {24'h5832_24};
		9'd115: reg_data <= {24'h5833_26};
		9'd116: reg_data <= {24'h5834_24};
		9'd117: reg_data <= {24'h5835_22};
		9'd118: reg_data <= {24'h5836_22};
		9'd119: reg_data <= {24'h5837_26};
		9'd120: reg_data <= {24'h5838_44};
		9'd121: reg_data <= {24'h5839_24};
		9'd122: reg_data <= {24'h583a_26};
		9'd123: reg_data <= {24'h583b_28};
		9'd124: reg_data <= {24'h583c_42};
		9'd125: reg_data <= {24'h583d_ce};
		9'd126: reg_data <= {24'h5180_ff};
		9'd127: reg_data <= {24'h5181_f2};
		9'd128: reg_data <= {24'h5182_00};
		9'd129: reg_data <= {24'h5183_14};
		9'd130: reg_data <= {24'h5184_25};
		9'd131: reg_data <= {24'h5185_24};
		9'd132: reg_data <= {24'h5186_09};
		9'd133: reg_data <= {24'h5187_09};
		9'd134: reg_data <= {24'h5188_09};
		9'd135: reg_data <= {24'h5189_75};
		9'd136: reg_data <= {24'h518a_54};
		9'd137: reg_data <= {24'h518b_e0};
		9'd138: reg_data <= {24'h518c_b2};
		9'd139: reg_data <= {24'h518d_42};
		9'd140: reg_data <= {24'h518e_3d};
		9'd141: reg_data <= {24'h518f_56};
		9'd142: reg_data <= {24'h5190_46};
		9'd143: reg_data <= {24'h5191_f8};
		9'd144: reg_data <= {24'h5192_04};
		9'd145: reg_data <= {24'h5193_70};
		9'd146: reg_data <= {24'h5194_f0};
		9'd147: reg_data <= {24'h5195_f0};
		9'd148: reg_data <= {24'h5196_03};
		9'd149: reg_data <= {24'h5197_01};
		9'd150: reg_data <= {24'h5198_04};
		9'd151: reg_data <= {24'h5199_12};
		9'd152: reg_data <= {24'h519a_04};
		9'd153: reg_data <= {24'h519b_00};
		9'd154: reg_data <= {24'h519c_06};
		9'd155: reg_data <= {24'h519d_82};
		9'd156: reg_data <= {24'h519e_38};
		9'd157: reg_data <= {24'h5480_01};
		9'd158: reg_data <= {24'h5481_08};
		9'd159: reg_data <= {24'h5482_14};
		9'd160: reg_data <= {24'h5483_28};
		9'd161: reg_data <= {24'h5484_51};
		9'd162: reg_data <= {24'h5485_65};
		9'd163: reg_data <= {24'h5486_71};
		9'd164: reg_data <= {24'h5487_7d};
		9'd165: reg_data <= {24'h5488_87};
		9'd166: reg_data <= {24'h5489_91};
		9'd167: reg_data <= {24'h548a_9a};
		9'd168: reg_data <= {24'h548b_aa};
		9'd169: reg_data <= {24'h548c_b8};
		9'd170: reg_data <= {24'h548d_cd};
		9'd171: reg_data <= {24'h548e_dd};
		9'd172: reg_data <= {24'h548f_ea};
		9'd173: reg_data <= {24'h5490_1d};
		9'd174: reg_data <= {24'h5381_1e};
		9'd175: reg_data <= {24'h5382_5b};
		9'd176: reg_data <= {24'h5383_08};
		9'd177: reg_data <= {24'h5384_0a};
		9'd178: reg_data <= {24'h5385_7e};
		9'd179: reg_data <= {24'h5386_88};
		9'd180: reg_data <= {24'h5387_7c};
		9'd181: reg_data <= {24'h5388_6c};
		9'd182: reg_data <= {24'h5389_10};
		9'd183: reg_data <= {24'h538a_01};
		9'd184: reg_data <= {24'h538b_98};
		9'd185: reg_data <= {24'h5580_06};
		9'd186: reg_data <= {24'h5583_40};
		9'd187: reg_data <= {24'h5584_10};
		9'd188: reg_data <= {24'h5589_10};
		9'd189: reg_data <= {24'h558a_00};
		9'd190: reg_data <= {24'h558b_f8};
		9'd191: reg_data <= {24'h501d_40};
		9'd192: reg_data <= {24'h5300_08};
		9'd193: reg_data <= {24'h5301_30};
		9'd194: reg_data <= {24'h5302_10};
		9'd195: reg_data <= {24'h5303_00};
		9'd196: reg_data <= {24'h5304_08};
		9'd197: reg_data <= {24'h5305_30};
		9'd198: reg_data <= {24'h5306_08};
		9'd199: reg_data <= {24'h5307_16};
		9'd200: reg_data <= {24'h5309_08};
		9'd201: reg_data <= {24'h530a_30};
		9'd202: reg_data <= {24'h530b_04};
		9'd203: reg_data <= {24'h530c_06};
		9'd204: reg_data <= {24'h5025_00};
		9'd205: reg_data <= {24'h3035_21};
		9'd206: reg_data <= {24'h3036_69};
		9'd207: reg_data <= {24'h3820_47};
		9'd208: reg_data <= {24'h3821_01};
		9'd209: reg_data <= {24'h3814_31};
		9'd210: reg_data <= {24'h3815_31};
		9'd211: reg_data <= {24'h3800_00};
		9'd212: reg_data <= {24'h3801_00};
		9'd213: reg_data <= {24'h3802_00};
		9'd214: reg_data <= {24'h3803_04};
		9'd215: reg_data <= {24'h3804_0a};
		9'd216: reg_data <= {24'h3805_3f};
		9'd217: reg_data <= {24'h3806_07};
		9'd218: reg_data <= {24'h3807_9f};
		9'd219: reg_data <= {24'h3808_04};
		9'd220: reg_data <= {24'h3809_00};
		9'd221: reg_data <= {24'h380a_03};
		9'd222: reg_data <= {24'h380b_00};
		9'd223: reg_data <= {24'h380c_07};
		9'd224: reg_data <= {24'h380d_68};
		9'd225: reg_data <= {24'h380e_03};
		9'd226: reg_data <= {24'h380f_d8};
		9'd227: reg_data <= {24'h3813_04};
		9'd228: reg_data <= {24'h3618_00};
		9'd229: reg_data <= {24'h3612_29};
		9'd230: reg_data <= {24'h3709_52};
		9'd231: reg_data <= {24'h370c_03};
		9'd232: reg_data <= {24'h3a02_02};
		9'd233: reg_data <= {24'h3a03_e0};
		9'd234: reg_data <= {24'h3a14_02};
		9'd235: reg_data <= {24'h3a15_e0};
		9'd236: reg_data <= {24'h4004_02};
		9'd237: reg_data <= {24'h3002_1c};
		9'd238: reg_data <= {24'h3006_c3};
		9'd239: reg_data <= {24'h4713_03};
		9'd240: reg_data <= {24'h4407_04};
		9'd241: reg_data <= {24'h460b_37};
		9'd242: reg_data <= {24'h460c_20};
		9'd243: reg_data <= {24'h4837_16};
		9'd244: reg_data <= {24'h3824_04};
		9'd245: reg_data <= {24'h5001_a3};
		9'd246: reg_data <= {24'h3503_00};
		9'd247: reg_data <= {24'h3a08_00};
		9'd248: reg_data <= {24'h3a09_6f};
		9'd249: reg_data <= {24'h3a0a_00};
		9'd250: reg_data <= {24'h3a0b_5c};
		9'd251: reg_data <= {24'h3a0e_06};
		9'd252: reg_data <= {24'h3a0d_08};
		9'd253: reg_data <= {24'h3016_02};
		9'd254: reg_data <= {24'h3b07_0a};
		9'd255: reg_data <= {24'h3b00_00};
		default:reg_data <= {16'hffff,8'hff};
    endcase      
end	 



endmodule

