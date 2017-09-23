`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: HIT
// Engineer:  Zhongyao Chen
// 
// Create Date: 2016/04/01 09:24:32
// Design Name: 
// Module Name: complex_mult
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: signed input width 16
//				signed output width 33 
//				output delay 5 clock cycles
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module complex_mult(

	clk,

	ab_valid,
	ar,ai,
	br,bi,

	p_valid,
	pr,pi

    );

	parameter WIDTH=16;

//  Complex Multilier
//  The following code implements a parameterizable complex multiplier
//  The style described uses 3 DSP's to implement the complex multiplier
//  taking advantage of the pre-adder, so widths chosen should be less than what the architecture supports or else extra-logic/extra DSPs will be inferred 
//parameter WIDTH = <WIDTH>;  // size of 1st input of multiplier
//parameter WIDTH = <WIDTH>;  // size of 2nd input of multiplier 

input clk;               // Clock 
input ab_valid;
input signed [WIDTH-1:0] 	    ar, ai; // 1st inputs real and imaginary parts
input signed [WIDTH-1:0] 	    br, bi; // 2nd inputs real and imaginary parts
output p_valid;
output signed [WIDTH+WIDTH:0] pr, pi; // output signal 


reg signed [WIDTH-1:0]	ai_d, ai_dd, ai_ddd, ai_dddd; 
reg signed [WIDTH-1:0]	ar_d, ar_dd, ar_ddd, ar_dddd; 
reg signed [WIDTH-1:0]	bi_d, bi_dd, bi_ddd, br_d, br_dd, br_ddd; 
reg signed [WIDTH:0]		addcommon; 
reg signed [WIDTH:0]		addr, addi; 
reg signed [WIDTH+WIDTH:0]	mult0, multr, multi, pr_int, pi_int; 
reg signed [WIDTH+WIDTH:0]	common, commonr1, commonr2; 


	reg [5:0] data_valid_reg;

	always@(posedge clk)
	begin
		data_valid_reg[0] <= ab_valid;
		data_valid_reg[5:1] <= data_valid_reg[4:0];
	end

	assign p_valid = data_valid_reg[5];

always @(posedge clk)
  begin
    ar_d   <= ar;
    ar_dd  <= ar_d;
    ai_d   <= ai;
    ai_dd  <= ai_d;
    br_d   <= br;
    br_dd  <= br_d;
    br_ddd <= br_dd;
    bi_d   <= bi;
    bi_dd  <= bi_d;
    bi_ddd <= bi_dd;
  end
 
   // Common factor (ar ai) x bi, shared for the calculations of the real and imaginary final products
   // 
always @(posedge clk)
 begin
	addcommon <= ar_d - ai_d;
	mult0     <= addcommon * bi_dd;
	common    <= mult0;
 end

   // Real product
   //
always @(posedge clk)
 begin
	ar_ddd   <= ar_dd;
	ar_dddd  <= ar_ddd;
	addr     <= br_ddd - bi_ddd;
	multr    <= addr * ar_dddd;
	commonr1 <= common;
	pr_int   <= multr + commonr1;
 end

   // Imaginary product
   //
always @(posedge clk)
 begin
	ai_ddd   <= ai_dd;
	ai_dddd  <= ai_ddd;
	addi     <= br_ddd + bi_ddd;	 
	multi    <= addi * ai_dddd;
	commonr2 <= common;
	pi_int   <= multi + commonr2;
 end

assign pr = pr_int;
assign pi = pi_int;

				
				
endmodule
