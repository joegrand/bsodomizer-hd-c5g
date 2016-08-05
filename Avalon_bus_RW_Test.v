module Avalon_bus_RW_Test (

		iCLK,
		iRST_n,
		iBUTTON,

		local_init_done,	// LPDDR2 (write only)
		avl_waitrequest_n,                 
		avl_address,                                        
		avl_writedata,                     
		avl_write,    
		avl_burstbegin,
		drv_status_test_complete,
		c_state,
		
		resetb,			// ADV7611 HDMI RX
		adv7611_hs,
		adv7611_vs,  
		adv7611_clk, 
		adv7611_d,	
		adv7611_de
);

parameter	ADDR_W  = 27;
parameter   DATA_W  = 32;

input	iCLK;
input iRST_n;
input iBUTTON;

input	local_init_done;
input avl_waitrequest_n;     			//  avl.waitrequest_n
output [ADDR_W-1:0] avl_address;    //     .address
output [DATA_W-1:0] avl_writedata;  //     .writedata
output avl_write;             		//     .write
output drv_status_test_complete;
output avl_burstbegin;
output [3:0] c_state;		

input resetb;
input adv7611_hs;
input adv7611_vs;
input adv7611_clk;
input [23:0] adv7611_d;
input adv7611_de;


//=======================================================
//  Signal declarations
//=======================================================
reg  [1:0]        pre_button;
reg               trigger;
wire [DATA_W-1:0] y;	
reg  [3:0]        c_state;		
reg	            avl_write;
reg  [ADDR_W-1:0] avl_address;  	
reg  [DATA_W-1:0] avl_writedata;


// HDMI RX (ADV7611)
reg [7:0] r_in; 
reg [7:0] g_in; 
reg [7:0] b_in;
reg hs_in;
reg vs_in;
reg de_in;


//=======================================================
//  Core instantiations
//=======================================================


//=======================================================
//  Structural coding
//=======================================================
assign drv_status_test_complete = (c_state == 9) ? 1 : 0;  // Signal to the top module that this module is done
assign avl_burstbegin = avl_write;
		

// HDMI RX (ADV7611)	
always @(posedge adv7611_clk or negedge resetb) begin 
	if(!resetb) begin
		r_in <= 8'h00; 
		g_in <= 8'h00;
		b_in <= 8'h00;
		hs_in <= 1'b0; 
		vs_in <= 1'b0;
		de_in <= 1'b0;
	end else begin
		r_in <= adv7611_d[23:16]; 
		g_in <= adv7611_d[15:8];
		b_in <= adv7611_d[7:0];
		hs_in <= adv7611_hs; 
		vs_in <= adv7611_vs;
		de_in <= adv7611_de;
   end
end

// Write data into LPDDR2
always@(posedge iCLK or negedge iRST_n)
begin
	if (!iRST_n) begin 
		pre_button <= 2'b11;
		trigger <= 1'b0;
		c_state <= 4'b0;
		avl_write <= 1'b0;
		avl_address <= 27'b0;
	end else begin
		pre_button <= {pre_button[0], iBUTTON};
		trigger <= !pre_button[0] && pre_button[1];

	  case (c_state)
	  	0 : begin // idle
	  		avl_address <= {ADDR_W{1'b0}};
	  		if (local_init_done && trigger)
	  			c_state <= 1;
	  	end
	  	1 : begin // begin data write fo LPDDR2 
			// horizontal bars, split screen
			/*if (avl_address < ('d1920 * 'd1080) / 2) 
				avl_writedata <= 32'h0055AA55; // top 
			else
				avl_writedata <= 32'h00BB6666; // bottom*/
			
			// horizontal bars, multiple
			if (avl_address <= 27'h7E900)  
				avl_writedata <= 32'h00FF0000; // quarter 1
			else if (avl_address >= 27'h7E901 && avl_address <= 27'hFD200)
				avl_writedata <= 32'h0000FF00; // quarter 2
			else if (avl_address >= 27'hDF201 && avl_address <= 27'h17BB00)
				avl_writedata <= 32'h000000FF; // quarter 3
			else
				avl_writedata <= 32'h00FFFFFF; // quarter 4
			
			 // vertical bars, split screen
			 /*if ((avl_address % 1920) < 960)
			   avl_writedata <= 32'h0055AA55; // left
			 else
				avl_writedata <= 32'h00BB6666; // right*/
		
		   // alternating pixels
		   /*if (avl_address[0] == 1'b0)
				avl_writedata <= 32'h00FF0000;
			else
				avl_writedata <= 32'h000FFFFF;*/
				
			// pixel color = memory address
			//avl_writedata <= avl_address;
	
		   avl_write <= 1'b1;
			c_state <= 2;
	  	end
	  	2 : begin // wait until write is complete
	  		if (avl_waitrequest_n)
	  		begin
	  			avl_write <= 1'b0;
	  			c_state <= 3;
	  		end
	  	end
	  	3 : begin
	  	  if (avl_address == ('d1920 * 'd1080) - 1) // check to see if we're done writing the entire frame 
	  		begin
	  			avl_address <= {ADDR_W{1'b0}};
	  			c_state <= 9;
	  		end
	  		else // if not, increment to the next address and write again!
	  		begin
	  			avl_address <= avl_address + 1'b1;
	  			c_state <= 1;
	  		end
      end
		9 : c_state <= 9; // done!
	    default : c_state <= 0;
	  endcase
  end
end
		
endmodule 