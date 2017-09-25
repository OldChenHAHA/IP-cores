`timescale 1ns / 1ps


module tb_complex_mult;

parameter N = 2;

//  UUT Signals

reg     clk;

reg ab_valid;
reg signed [N-1:0] ar,ai,br,bi;

wire p_valid;
wire signed [N+N:0] pr,pi;
//  Simulation Variables

reg [4*N-1:0] i,j;
reg signed [N-1:0] exp_ar,exp_ai,exp_br,exp_bi;
reg signed [N+N:0] real_part_dsp,imag_part_dsp;

// Instantiate the Unit Under Test (UUT)
complex_mult
#(
	.WIDTH(N),
	.INPUT_BUF("ON"),
	.OUTPUT_BUF("ON")
)UUT(
	.clk(clk),               // Clock
	.ab_valid(ab_valid),
	.ar(ar), .ai(ai), // 1st inputs real and imaginary parts
	.br(br), .bi(bi), // 2nd inputs real and imaginary parts
	.p_valid(p_valid),
	.pr(pr), .pi(pi) // output signal

    );

initial begin
    // Initialize Inputs

    // $dumpfile("dut.vcd");
    // $dumpvars;

    clk = 0;
    i = 0;
    j = 0;
    ab_valid = 0;
    ar = 0; ai = 0; br = 0; bi = 0;

    #200;

    // Add stimulus here
    $display("Simulation begin!");

    for(i = 0; i < 2**(4*N)-1; i = i + 1) begin
        @(posedge clk)
        #1; // !! very important otherwise iverilog simulate goes wrong!
        ab_valid = 1;
        ar = i[N-1:0];
        ai = i[2*N-1:N];
        br = i[3*N-1:2*N];
        bi = i[4*N-1:3*N];
    end
    @(posedge clk)
    ab_valid = 0;
    ar = 0; ai = 0; br = 0; bi = 0;

    @(negedge p_valid)
    #100;

    $display("All tests are passed!");

    $finish;

end

initial begin
	while(1)begin
		@(posedge clk);
		if(p_valid)begin
			exp_ar = j[N-1:0];
	        exp_ai = j[2*N-1:N];
	        exp_br = j[3*N-1:2*N];
	        exp_bi = j[4*N-1:3*N];

	        real_part_dsp = exp_ar*exp_br - exp_ai*exp_bi;
	        imag_part_dsp = exp_ai*exp_br + exp_ar*exp_bi;
	        if( (pr != real_part_dsp)&&(pi != imag_part_dsp) ) begin
	            $display(" Fail - Module output does not equal expected value\n");
	            $display("%d,%d,%d,%d",pr,pi,real_part_dsp,imag_part_dsp);
	            $stop;
	        end

			j = j + 1;
		end
	end
end


///////////////////////////////////////////////////////////////////////////////

always #10 clk = ~clk;

///////////////////////////////////////////////////////////////////////////////

endmodule
