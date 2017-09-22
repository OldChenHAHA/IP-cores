
`define tb_iverilog

module tb_Booth_Multiplier;

parameter N = 2;

//  UUT Signals

reg     Rst;
reg     Clk;

reg     Ld;
reg     [(2**N - 1):0] M;
reg     [(2**N - 1):0] R;

wire    Valid;
wire    [(2**(N+1) - 1):0] P;

//  Simulation Variables

reg     [2**(N+1):0] i;

// Instantiate the Unit Under Test (UUT)
/*
Booth_Multiplier    #(
                        .pN(N)
                    ) uut (
                        .Rst(Rst),
                        .Clk(Clk),
                        .Ld(Ld),
                        .M(M),
                        .R(R),
                        .Valid(Valid),
                        .P(P)
                    );
*/
                    Booth_Multiplier #(
                        .pN(N)                // Width = 2**pN: multiplicand & multiplier
                    )chen_dut(
                      .Rst_n(~Rst),
                      .Clk(Clk),
                      .En(Ld),
                      .M(M),
                      .Q(R),
                      .Valid(Valid),
                      .Product(P)

                    );

`ifdef tb_iverilog

initial
begin
    $dumpfile("dut.vcd");
    $dumpvars;
end

`endif

initial begin
    // Initialize Inputs
    Rst = 1;
    Clk = 1;
    Ld  = 0;
    M   = 0;
    R   = 0;

    i   = 0;

    // Wait 100 ns for global reset to finish
    #101 Rst = 0;

    // Add stimulus here
    /*
    for(i = 0; i < (2**(2**(N+1))); i = i + 1) begin
        @(posedge Clk) #1 Ld = 1;
            M = i[(2**(N+1) - 1):2**N];
            R = i[(2**N - 1):0];
        @(posedge Clk) #1 Ld = 0;
        @(posedge Valid);
    end
    */
    @(posedge Clk) #1 Ld = 1; M = 4'b0110; R = 4'b0101;
    @(posedge Clk) #1 Ld = 0; M=0; R=0;
    @(posedge Valid);

    @(posedge Clk);
    @(posedge Clk);

    $finish;
end

///////////////////////////////////////////////////////////////////////////////

always #5 Clk = ~Clk;

///////////////////////////////////////////////////////////////////////////////

endmodule
