`timescale 1ns/1ps

module chen_fifo(

	clk,
	rst,

	data_en_i,
	data_i,

	data_en_o,
	data_o

	);

	parameter DATA_WIDTH = 8;
	parameter FRAME_LENGTH = 255;
	parameter RAM_ADDR_WIDTH = 8;

	input clk;
	input rst;

	input data_en_i;
	input [DATA_WIDTH-1:0] data_i;

	output data_en_o;
	output [DATA_WIDTH-1:0] data_o;


/********************************write**********************************************/
	

	reg [RAM_ADDR_WIDTH:0] cnt_i;
	reg write_en;
	reg [RAM_ADDR_WIDTH-1:0] address_i;
	reg [DATA_WIDTH-1:0] ramdatain;

	reg read_flag;
	
	always@(posedge clk)
	if(!rst)
		begin
			cnt_i <= 0;
			address_i <= 0;
			write_en <= 0;
			ramdatain <= 0;
			read_flag <= 0;
		end
	else 
		begin
			if(data_en_i)
				begin
					cnt_i <= (cnt_i==FRAME_LENGTH-1)?0:cnt_i+1'b1;
					read_flag <= (cnt_i==FRAME_LENGTH-1)?1:0;
					address_i <= cnt_i;
					write_en <= 1;
					ramdatain <= data_i;
				end
			else 
				begin
					address_i <= 0;
					write_en <= 0;
					ramdatain <= 0;
					read_flag <= 0;
				end
		end
/***************************read***************************************************/
	
	reg read_en;
	reg [RAM_ADDR_WIDTH-1:0] addressA_o,addressB_o;
	reg even;
	wire [RAM_ADDR_WIDTH-1:0] address_o;

	always@(posedge clk)
	if(!rst)
		begin
			addressA_o <= 0;
			addressB_o <= 0;
			read_en <= 0;
			even <= 0;

		end
	else 
		begin
			if(read_flag) 	even <= ~even;


			if(read_flag)
				begin
					read_en <= 1;
				end
			else if(read_en)
				begin
					if(even)
						begin
							addressA_o <= (addressA_o==FRAME_LENGTH-1)?0:addressA_o+1'b1;
							addressB_o <= 0;
							read_en <= (addressA_o==FRAME_LENGTH-1)?0:1;
						end
					else 
						begin
							addressB_o <= (addressB_o==FRAME_LENGTH-1)?0:addressB_o+1'b1;
							addressA_o <= 0;
							read_en <= (addressB_o==FRAME_LENGTH-1)?0:1;
						end

				end
			else 
				begin
					addressA_o <= 0;
					addressB_o <= 0;
					read_en <= 0;
				end

		end

		assign address_o = (even)?addressA_o:addressB_o;

/***********************************************************************************/
	

	wire wea;
	wire [DATA_WIDTH-1:0] dina;
	wire [RAM_ADDR_WIDTH-1:0] addra,addrb;
	wire addrenb;

	assign wea = write_en;
	assign addra = address_i;
	assign dina = ramdatain;

	assign addrenb= read_en;
	assign addrb = address_o;
	
	wire doutenb;
	wire [DATA_WIDTH-1:0] doutb;

	xilinx_simple_dual_port_1_clock_ram #(
	  .RAM_WIDTH(DATA_WIDTH),                       // Specify RAM data width
	  .RAM_DEPTH(FRAME_LENGTH),                      // Specify RAM depth (number of entries)
	  .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
	  .RAM_TYPE("distributed"),// rom_type: distributed or block
	  .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
	) inst_rs_ram (
	  .addra(addra), // Write address bus, width determined from RAM_DEPTH
	  .addrenb(addrenb),
	  .addrb(addrb), // Read address bus, width determined from RAM_DEPTH
	  .dina(dina),          // RAM input data
	  .clka(clk),                          // Clock
	  .wea(wea),                           // Write enable
	  .enb(1'b1),                           // Read Enable, for additional power savings, disable when not in use
	  .rstb(~rst),                          // Output reset (does not affect memory contents)
	  .doutenb(doutenb),                      
	  .doutb(doutb)         // RAM output data
	);

/* output */

	reg data_en_o;
	reg [DATA_WIDTH-1:0] data_o;

	always@(posedge clk)
	if(~rst)
		begin
			data_en_o <= 0;
			data_o <= 0;
		end
	else if(doutenb)
		begin
			data_en_o <= 1;
			data_o <= doutb;
		end
	else 
		begin
			data_en_o <= 0;
			data_o <= 0;
		end



/*************************************************************************************/

endmodule
