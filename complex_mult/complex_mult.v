`timescale 1ns / 1ps

/*
* module: 		complex_mult
* file name: 	complex_mult.v
* author: 		Chen Zhongyao
* date: 		2016-04-01
* description:
* 				use LEs implement
*               input signed width 16 bits
*				output signed width 33 bits
*
*  Complex Multilier
*  The following code implements a parameterizable complex multiplier
*  The style described uses LEs to implement the complex multiplier
*  taking advantage of the pre-adder, so widths chosen should be less than what the architecture supports or else extra-logic/extra DSPs will be inferred
*  parameter WIDTH = <WIDTH>;  // size input of multiplier
*/

module complex_mult
#(
	parameter WIDTH = 16,
	parameter INPUT_BUF = "ON",
	parameter OUTPUT_BUF = "ON"
)(
	input wire clk,               // Clock
	input wire ab_valid,
	input wire signed [WIDTH-1:0] 	    ar, ai, // 1st inputs real and imaginary parts
	input wire signed [WIDTH-1:0] 	    br, bi, // 2nd inputs real and imaginary parts
	output reg p_valid,
	output reg signed [WIDTH+WIDTH:0] pr, pi // output signal

    );

reg ab_valid_buf;
reg signed [WIDTH-1:0] ar_buf,ai_buf,br_buf,bi_buf;

/* input buf */
	generate if ( INPUT_BUF == "ON" )

      always@(posedge clk)
	  	{ ab_valid_buf,ar_buf,ai_buf,br_buf,bi_buf } <= { ab_valid,ar,ai,br,bi };

   else if (INPUT_BUF == "OFF")

      always@(*)
	  	{ ab_valid_buf,ar_buf,ai_buf,br_buf,bi_buf } = { ab_valid,ar,ai,br,bi };

   endgenerate
/* end of input buffer */

reg booth_mult_En;
reg signed [WIDTH:0] common_M,common_Q,real_mult1,real_mult2,imag_mult1,imag_mult2;

always @ (posedge clk) begin
	booth_mult_En <= ab_valid_buf;

	common_M <= ar_buf - ai_buf;
	common_Q <= bi_buf;

	real_mult1 <= br_buf - bi_buf;
	real_mult2 <= ar_buf;

	imag_mult1 <= br_buf + bi_buf;
	imag_mult2 <= ai_buf;

end

wire booth_mult_Valid;
wire signed [2*(WIDTH+1)-1:0] common_Product,real_Product,imag_Product;

Booth_Multiplier_inside_cmult #(
	.WIDTH(WIDTH+1)                // Width = WIDTH: multiplicand & multiplier
)booth_mult0(
    .Rst_n(1'b1),
    .Clk(clk),
    .En(booth_mult_En),
    .M(common_M),
    .Q(common_Q),
    .Valid(booth_mult_Valid),
    .Product(common_Product)
);

Booth_Multiplier_inside_cmult #(
	.WIDTH(WIDTH+1)                // Width = WIDTH: multiplicand & multiplier
)booth_mult1(
    .Rst_n(1'b1),
    .Clk(clk),
    .En(booth_mult_En),
    .M(real_mult1),
    .Q(real_mult2),
    .Valid(),
    .Product(real_Product)
);

Booth_Multiplier_inside_cmult #(
	.WIDTH(WIDTH+1)                // Width = WIDTH: multiplicand & multiplier
)booth_mult2(
    .Rst_n(1'b1),
    .Clk(clk),
    .En(booth_mult_En),
    .M(imag_mult1),
    .Q(imag_mult2),
    .Valid(),
    .Product(imag_Product)
);


/* output buf */
	generate if ( OUTPUT_BUF == "ON" )

      always@(posedge clk)begin
	  	p_valid <= booth_mult_Valid;
		pr <= real_Product + common_Product;
		pi <= imag_Product + common_Product;
	  end

   else if (OUTPUT_BUF == "OFF")

	   always@(*)begin
		 p_valid = booth_mult_Valid;
		 pr = real_Product + common_Product;
		 pi = imag_Product + common_Product;
	   end

   endgenerate
/* end of output buffer */


endmodule


// http://www.cnblogs.com/ruowei/p/5891029.html

module Booth_Multiplier_inside_cmult #(
    parameter WIDTH = 16                // Width = WIDTH: multiplicand & multiplier
)(
    input wire Rst_n,              // Reset_n
    input wire Clk,                    // Clock

    input wire En,                     // Load Registers and Start Multiplier
    input wire [(WIDTH - 1):0] M,      // Multiplicand
    input wire [(WIDTH - 1):0] Q,      // Multiplier
    output reg Valid,              // Product Valid
    output reg [(2*WIDTH - 1):0] Product   // Product <= M * R
);

  wire [(WIDTH-1):0] A=0;
  wire Q_assist=0;

  wire [3*WIDTH:0] i_temp[(WIDTH-1):0];
  wire [3*WIDTH:0] o_temp[(WIDTH-1):0];

  assign i_temp[0] = {M,Q_assist,A,Q};

  genvar vari;
  generate
      for(vari = 0;vari < WIDTH; vari = vari+1) begin: Booth
          Booth_Shift_inside_mult#(
            .WIDTH(WIDTH)
          )inst_booths(
            .Clk(Clk),
            .Rst_n(Rst_n),
            .i(i_temp[vari]),
            .o(o_temp[vari])
            );
      end

      for(vari = 0;vari < WIDTH-1; vari = vari+1)
        assign i_temp[vari+1] = o_temp[vari];

  endgenerate

  reg [WIDTH-1:0] en_shift;

  always @ (posedge Clk)
  if(~Rst_n)begin
    en_shift <= 0;
    Valid <= 0;
    Product <= 0;
  end
  else begin
    en_shift <= {en_shift[WIDTH-2:0],En};
    if (en_shift[WIDTH-1] == 1'b1)begin
      Valid <= 1;
      Product <= o_temp[WIDTH-1][(2*WIDTH - 1):0];
    end
    else begin
      Valid <= 0;
      Product <= 0;
    end
  end

endmodule


module Booth_Shift_inside_mult #(
    parameter WIDTH = 16                // Width = WIDTH: multiplicand & multiplier
)(
    input wire Rst_n,              // Reset_n
    input wire Clk,                    // Clock
    input wire [3*WIDTH:0] i,
    output wire [3*WIDTH:0] o
);

  wire [(WIDTH - 1):0] M_i;      // Multiplicand
  wire [(WIDTH - 1):0] Q_i;      // Multiplier
  wire [(WIDTH - 1):0] A_i;
  wire Q_assist_i;
  wire [(WIDTH - 1):0] M_o;   // Product <= M * R
  wire [(WIDTH - 1):0] Q_o;   // Product <= M * R
  wire [(WIDTH - 1):0] A_o;   // Product <= M * R
  wire Q_assist_o;

  assign {M_i,Q_assist_i,A_i,Q_i} = i;


  reg [(WIDTH - 1):0] b;
  wire [(WIDTH - 1):0] a,out;
  reg cin;

  reg [(WIDTH - 1):0] M_temp;
  reg [(WIDTH - 1):0] A_temp,Q_temp;
  reg Q_assist_temp;

  always @ (posedge Clk)
  if (~Rst_n) begin
    {cin,b} <= 0;
    M_temp <= 0;
    A_temp <= 0;
    Q_temp <= 0;
    Q_assist_temp <= 0;
  end
  else begin
    case ({Q_i[0],Q_assist_i})
      2'b01: { cin,b } <= { 1'b0,M_i };
      2'b10: { cin,b } <= { 1'b1,~M_i };
      default: { cin,b } <= 0;
    endcase
    M_temp <= M_i;
    A_temp <= A_i;
    Q_temp <= Q_i;
    Q_assist_temp <= Q_assist_i;
  end

  assign a = A_temp;
  assign out = a + b + cin;  // full adder

  assign M_o = M_temp;
  assign {A_o, Q_o, Q_assist_o} = $signed({out, Q_temp, Q_assist_temp}) >>> 1;

  assign o = {M_o,Q_assist_o,A_o,Q_o};

endmodule
