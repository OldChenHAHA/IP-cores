/**************************************
* Module: chen_cordic
* Date:2016-04-15  
* Author: Chen Zhongyao     
*
* Description:  compute cordic
* 
*  cordic gain : K = 0.6072529   
*  by controling the parameters below, you can change this module function;
* 
*  ROTATE_TYPE = ROTATE OR VECTOR

*  ROTATE mode : 
*       input ports  : Validin,Xin,Yin,Ain
*       output ports : Validout,Xout,Yout     leave the port Aout.
*  VECTOR mode : 
*       input ports  : Validin,Xin,Yin
*       output ports : Validout,Xout,Aout     leave the port Ain,Yout.
* 
* if you want to compute the sin or cos, give the input ports {Xin=1,Yin=0} and the angle, ouput ports Xout means the cos, Yout means the sin.
* 
*   input/output ports range 
*       Ain : -pi ~ +pi     fix18_15  one sign bit, two integer bits, and 15 fractional bits.
*       Xin : -1  ~ +1      fix17_15  one sign bit, one integer bit , and 15 fractional bits.
*       Yin : -1  ~ +1
* 
***************************************/



module  chen_cordic #(
    
    parameter ROTATE_TYPE = "ROTATE",  // ROTATE_TYPE = ROTATE OR VECTOR
    parameter DATABITS = 17,  // fix17_15    a sign bit, a interger bit and the fractional bits.
    parameter ITERATIONS = 16  // iterate times    max value : 16

    )(

    input clk,
    input rst_n,
    
    input Validin,
    input signed [DATABITS-1:0] Xin,
    input signed [DATABITS-1:0] Yin,  
    input signed [17:0] Ain,
    
    output reg Validout,
    output reg signed [DATABITS-1:0] Xout,
    output reg signed [DATABITS-1:0] Yout,
    output reg signed [17:0] Aout
    
    );
    
/*****************************************************/
    
    localparam pi = 18'sd102943; //18'sd102943.7 
    localparam half_pi = 18'sd51471;  // 18'sd51471.8 fix18_15
    localparam K = 16'sb0100110110111010;// 0.6072529
    
 /***************************************************/
 
 /* Quadrant adjustment */
    reg signed [DATABITS-1:0] xtemp,ytemp;
    reg signed [17:0] atemp;
    
generate
if (ROTATE_TYPE == "ROTATE") begin: Rotating
    
    always@(posedge clk)
    if(!rst_n)
        {xtemp,ytemp,atemp} <= 0;
    else if( Ain <= half_pi && Ain >= -half_pi)     
        begin
            xtemp <= Xin;
            ytemp <= Yin;
            atemp <= Ain;
        end
    else if( Ain > half_pi )
        begin
            xtemp <= -Xin;
            ytemp <= -Yin;
            atemp <= Ain - pi;
        end
    else if( Ain < -half_pi )
        begin
            xtemp <= -Xin;
            ytemp <= -Yin;
            atemp <= Ain + pi;
        end
       
end else if(ROTATE_TYPE == "VECTOR") begin : Vectoring
    
    always@(posedge clk)
    if(!rst_n)
        {xtemp,ytemp,atemp} <= 0;
    else if(Xin>=0)
        begin
            xtemp <= Xin;
            ytemp <= Yin;
            atemp <= 0;
        end
    else if( Xin < 0 && Yin >= 0 )   
        begin 
            xtemp <= -Xin;
            ytemp <= -Yin;
            atemp <= +pi;
        end
    else if( Xin < 0 && Yin < 0 )
        begin 
            xtemp <= -Xin;
            ytemp <= -Yin;
            atemp <= -pi;
        end

end
endgenerate

/* iterate instances */

    wire [DATABITS-1:0] x[ITERATIONS:0];
    wire [DATABITS-1:0] y[ITERATIONS:0];
    wire [17:0] a[ITERATIONS:0];
    
    assign { x[0],y[0],a[0] } = {xtemp,ytemp,atemp};

    genvar i;
    generate for(i=0;i<=ITERATIONS-1;i=i+1) begin
      rotator inst_rotator (clk,rst_n,x[i],y[i],a[i],x[i+1],y[i+1],a[i+1]);
      defparam inst_rotator.ROTATE_TYPE = ROTATE_TYPE;
      defparam inst_rotator.ITERATE_INDEX = i;
      defparam inst_rotator.DATABITS = DATABITS;
      defparam inst_rotator.angle = angle(i);
    end 
    endgenerate
    
    
    reg [ITERATIONS:0] valid_temp;
    always@(posedge clk)
    if(~rst_n)
        valid_temp <= 0;
    else 
        valid_temp <= {valid_temp[ITERATIONS-1:0],Validin};
        
 
 /* multipe K and output reg */
    
    reg Validout_reg;
    reg signed [DATABITS+16-1:0] Xout_reg,Yout_reg;
    reg signed [17:0] Aout_reg;

    always@(posedge clk)
    if(!rst_n)
        begin
            { Validout_reg,Xout_reg,Yout_reg,Aout_reg } <= 0;
            { Validout,Xout,Yout,Aout } <= 0;
        end
    else 
        begin
            Validout_reg <= valid_temp[ITERATIONS];
            Xout_reg <= K*$signed(x[ITERATIONS]);
            Yout_reg <= K*$signed(y[ITERATIONS]);
            Aout_reg <= a[ITERATIONS];
            
            if(Validout_reg)
                begin
                    Validout <= Validout_reg;
                    Xout <= Xout_reg[DATABITS+14:15];
                    Yout <= Yout_reg[DATABITS+14:15];
                    Aout <= Aout_reg;
                end
            else 
                { Validout,Xout,Yout,Aout } <= 0;
        end
   
    
