
`timescale 1ns / 1ps
// http://www.cnblogs.com/ruowei/p/5891029.html

module Booth_Multiplier #(
    parameter pN = 4                // Width = 2**pN: multiplicand & multiplier
)(
    input wire Rst_n,              // Reset_n
    input wire Clk,                    // Clock

    input wire En,                     // Load Registers and Start Multiplier
    input wire [(2**pN - 1):0] M,      // Multiplicand
    input wire [(2**pN - 1):0] Q,      // Multiplier
    output reg Valid,              // Product Valid
    output reg [(2**(pN+1) - 1):0] Product   // Product <= M * R
);


  wire [(2**pN-1):0] A=0;
  wire Q_assist=0;

  wire [3*2**pN:0] i_temp[(2**pN-1):0];
  wire [3*2**pN:0] o_temp[(2**pN-1):0];

  assign i_temp[0] = {M,Q_assist,A,Q};

  genvar vari;
  generate
      for(vari = 0;vari < 2**pN; vari = vari+1) begin: Booth
          Booth_Shift#(
            .pN(pN)
          )inst_booth(
            .Clk(Clk),
            .Rst_n(Rst_n),
            .i(i_temp[vari]),
            .o(o_temp[vari])
            );
      end

      for(vari = 0;vari < 2**pN-1; vari = vari+1)
        assign i_temp[vari+1] = o_temp[vari];

  endgenerate

  reg [2**pN-1:0] en_shift;

  always @ (posedge Clk)
  if(~Rst_n)begin
    en_shift <= 0;
    Valid <= 0;
    Product <= 0;
  end
  else begin
    en_shift <= {en_shift[2**pN-2:0],En};
    if (en_shift[2**pN-1] == 1'b1)begin
      Valid <= 1;
      Product <= o_temp[2**pN-1][(2**(pN+1) - 1):0];
    end
    else begin
      Valid <= 0;
      Product <= 0;
    end
  end

endmodule


module Booth_Shift #(
    parameter pN = 4                // Width = 2**pN: multiplicand & multiplier
)(
    input wire Rst_n,              // Reset_n
    input wire Clk,                    // Clock
    input wire [3*2**pN:0] i,
    output wire [3*2**pN:0] o
);

  wire [(2**pN - 1):0] M_i;      // Multiplicand
  wire [(2**pN - 1):0] Q_i;      // Multiplier
  wire [(2**pN - 1):0] A_i;
  wire Q_assist_i;
  wire [(2**pN - 1):0] M_o;   // Product <= M * R
  wire [(2**pN - 1):0] Q_o;   // Product <= M * R
  wire [(2**pN - 1):0] A_o;   // Product <= M * R
  wire Q_assist_o;

  assign {M_i,Q_assist_i,A_i,Q_i} = i;


  reg [(2**pN - 1):0] b;
  wire [(2**pN - 1):0] a,out;
  reg cin;

  reg [(2**pN - 1):0] M_temp;
  reg [(2**pN - 1):0] A_temp,Q_temp;
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
