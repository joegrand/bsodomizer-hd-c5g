`timescale 1ns / 1ps

module pattern_vg 
  #( 
    parameter B=8, // number of bits per channel 
              X_BITS=13, 
              Y_BITS=13, 
              FRACTIONAL_BITS = 12 
  ) 
  (input reset, clk_in,  
   input wire [X_BITS-1:0] x, 
   input wire [Y_BITS-1:0] y, 
   input wire vn_in, hn_in, dn_in, 
   input wire [B-1:0] r_in, g_in, b_in, 
   output reg vn_out, hn_out, den_out, 
   output reg [B-1:0] r_out, g_out, b_out, 
   input wire [X_BITS-1:0] total_active_pix, 
   input wire [Y_BITS-1:0] total_active_lines, 
   input wire [7:0] pattern, 
   input wire [B+FRACTIONAL_BITS-1:0] ramp_step,
	input wire [2:0] dip_sw,
	
	input  wire 		  avl_clk,					//	   LPDDR2 (read only)
	input  wire			  local_init_done,	  
	input  wire         avl_waitrequest_n, 	// 	avl.waitrequest_n
	output reg  [26:0]  avl_address,       	//       .address
	input  wire         avl_readdatavalid, 	//       .readdatavalid
	input  wire [31:0]  avl_readdata,      	//       .readdata
	output reg          avl_read,          	//       .read
	output wire			  avl_burstbegin			//			.burstbegin
	);
	
//=======================================================
//  Constant declarations
//=======================================================

//parameter	INTRAM_DATA_WIDTH	=	8;			//	8 bits/word
//parameter	INTRAM_DATA_NUM	=	259200;	// 1920 * 1080 / 8	
//parameter	INTRAM_ADDR_WIDTH	=	18;		//	18	address lines


 //=======================================================
//  Registers
//=======================================================

// State machine
reg  [3:0]   c_state;

// PRNG 
reg load_init_pattern;
reg next_pattern;

// Pattern generator
reg [B+FRACTIONAL_BITS-1:0] ramp_values; // 12-bit fractional end for ramp values 

// Internal RAM
/*reg [INTRAM_ADDR_WIDTH-1:0]  intram_address;
reg [INTRAM_DATA_WIDTH-1:0]  intram_data_in;
reg intram_wren;*/

// LPDDR2
reg [31:0]   avl_q; 		// data read from memory
reg  [4:0]   write_count;


//=======================================================
//  Wires
//=======================================================

wire [31:0] prng_data; 	// PRNG output
//wire [INTRAM_DATA_WIDTH-1:0] intram_q; // Internal RAM data output


//=======================================================
//  Assignments
//=======================================================

assign avl_burstbegin = avl_read;


//=======================================================
//  Core instantiations
//=======================================================

// Cellular automata PRNG
ca_prng prng (
   .clk(clk_in),
   .reset_n(!reset),
	.init_pattern_data(32'b01011000000000010000111000001100),  // COMPLEX_INIT_PATTERN
	.load_init_pattern(load_init_pattern),
   .next_pattern(next_pattern),
   .prng_data(prng_data)
);

// Internal RAM (1-port)
/*int_ram	int_ram_inst (
	.address (intram_address),
	.clock (clk_in),
	.data (intram_data_in),
	.wren (intram_wren),
	.q (intram_q)
);*/

 
//=======================================================
//  Structural coding
//=======================================================

always @ (posedge clk_in) 
begin 
  vn_out <= vn_in; 
  hn_out <= hn_in; 
  den_out <= dn_in; 
 
  if (reset) 
     ramp_values <= 0; 
  else
    case (dip_sw)
	 3'b000 : begin	// No pattern (black screen)
		r_out <= r_in; 
		g_out <= g_in; 
		b_out <= b_in; 
	 end
	 3'b001 : begin	// border (thin white line around edge of frame)
		if ((dn_in) && ((y == 12'b0) || (x == 12'b0) || (x == total_active_pix - 1) || (y == total_active_lines -  1))) 
      begin 
			r_out <= 8'hFF; 
			g_out <= 8'hFF; 
			b_out <= 8'hFF; 
      end 
      else 
      begin 
			r_out <= r_in; 
			g_out <= g_in; 
			b_out <= b_in; 
      end 	 
	 end
	 3'b010 : begin	// moire vertical
		if ((dn_in) && x[0] == 1'b1) 
		begin 
			r_out <= 8'hFF; 
			g_out <= 8'hFF; 
			b_out <= 8'hFF; 
		end 
		else 
		begin 
			r_out <= 8'b0; 
			g_out <= 8'b0; 
			b_out <= 8'b0; 
		end	 
	 end
	 3'b011 : begin	// moire horizontal
		if ((dn_in) && y[0] == 1'b1) 
		begin 
			r_out <= 8'hFF; 
			g_out <= 8'hFF; 
			b_out <= 8'hFF; 
		end 
		else 
		begin 
			r_out <= 8'b0; 
			g_out <= 8'b0; 
			b_out <= 8'b0; 
		end 	 
	 end
	 3'b100 : begin	// simple ramp (vertical greyscale shading, black to white)
		r_out <= ramp_values[B+FRACTIONAL_BITS-1:FRACTIONAL_BITS]; 
		g_out <= ramp_values[B+FRACTIONAL_BITS-1:FRACTIONAL_BITS]; 
		b_out <= ramp_values[B+FRACTIONAL_BITS-1:FRACTIONAL_BITS]; 
       
		if ((x == total_active_pix - 1) && (dn_in)) 
			ramp_values <= 0; 
		else if ((x == 0) && (dn_in)) 
			ramp_values <= ramp_step; 
		else if (dn_in) 
			ramp_values <= ramp_values + ramp_step;	 
	 end
	 3'b101 : begin	// PRNG (static)
		if (prng_data == 'h0)   // on first run, we need to load the initialization pattern
			load_init_pattern <= 1'b1;
		else
		begin
			load_init_pattern <= 1'b0;	// on subsequent runs, get the next pattern	
			next_pattern      <= 1'b1;
		end
		if (prng_data > 'h23456789)   // set threshold for selecting black or white pixels
		begin
			r_out <= 8'h0; // black
			g_out <= 8'h0; 
			b_out <= 8'h0;  
		end
		else
		begin
			r_out <= 8'hFF; // white
			g_out <= 8'hFF; 
			b_out <= 8'hFF; 
		end	 
	 end
	 3'b110 : begin	// tesselated rainbow pattern
		r_out <= x;
		g_out <= y;
		b_out <= x + y;	 
	 end
	 3'b111 : begin	// image (1920 x 1080, 8bpp)
		r_out <= avl_q[23:16];
		g_out <= avl_q[15:8];
		b_out <= avl_q[7:0];	 
	 end
	 /*3'b111 : begin	// image (1920 x 1080, 1bpp packed)
		if (intram_q & (8'h80 >> ((x-1) % 8))) // unpack image using a bitmask (x = current pixel on horizontal line)
		begin
			r_out <= 8'hC0; 	// silver/white (BSOD, text)
			g_out <= 8'hC0; 
			b_out <= 8'hC0; 
		end
		else
		begin
			//r_out <= 8'h0; 	// navy blue (BSOD, up through Windows 7)
			//g_out <= 8'h0; 
			//b_out <= 8'h80;
			
			r_out <= 8'h11; 	// cerulean blue (BSOD, Windows 8 and beyond)
			g_out <= 8'h71; 
			b_out <= 8'hab;
		end
	end*/
	endcase
 end 
 
 
 
////////////	LPDDR2 ADDR Generator	////////////

always @ (posedge avl_clk)
begin	 
   if(reset)
   begin
		avl_read <= 1'b0;
		avl_address <= 0;
		c_state <= 4'b0;
		write_count <= 5'b0;
   end
	else
	begin
		case (c_state)
		0 : begin // set memory address
			if (local_init_done)
			begin
				if (avl_address == ('d1920 * 'd1080))
					avl_address <= 0;
			
				c_state <= 1;
			end
		end
		1 : begin // assert read
			avl_read <= 1;

			if (!write_count[3])
	  			write_count <= write_count + 1'b1;
				
			// if read is done, go to the next state
			if (avl_waitrequest_n)
				c_state <= 2;
		end
		2 : begin // latch read data
	  		avl_read <= 0;
			
			if (!write_count[3])
	  			write_count <= write_count + 5'b1;
				
			if (avl_readdatavalid)
			begin
	  			avl_q <= avl_readdata;
				avl_address <= avl_address+1;
				c_state <= 0;
			end
	   end
		default : c_state <= 0;
	   endcase
	end
end	  
		
////////////	SRAM ADDR Generator	  ////////////
/*always @ (negedge clk_in)
begin	 
	if(reset)
	begin
	  intram_address <= 0;
	end
	else
	begin
	  if (x % 8 == 7)  // increment the memory every 8 clocks, since we need to unpack the 1bpp structure
	  begin
	    if (x < 'd1920)
		   intram_address <= intram_address+1;
	    else
		   if (y < 'd1080)
				intram_address <= (y * 'd240); // 240 bytes per line for packed 1bpp structure
			else
				intram_address <= 0;
	  end
	end
end*/


endmodule