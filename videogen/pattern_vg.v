`timescale 1ns / 1ps

module pattern_vg (
   input reset, clk_in,  
   input wire [X_BITS-1:0] x, 
   input wire [Y_BITS-1:0] y, 
   input wire vn_in, hn_in, dn_in, 
   input wire [B-1:0] r_in, g_in, b_in, 
   output reg vn_out, hn_out, den_out, 
   output reg [B-1:0] r_out, g_out, b_out, 
   input wire [X_BITS-1:0] total_active_pix, 
   input wire [Y_BITS-1:0] total_active_lines, 
   input wire [B+FRACTIONAL_BITS-1:0] ramp_step,
	input wire [2:0] dip_sw,
	
	input  wire 		  avl_clk,					//	   LPDDR2 (read only)
	input  wire			  local_init_done,	  
	input  wire         avl_waitrequest_n, 	// 	avl.waitrequest_n
	output reg  [26:0]  avl_address,       	//       .address
	input  wire         avl_readdatavalid, 	//       .readdatavalid
	input  wire [31:0]  avl_readdata,      	//       .readdata
	output reg          avl_read,          	//       .read
	output reg			  avl_burstbegin,			//			.burstbegin
	output reg  [7:0]   avl_burstcount
	);
	
//=======================================================
//  Constant declarations
//=======================================================
parameter B = 8;
parameter X_BITS = 13;
parameter Y_BITS = 13;
parameter FRACTIONAL_BITS = 12;

parameter	INTRAM_DATA_WIDTH	=	8;			//	8 bits/word
parameter	INTRAM_ADDR_WIDTH	=	18;		//	18	address lines


 //=======================================================
//  Registers
//=======================================================

// State machine
reg  [3:0]   read_state;

// PRNG 
reg load_init_pattern;
reg next_pattern;

// Pattern generator
reg [B+FRACTIONAL_BITS-1:0] ramp_values; // 12-bit fractional end for ramp values 

// Internal RAM
reg [INTRAM_ADDR_WIDTH-1:0]  intram_address;
reg [INTRAM_DATA_WIDTH-1:0]  intram_data_in;

// LPDDR2
reg [1:0] vsync;
reg [1:0] hsync;
		
// FIFO
reg [31:0] fifo_data; 	// data written into fifo
wire [31:0] fifo_q; 		// data read from fifo
reg fifo_clr;				// asynchronous clear

reg [6:0] dat_count;
reg [15:0] burst_count;


//=======================================================
//  Wires
//=======================================================

wire [31:0] prng_data; 	// PRNG output
wire [INTRAM_DATA_WIDTH-1:0] intram_q; // Internal RAM data output
wire [10:0] fifo_used;

wire rdreq;
wire wrreq;


//=======================================================
//  Assignments
//=======================================================

assign rdreq = dn_in & !reset;
assign wrreq = avl_readdatavalid & (read_state == 4'h3) & !reset;


//=======================================================
//  Core instantiations
//=======================================================
/* rdreq is a syncronous signal.
 * The FIFO is in show-ahead mode, rdreq is an ACK signal in this case
 * In order to prevent extra data read from the FIFO, rdreq is tied
 * directly to the DE signal coming in, and not reset
 */
fifo fifo_inst (
	.sclr (fifo_clr),
	.clock (clk_in),
	.data (fifo_data),
	.rdreq (rdreq),
	.wrreq (wrreq),
	.q (fifo_q),
	.empty (),
	.full (),
	.usedw (fifo_used)
	);
	
	
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
	.wren (),
	.q (intram_q)
);*/

 
//=======================================================
//  Structural coding
//=======================================================

/* Its debatable practice to use "always@() begin" rather than not using begin
 * and only using the "if(reset) ... else ... end" structure since it does not
 * inherently prevent people from adding code that can take place outside of
 * the reset/un-reset code paths which results in sequential logic that ALWAYS
 * gets run.
 *
 * Reset should also be in sensitivity list along with clock. Best practice is
 * is asynchronous reset, synchronous un-reset.  Adding reset to the
 * sensitivity list ensures peripherals receive an async reset.
 */
always @ (posedge clk_in or posedge reset) begin 
  if (reset) begin
    /* There should always be a reset state defined for each signal that is
     * modified in the unreset state of the sequential logic block.
	  * Otherwise a latch is inferred and is costly in space.
     */
    ramp_values <= 0; 
    vn_out <= 1'b0;
    hn_out <= 1'b0;
    den_out <= 1'b0;
    r_out <= 8'h00;
    g_out <= 8'h00;
    b_out <= 8'h00;
	 ramp_values <= 0;
    load_init_pattern <= 1'b0;
    next_pattern <= 1'b0;
  end else begin
    vn_out <= vn_in; 
    hn_out <= hn_in; 
    den_out <= dn_in;
    
    case (dip_sw)
    3'b000 : begin	// border (thin white line around edge of frame)
		if ((dn_in) && ((y == 12'b0) || (x == 12'b0) || (x == total_active_pix - 1) || (y == total_active_lines -  1))) begin 
			r_out <= 8'hFF; 
			g_out <= 8'hFF; 
			b_out <= 8'hFF; 
		end else begin
			r_out <= 8'h00; 
			g_out <= 8'h00; 
			b_out <= 8'h00;
		end
    end
    3'b001 : begin	// PRNG (static)
		if (prng_data == 8'h00)   // on first run, we need to load the initialization pattern
		  load_init_pattern <= 1'b1;
		else begin
		  load_init_pattern <= 1'b0;	// on subsequent runs, get the next pattern	
		  next_pattern      <= 1'b1;
		end
		if (prng_data > 'h23456789) begin  // set threshold for selecting black or white pixels
		  r_out <= 8'h00; // black
		  g_out <= 8'h00; 
		  b_out <= 8'h00;  
		end else begin
		  r_out <= 8'hFF; // white
		  g_out <= 8'hFF; 
		  b_out <= 8'hFF; 
		end	 
    end	  
    3'b010 : begin	// moire vertical (alternate black and white pixels every other x)
      if ((dn_in) && x[0] == 1'b1) begin 
        r_out <= 8'hFF; 
        g_out <= 8'hFF; 
        b_out <= 8'hFF; 
      end else begin
        r_out <= 8'h00; 
        g_out <= 8'h00; 
        b_out <= 8'h00; 
     end	 
    end
    3'b011 : begin	// moire horizontal (alternate black and white pixels every other y)
      if ((dn_in) && y[0] == 1'b1) begin 
        r_out <= 8'hFF; 
        g_out <= 8'hFF; 
        b_out <= 8'hFF; 
      end else begin 
        r_out <= 8'h00; 
        g_out <= 8'h00; 
        b_out <= 8'h00; 
      end 	 
    end
    3'b100 : begin	// ramp (full screen width, vertical greyscale gradient)
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
    /*3'b101 : begin	// tesselated rainbow pattern
			r_out <= x;
			g_out <= y;
			b_out <= x + y;	 
    end*/
	 3'b101 : begin // color bar pattern
	   if (dn_in) begin
			if (x <= 275) begin // 100% white
			  r_out <= 8'hFF; 
			  g_out <= 8'hFF; 
			  b_out <= 8'hFF; 
			end 
			else if (x >= 276 && x <= 549) begin // yellow
			  r_out <= 8'hFF; 
			  g_out <= 8'hFF; 
			  b_out <= 8'h00; 
			end	  
			else if (x >= 550 && x <= 823) begin // cyan
			  r_out <= 8'h00; 
			  g_out <= 8'hFF; 
			  b_out <= 8'hFF; 
			end 		
			else if (x >= 824 && x <= 1097) begin // green
			  r_out <= 8'h00; 
			  g_out <= 8'hFF; 
			  b_out <= 8'h00; 
			end 		
			else if (x >= 1098 && x <= 1371) begin // magenta
			  r_out <= 8'hFF; 
			  g_out <= 8'h00; 
			  b_out <= 8'hFF; 
			end 		
			else if (x >= 1372 && x <= 1645) begin // red
			  r_out <= 8'hFF; 
			  g_out <= 8'h00; 
			  b_out <= 8'h00; 
			end 		
			else if (x >= 1646 && x <= 1919) begin // blue
			  r_out <= 8'h00; 
			  g_out <= 8'h00; 
			  b_out <= 8'hFF; 
			end 
			else begin // black
			  r_out <= 8'h00; 
			  g_out <= 8'h00; 
			  b_out <= 8'h00; 
			end
		end
	 end
	 /*3'b110 : begin	// image (1920 x 1080, 1bpp packed, from internal BRAM)
	   if (dn_in) begin
			if (intram_q & (8'h80 >> ((x-1) % 8))) begin  // unpack image using a bitmask (x = current pixel on horizontal line)
			  r_out <= 8'hC0; 	// silver/white (BSOD, text)
			  g_out <= 8'hC0; 
			  b_out <= 8'hC0; 
			end else begin
			  //r_out <= 8'h0; 	// navy blue (BSOD, up through Windows 7)
			  //g_out <= 8'h0; 
			  //b_out <= 8'h80;
			  r_out <= 8'h11; 	// cerulean blue (BSOD, Windows 8 and beyond)
			  g_out <= 8'h71; 
			  b_out <= 8'hab;
			end
		end
	 end*/		 
    3'b111 : begin	// image (1920 x 1080, 8bpp)		
		 // dn_in is DE, this is high when actual frame data is needed
		 if (dn_in) begin
			r_out <= fifo_q[23:16]; // get data from fifo and push to HDMI
			g_out <= fifo_q[15:8];
			b_out <= fifo_q[7:0];
		 end
	 end	 
	 endcase
  end
end 
  
  
 
////////////	LPDDR2 	////////////

always @ (posedge avl_clk or posedge reset)
begin	 
  if(reset) begin 
	 vsync <= 2'b00;
	 hsync <= 2'b00;
	 read_state <= 4'h0;
	 avl_burstcount <= 8'd128;  //128 is the max, even though count is 8bit
	 dat_count <= 7'h0;
	 burst_count <= 16'h0;
  end else begin
  	 avl_burstcount <= avl_burstcount;  // Prevent inferring of latch
	 vsync <= {vsync[0], vn_in};
	 hsync <= {hsync[0], hn_in};
	 
	 case(read_state)
	 4'h0: begin //Frame sync, FIFO, and AVL reset
		avl_address <= 27'h0;
		fifo_clr <= 1'b1;
		burst_count <= 16'h0;
		  
		// check for beginning of frame
		if((vsync == 2'b01) && (hsync == 2'b01)) begin
			read_state <= 4'h1;
			fifo_clr <= 1'b0;
		end
	 end
	 /* I _THINK_ the LPDDR2 IP can take up to 8 burst requests, but the
	  * docs on it are terrible and don't really explain it well.
	  * Nor does it really cleanly explain how to tell if its done sending
	  * data. So, lets do one at a time, since we have enough margin.
	  */
	 4'h1: begin //Start burst read
		// avl_burstcount is always set to 128
		// 15x 128 word bursts per line (32 bits per word, of which 24 bits are used for RGB)
		if(!fifo_used[10]) begin  //If the FIFO is half full, wait
			avl_read <= 1'b1;
			avl_burstbegin <= 1'b1;
			read_state <= 4'h2;
			burst_count <= burst_count + 1'b1;
		end
	 end
	 4'h2: begin // Wait for wait request from slave
		avl_burstbegin <= 1'b0;
		avl_read <= 1'b0;
		if(avl_waitrequest_n) // If read is done, go to the next state
		  read_state <= 4'h3;
	 end
	 4'h3: begin //Latch in data to the FIFO
		if(avl_readdatavalid) begin // If data is valid
			fifo_data <= avl_readdata;
			dat_count <= dat_count + 1'b1;
			if(dat_count == 7'd127) begin //On THIS clock, we just got the 128th word
			  avl_address <= avl_address + 'd128;
			  // If this is the 16200th burst, its the last for this frame
			  if(burst_count > 16'd16199) 
				read_state <= 4'h0; // go back to idle until the next frame
			  else 
				read_state <= 4'h1; // continue with this frame
			end
		end
	 end
	 default: read_state <= 4'h0;
	 endcase	
  end 
end

		
////////////	SRAM Address Generator	  ////////////
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
		   intram_address <= intram_address + 1;
	    else
		   if (y < 'd1080)
				intram_address <= (y * 'd240); // 240 bytes per line for packed 1bpp structure
			else
				intram_address <= 0;
	  end
	end
end*/

endmodule
