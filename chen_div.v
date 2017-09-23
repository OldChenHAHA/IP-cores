
/*  
* module:chen_div_tb  
* file name:chen_div_tb.v  
* author: Chen Zhongyao
* date:2016-04-27  
* description:  this is a test module for chen_unsigned_div and chen_signed_div
*/  
  
`timescale 1ns/1ns  
module chen_div_tb;  
  
	reg clk=0,rst=0;
	initial #30 rst=1;
	always#10 clk=~clk;

	/* test unsigned div */
	reg divide_en=0;
	reg [31:0] dividend=0,divisor=0;

	integer i=0;
	always@(posedge clk)
	begin
		i <= i + 1;
		if(i==7)
			begin
				divide_en=1; dividend={16'd10,16'd0};divisor={16'd0,16'd3};
			end
		else if(i==8)
			begin
				divide_en=1; dividend=10;divisor=2;
			end
		else 
			begin
				divide_en=0; dividend=0;divisor=0;
			end
	end

    wire divide_error;
    wire divide_done;
    wire [31:0] quotient;
    wire [31:0] remainde;

	chen_unsigned_div chen_unsigned_div( 
		.clk(clk),
		.rst_n(rst),
		.divide_en(divide_en),
		.dividend(dividend),
		.divisor(divisor),
		.divide_error(divide_error),
		.divide_done(divide_done),
		.quotient(quotient),
		.remainde(remainde) 
		); 

	/* test signed div */

	reg divide_en_signed=0;
	reg [15:0] dividend_signed=0,divisor_signed=0;

	integer j=0;
	always@(posedge clk)
	begin
		j <= j + 1;
		if(j==7)
			begin
				divide_en_signed=1; dividend_signed=-16'sd10;divisor_signed=16'sd3;
			end
		else if(j==8)
			begin
				divide_en_signed=1; dividend_signed=-16'sd10;divisor_signed=16'sd0;
			end
		else 
			begin
				divide_en_signed=0; dividend_signed=0;divisor_signed=0;
			end
	end

	wire divide_error_signed;
    wire divide_done_signed;
    wire [31:0] quotient_signed;

	chen_signed_div chen_signed_div( 
		.clk(clk),
		.rst_n(rst),
		.divide_en(divide_en_signed),
		.dividend(dividend_signed),
		.divisor(divisor_signed),
		.divide_error(divide_error_signed),
		.divide_done(divide_done_signed),
		.quotient(quotient_signed) 
		);
  
endmodule  

/*  
* module:chen_signed_div  
* file name:chen_signed_div.v  
* author: Chen Zhongyao
* date:2016-04-27  
* description:  
*				This is a signed divider module, input ports is 16 bits signed integer, output ports only have quotient, 
*					which has 32bits containing a sign bit, 15 whole bits and 16 decimal bits.
*				Port divide_en and divide_done is the syn enable signal for input and output value. 
*				If divisor is a zero input when divide_en is set to 1, when calculation is done, the port divide_error 
*					will be set to 1 with the divide_done signal. 
*/  

module chen_signed_div ( clk,rst_n,divide_en,dividend,divisor,divide_error,divide_done,quotient );

	parameter width = 16;   

	input clk;
	input rst_n;
	input divide_en;
	input[15:0] dividend;   
	input[15:0] divisor;  
	
	output reg divide_error;
	output reg divide_done;
	output reg [31:0] quotient;  // signed 1,15.16

	reg divide_en_temp;
	reg divide_sign_temp;
	reg [31:0] divide_dividend_temp;
	reg [31:0]divide_divisor_temp;

	reg [33:0] divide_sign_temp_shift_reg;

	wire divide_error_temp;
	wire divide_done_temp;
	wire [31:0] quotient_temp;

	always@(posedge clk)
	if(~rst_n)
		begin
			divide_en_temp <= 0;
			divide_sign_temp <= 0;
			divide_dividend_temp <= 0;
			divide_divisor_temp <= 0;
			divide_sign_temp_shift_reg <= 0;
			divide_done <= 0;
			divide_error <= 0;
			quotient <= 0;
		end
	else 
		begin
			divide_en_temp <= divide_en;
			divide_sign_temp <= dividend[15]^divisor[15];
			divide_dividend_temp <= { abs(dividend),16'sb0 };
			divide_divisor_temp <= { 16'sb0,abs(divisor) };

			divide_sign_temp_shift_reg <= {divide_sign_temp_shift_reg[32:0],divide_sign_temp};

			divide_done <= divide_done_temp;
			divide_error <= divide_error_temp;
			quotient <= divide_done_temp?unsignedtosigned(quotient_temp,divide_sign_temp_shift_reg[33]):0;
		end


	chen_unsigned_div#(
		.width (32) 
		) inst_chen_unsigned_div( 
		.clk(clk),
		.rst_n(rst_n),
		.divide_en(divide_en_temp),
		.dividend(divide_dividend_temp),
		.divisor(divide_divisor_temp),
		.divide_error(divide_error_temp),
		.divide_done(divide_done_temp),
		.quotient(quotient_temp),
		.remainde() 
		); 


	function [15:0] abs; 
	   input [15:0] x;  
	   begin
	   		abs = x[15]?~x+1'b1:x;
	   end
	endfunction

	function [31:0] unsignedtosigned; 
	   input [31:0] x;
	   input sign;  
	   begin
	   		unsignedtosigned = sign?~x+1'b1:x;
	   end
	endfunction

endmodule


/*  
* module:chen_unsigned_div  
* file name:chen_unsigned_div.v  
* author: Chen Zhongyao
* date:2016-04-27  
* description:  
*				This is a unsigned divider module, input ports is 32 bits unsigned integer, output ports have quotient and remainde,both are 32 bits
*				Port divide_en and divide_done is the syn enable signal for input and output value. 
*				If divisor is a zero input when divide_en is set to 1, when calculation is done, the port divide_error 
*					will be set to 1 with the divide_done signal. 
* for example: 
*			 input dividend = 32'd10  divisor=32'd3
* 			 output will be quotient = 32'd3  remainde = 32'd1
*/  
  
module chen_unsigned_div ( clk,rst_n,divide_en,dividend,divisor,divide_error,divide_done,quotient,remainde );  

	parameter width = 32;

	input clk;
	input rst_n;
	input divide_en;
	input[width-1:0] dividend;   
	input[width-1:0] divisor;  
	
	output divide_error;
	output divide_done;
	output [width-1:0] quotient;
	output [width-1:0] remainde;

	/* input temp */
	
	reg temp_en;
	reg[width*2-1:0] temp_a;  
	reg[width*2-1:0] temp_b; 

	reg divide_error_temp;

	always@(posedge clk)
	if(~rst_n)
		begin
			divide_error_temp <= 0;
			temp_en <= 0;
			temp_a <= 0;
			temp_b <= 0; 
		end
	else if(divide_en)
		begin
			if( divisor==0 )
				begin
					divide_error_temp <= 1;
					temp_en <= 0;
					temp_a <= 0;
					temp_b <= 0;
				end
			else 
				begin
					divide_error_temp <= 0;
					temp_en <= 1;
					temp_a <= {dividend>>width,dividend};//{32'h00000000,dividend};  
    				temp_b <= {divisor,divisor>>width};  
    			end
		end
	else 
		begin
			divide_error_temp <= 0;
			temp_en <= 0;
			temp_a <= 0;
			temp_b <= 0; 
		end

	/* shift_compute instance */

	wire [width*2-1:0] a_reg[0:width];
	wire [width*2-1:0] b_reg[0:width];

	assign a_reg[0] = temp_a;
	assign b_reg[0] = temp_b;

	generate
		genvar i;
		for (i = 0; i < width; i = i + 1)
		begin:shift_compute
			shift_compute#(
				 .width(width*2)
			) inst_shift_compute ( 
				.clk(clk),
				.a_i(a_reg[i]),
				.b_i(b_reg[i]),
				.a_o(a_reg[i+1]),
				.b_o(b_reg[i+1]) 
				);
		end
	endgenerate

	/* ouput register */

	reg [width:0] divide_en_shift_reg;
	reg [width-1:0] divide_error_temp_shift_reg;

	reg divide_error;
	reg divide_done;
	reg [width-1:0] quotient;
	reg [width-1:0] remainde;

	always@(posedge clk)
	if(~rst_n)
		begin
			divide_en_shift_reg <= 0;
			divide_error_temp_shift_reg <= 0;

			divide_error <= 0;
			divide_done <= 0;
			quotient <= 0;
			remainde <= 0;
		end
	else 
		begin
			divide_en_shift_reg <= {divide_en_shift_reg[width-1:0],divide_en};
			divide_error_temp_shift_reg <= {divide_error_temp_shift_reg[width-2:0],divide_error_temp};

			divide_error <= divide_error_temp_shift_reg[width-1];
			divide_done <= divide_en_shift_reg[width];
			quotient <= divide_en_shift_reg[width]?a_reg[width][width-1:0]:0;  
			remainde <= divide_en_shift_reg[width]?a_reg[width][width*2-1:width]:0; 
		end

  
endmodule  

/* shift_compute */
module shift_compute#( parameter width=64 )( clk,a_i,b_i,a_o,b_o );
	input clk;
	input [width-1:0] a_i,b_i;
	output reg [width-1:0] a_o,b_o;

	wire [width-1:0] temp_a,temp_b;
	assign temp_a = {a_i[width-2:0],1'b0};
	assign temp_b = b_i;

	always@(posedge clk)
	begin
		if(temp_a[width-1:width/2] >= temp_b[width-1:width/2])  
            a_o <= temp_a - temp_b + 1'b1;  
        else  
            a_o <= temp_a;
        b_o <= temp_b;
	end

endmodule 

