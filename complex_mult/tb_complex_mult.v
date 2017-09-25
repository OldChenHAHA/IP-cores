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

reg [4*N-1:0] i;
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
    ab_valid = 0;
    ar = 0; ai = 0; br = 0; bi = 0;
    real_part_dsp = 0; imag_part_dsp = 0;

    #200;

    // Add stimulus here
    $display("Simulation begin!");

    for(i = 0; i < 5/*2**(4*N)*/; i = i + 1) begin
        @(posedge clk)
        #1 ab_valid = 1;
        ar = i[N-1:0];
        ai = i[2*N-1:N];
        br = i[3*N-1:2*N];
        bi = i[4*N-1:3*N];

        real_part_dsp = ar*br - ai*bi;
        imag_part_dsp = ai*br + ar*bi;

        @(posedge clk)
        #1 ab_valid = 0;
        ar = 0; ai = 0; br = 0; bi = 0;

        @(posedge p_valid)
        if( (pr != real_part_dsp)&&(pi != imag_part_dsp) ) begin
            $display(" Fail - Module output does not equal expected value\n");
            $stop;
        end

    end
    @(posedge clk)
    #1 ab_valid = 0;
    ar = 0; ai = 0; br = 0; bi = 0;

    @(posedge clk)

    $display("All tests are passed!");

    $finish;
end

///////////////////////////////////////////////////////////////////////////////

always #10 clk = ~clk;

///////////////////////////////////////////////////////////////////////////////

endmodule
