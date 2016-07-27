`timescale 1ns / 1ps

module top_sync_vg_pattern ( 
	input  wire clk_in,  
   input  wire resetb,  
   output reg adv7513_hs,       	// HSYNC 
   output reg adv7513_vs,       	// VSYNC 
   output wire adv7513_clk,      // CLK 
   output reg [23:0] adv7513_d,  // DATA 
   output reg adv7513_de,        // DE
	input  wire [2:0] dip_sw,		// SW 
	
	input  wire 		  avl_clk,					//	   LPDDR2 (read only)
	input  wire			  local_init_done,	  
	input  wire         avl_waitrequest_n, 	// 	avl.waitrequest_n
	output wire  [26:0] avl_address,       	//       .address
	input  wire         avl_readdatavalid, 	//       .readdatavalid
	input  wire  [31:0] avl_readdata,      	//       .readdata
	output wire         avl_read,          	//       .read
	output wire			  avl_burstbegin			//			.burstbegin
); 
/* ************************************* */ 
 
// 1080p (1920 x 1080, non-interlaced) 
parameter INTERLACED  = 1'b0; 
parameter V_TOTAL_0   = 12'd1125; 
parameter V_FP_0      = 12'd4; 
parameter V_BP_0      = 12'd36; 
parameter V_SYNC_0    = 12'd5; 
parameter V_TOTAL_1   = 12'd0; 
parameter V_FP_1      = 12'd0; 
parameter V_BP_1      = 12'd0; 
parameter V_SYNC_1    = 12'd0; 
parameter H_TOTAL     = 12'd2200; 
parameter H_FP        = 12'd88; 
parameter H_BP        = 12'd148; 
parameter H_SYNC      = 12'd44; 
parameter HV_OFFSET_0 = 12'd0; 
parameter HV_OFFSET_1 = 12'd0; 
parameter PATTERN_RAMP_STEP = 20'h0222;
 
wire reset; 
assign reset = !resetb; 
    
wire [11:0] x_out; 
wire [12:0] y_out; 
wire [7:0] r_out; 
wire [7:0] g_out; 
wire [7:0] b_out; 

reg pclk;
    
   /* ********************* */ 
   sync_vg #(.X_BITS(12), .Y_BITS(12)) sync_vg   
   ( 
     .clk(pclk), 
     .reset(reset),  
     .interlaced(INTERLACED), 
     .clk_out(), 
     .v_total_0(V_TOTAL_0), 
     .v_fp_0(V_FP_0), 
     .v_bp_0(V_BP_0), 
     .v_sync_0(V_SYNC_0), 
     .v_total_1(V_TOTAL_1), 
     .v_fp_1(V_FP_1), 
     .v_bp_1(V_BP_1), 
     .v_sync_1(V_SYNC_1), 
     .h_total(H_TOTAL), 
     .h_fp(H_FP), 
     .h_bp(H_BP), 
     .h_sync(H_SYNC), 
     .hv_offset_0(HV_OFFSET_0), 
     .hv_offset_1(HV_OFFSET_1), 
     .de_out(de), 
     .vs_out(vs), 
     .v_count_out(), 
     .h_count_out(), 
     .x_out(x_out), 
     .y_out(y_out),   
     .hs_out(hs), 
     .field_out(field) 
   ); 
    
	pattern_vg #( 
	  .B(8), // Bits per channel 
	  .X_BITS(12), 
	  .Y_BITS(12), 
	  .FRACTIONAL_BITS(12)) // Number of fractional bits for ramp pattern 
	pattern_vg ( 
	  .reset(reset), 
	  .clk_in(avl_clk), 
	  .x(x_out), 
	  .y(y_out[11:0]), 
	  .vn_in(vs), 
	  .hn_in(hs), 
	  .dn_in(de), 
	  .r_in(8'h0), // default red channel value 
	  .g_in(8'h0), // default green channel value 
	  .b_in(8'h0), // default blue channel value 
	  .vn_out(vs_out),   
	  .hn_out(hs_out), 
	  .den_out(de_out), 
	  .r_out(r_out), 
	  .g_out(g_out), 
	  .b_out(b_out), 
	  .total_active_pix(H_TOTAL  - (H_FP + H_BP + H_SYNC)), // (1920) // h_total - (h_fp+h_bp+h_sync) 
	  .total_active_lines(INTERLACED ? (V_TOTAL_0 - (V_FP_0 + V_BP_0 + V_SYNC_0)) + (V_TOTAL_1 - (V_FP_1 + V_BP_1 + 
	V_SYNC_1)) : (V_TOTAL_0 -  (V_FP_0 + V_BP_0 + V_SYNC_0))),  // originally: 13'd480 
	  //.pattern(PATTERN_TYPE),   
	  .ramp_step(PATTERN_RAMP_STEP),
	  .dip_sw(dip_sw),
	  .avl_clk(avl_clk),								// LPDDR2 (read only)
	  .local_init_done(local_init_done),
	  .avl_waitrequest_n(avl_waitrequest_n),                
	  .avl_address(avl_address),                      
	  .avl_readdatavalid(avl_readdatavalid),                 
	  .avl_readdata(avl_readdata),                      
	  .avl_read(avl_read),                          
	  .avl_burstbegin(avl_burstbegin)
	  ); 
     
	  
	// clock divider to create PCLK (148.5MHz) from 2xPCLK (needed for LPDDR2/pattern_vg.v)
	always@(posedge avl_clk or posedge reset)
	begin
		if(reset) 
			pclk <= 1'b0; 
		else 
			pclk <= ~pclk;
	end
	    
   //assign adv7513_clk = ~clk_in; 
   assign adv7513_clk = ~pclk;
	
   //always @(posedge clk_in) 
	always @(posedge pclk or posedge reset)
   begin 
	  if(reset)
	  begin
		adv7513_d <= 24'h0; 
		adv7513_hs <= 8'h00; 
		adv7513_vs <= 8'h00; 
		adv7513_de <= 8'h00; 
	  end
	  else begin
		adv7513_d[23:16] <= r_out; 
		adv7513_d[15:8] <= g_out; 
		adv7513_d[7:0] <= b_out; 
		adv7513_hs <= hs; 
		adv7513_vs <= vs; 
		adv7513_de <= de; 
	  end
   end 
	
endmodule