/* ***********************
 * Table:       angle in tan form  
 * data type:   fix17_15
 * exmple:      45degree means that angle = 45*360/2pi
 ************************/

function signed [18:0] angle;  // fix18_15
  input [3:0] i;
  begin
    case (i)
    4'b0000: angle = 18'd25736 ;   //  1/1  45*360/2pi
    4'b0001: angle = 18'd15192;    //  1/2
    4'b0010: angle = 18'd8027;     //  1/4
    4'b0011: angle = 18'd4075;     //  1/8
    4'b0100: angle = 18'd2045;     //  1/16
    4'b0101: angle = 18'd1024;     //  1/32
    4'b0110: angle = 18'd512;      //  1/64
    4'b0111: angle = 18'd256;      //  1/128
    4'b1000: angle = 18'd128;      //  1/256
    4'b1001: angle = 18'd64;       //  1/512
    4'b1010: angle = 18'd32;       //  1/1024
    4'b1011: angle = 18'd16;       //  1/2048
    4'b1100: angle = 18'd8;        //  1/4096
    4'b1101: angle = 18'd4;        //  1/8192
    4'b1110: angle = 18'd2;        //  1/16k
    4'b1111: angle = 18'd1;        //  1/32k
    endcase
  end
endfunction

endmodule

/* simple rotate module */

module rotator(clk,rst_n,xin,yin,ain,xout,yout,aout);
    
    parameter ROTATE_TYPE = "ROTATE";  // ROTATE_TYPE = ROTATE OR VECTOR
    parameter ITERATE_INDEX = 0;
    parameter DATABITS = 17;
    parameter signed [17:0] angle=0;

    input clk;
    input rst_n;
    
    input signed [DATABITS-1:0] xin,yin;
    input signed [17:0] ain;
    
    output reg signed [DATABITS-1:0] xout,yout;
    output reg signed [17:0] aout;
    
    
generate
    if (ROTATE_TYPE == "ROTATE") begin: Rotating
    
    always@(posedge clk)
    if(!rst_n)
        {xout,yout,aout} <= 0;
/*  *********************************************************
 * Here I comment because if the cordic stop iterating before 16times, the angle result is perfect, 
 * but the scaling of the x,y value isn't the cordic gain K which is 0.6072529;
 * It has to iterate enough to get to the K gain before entering the multipler.
 * However if you only want the angle, dont care the x,y, you can remove multipler and uncomment below.
 *************************************************************/
//    else if(ain==0)                                   
//        {xout,yout,aout} <= {xin,yin,ain};
    else if(ain < 0)
        begin       
            xout <= xin + (yin>>>ITERATE_INDEX);
            yout <= yin - (xin>>>ITERATE_INDEX);
            aout <= ain + angle;
        end
    else 
        begin
            xout <= xin - (yin>>>ITERATE_INDEX);
            yout <= yin + (xin>>>ITERATE_INDEX);
            aout <= ain - angle;
        end
        
    end else if(ROTATE_TYPE == "VECTOR") begin : Vectoring
    
    always@(posedge clk)
    if(!rst_n)
        {xout,yout,aout} <= 0;
/* here comment for the same reason above */
//    else if(yin==0)
//        {xout,yout,aout} <= {xin,yin,ain};
    else if(yin > 0)
        begin       
            xout <= xin + (yin>>>ITERATE_INDEX);
            yout <= yin - (xin>>>ITERATE_INDEX);
            aout <= ain + angle;
        end
    else 
        begin
            xout <= xin - (yin>>>ITERATE_INDEX);
            yout <= yin + (xin>>>ITERATE_INDEX);
            aout <= ain - angle;
        end

end
endgenerate

endmodule


