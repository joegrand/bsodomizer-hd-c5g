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
   input wire [B+FRACTIONAL_BITS-1:0] ramp_step); 
 
 
//=======================================================
//  Constant declarations
//=======================================================

parameter	INTRAM_DATA_WIDTH	=	8;			//	8 bits/word
//parameter	INTRAM_DATA_NUM	=	259200;	// 1920 * 1080 / 8	
parameter	INTRAM_ADDR_WIDTH	=	18;		//	18	address lines


 //=======================================================
//  Registers
//=======================================================

// PRNG 
reg load_init_pattern;
reg next_pattern;

// Pattern generator
reg [B+FRACTIONAL_BITS-1:0] ramp_values; // 12-bit fractional end for ramp values 

// Internal RAM
reg [INTRAM_ADDR_WIDTH-1:0]  intram_address;
reg [INTRAM_DATA_WIDTH-1:0]  intram_data_in;
reg intram_wren;

	
//=======================================================
//  Wires
//=======================================================

wire [31:0] prng_data; 	// PRNG output
wire [INTRAM_DATA_WIDTH-1:0] intram_q; // Internal RAM data output


//=======================================================
//  Assignments
//=======================================================


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
int_ram	int_ram_inst (
	.address (intram_address),
	.clock (clk_in),
	.data (intram_data_in),
	.wren (intram_wren),
	.q (intram_q)
);

 
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
  else if (pattern == 8'b0) // no pattern 
    begin 
      r_out <= r_in; 
      g_out <= g_in; 
      b_out <= b_in; 
    end 
  else if (pattern == 8'b1) // border 
    begin 
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
  else if (pattern == 8'd2) // moireX 
  begin 
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
  else if (pattern == 8'd3) // moireY 
  begin 
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
  else if (pattern == 8'd4) // Simple RAMP 
  begin 
       r_out <= ramp_values[B+FRACTIONAL_BITS-1:FRACTIONAL_BITS]; 
       g_out <= ramp_values[B+FRACTIONAL_BITS-1:FRACTIONAL_BITS]; 
       b_out <= ramp_values[B+FRACTIONAL_BITS-1:FRACTIONAL_BITS]; 
       if ((x == total_active_pix -  1) && (dn_in)) 
         ramp_values <= 0; 
       else if ((x == 0) && (dn_in)) 
         ramp_values <= ramp_step; 
       else if (dn_in) 
         ramp_values <= ramp_values + ramp_step; 
   end
   else if (pattern == 8'd5) // PRNG 
   begin 	
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
	else if (pattern == 8'd6) // tesselated rainbow pattern
	begin
		r_out <= x;
		g_out <= y;
		b_out <= x + y;
	end
	else if (pattern == 8'd7) // image (1920 x 1080, packed 1bpp)
	begin
		if (intram_q & (8'h80 >> ((x-1) % 8))) // unpack 1bpp image using a bitmask (x = current pixel on horizontal line)
		begin
			r_out <= 8'hC0; 	// silver/white (BSOD, text)
			g_out <= 8'hC0; 
			b_out <= 8'hC0; 
		end
		else
		begin
			/*r_out <= 8'h0; 	// navy blue (BSOD, up through Windows 7)
			g_out <= 8'h0; 
			b_out <= 8'h80;*/
			
			r_out <= 8'h11; 	// cerulean blue (BSOD, Windows 8 and beyond)
			g_out <= 8'h71; 
			b_out <= 8'hab;
		end
	end
 end 
 
 
////////////	SRAM ADDR Generator	  ////////////
always @ (negedge clk_in)
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
end


endmodule