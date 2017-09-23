`timescale 1ns/1ps

/*
  module : QAM modulation  
  created by Chen Zhongyao
  e-mail : chen_zhongyao@163.com
*/

`define QPSK

module QAM_modulation(

	clk,
	rst,

	DATAIN_EN,
	DATAIN_BIT,

	QAM_EN,
	QAM_DATA_RE,
	QAM_DATA_IM

    );

	input clk;
	input rst;

	input DATAIN_EN;
	input DATAIN_BIT;

	output QAM_EN;
	output [15:0] QAM_DATA_RE,QAM_DATA_IM; // signed 1,0.15


	`ifdef QAM16
	// 16QAM 归一化能量
	localparam ref3 = 16'sb0111_1001_0110_1110;  //  1/sqrt(10) * 3 signed 1,0.15  
	localparam ref1 = 16'sb0010_1000_0111_1010;  //  1/sqrt(10) * 1 signed 1,0.15

	reg [3:0] bit_buffer;
	reg [1:0] bit_cnt;
	reg bit_buffer_en;
 	reg QAM_EN;
 	reg signed [15:0] QAM_DATA_RE,QAM_DATA_IM;

	always@(posedge clk)
	if(!rst)
		begin
			bit_buffer <= 0;
			bit_cnt <= 0;
			bit_buffer_en <= 0;

			QAM_EN <= 0;
			QAM_DATA_RE <= 0;
			QAM_DATA_IM <= 0;
		end
	else 
		begin
			if(DATAIN_EN)
				begin
					bit_buffer[0] <= DATAIN_BIT;
					bit_buffer[3:1] <= bit_buffer[2:0];
					bit_cnt <= bit_cnt + 1'b1;
				end
			else 
				begin
					bit_cnt <= 0;
					bit_buffer <= 0;
				end

			if(bit_cnt == 2'b11)
				begin
					bit_buffer_en <= 1;
				end
			else 
				begin
					bit_buffer_en <= 0;
				end

			if(bit_buffer_en)
				begin
					QAM_EN <= 1;
					case(bit_buffer[3:2])
						2'b00: QAM_DATA_RE <= -ref3;
						2'b01: QAM_DATA_RE <= -ref1;
						2'b11: QAM_DATA_RE <= ref1;
						2'b10: QAM_DATA_RE <= ref3;
					endcase
					case(bit_buffer[1:0])
						2'b00: QAM_DATA_IM <= -ref3;
						2'b01: QAM_DATA_IM <= -ref1;
						2'b11: QAM_DATA_IM <= ref1;
						2'b10: QAM_DATA_IM <= ref3;
					endcase
				end
			else 
				begin
					QAM_EN <= 0;
					QAM_DATA_RE <= 0;
					QAM_DATA_IM <= 0;
				end
		end

	`endif

	`ifdef QPSK
	// 16QAM 归一化能量
	localparam ref2 = 16'sb0101101010000010;  //  1/sqrt(2) * 1 signed 1,0.15  

	reg [1:0] bit_buffer;
	reg bit_cnt;
	reg bit_buffer_en;
 	reg QAM_EN;
 	reg signed [15:0] QAM_DATA_RE,QAM_DATA_IM;

	always@(posedge clk)
	if(!rst)
		begin
			bit_buffer <= 0;
			bit_cnt <= 0;
			bit_buffer_en <= 0;

			QAM_EN <= 0;
			QAM_DATA_RE <= 0;
			QAM_DATA_IM <= 0;
		end
	else 
		begin
			if(DATAIN_EN)
				begin
					bit_buffer[0] <= DATAIN_BIT;
					bit_buffer[1] <= bit_buffer[0];
					bit_cnt <= bit_cnt + 1'b1;
				end
			else 
				begin
					bit_cnt <= 0;
					bit_buffer <= 0;
				end

			if(bit_cnt == 1'b1)
				begin
					bit_buffer_en <= 1;
				end
			else 
				begin
					bit_buffer_en <= 0;
				end

			if(bit_buffer_en)
				begin
					QAM_EN <= 1;
					case(bit_buffer[1])
						1'b0: QAM_DATA_RE <= -ref2;
						1'b1: QAM_DATA_RE <= ref2;
					endcase
					case(bit_buffer[0])
						1'b0: QAM_DATA_IM <= -ref2;
						1'b1: QAM_DATA_IM <= ref2;
					endcase
				end
			else 
				begin
					QAM_EN <= 0;
					QAM_DATA_RE <= 0;
					QAM_DATA_IM <= 0;
				end
		end

	`endif


endmodule
