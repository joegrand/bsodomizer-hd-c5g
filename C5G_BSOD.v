
//======================================================================
//
// C5G_BSOD.v
// ---------
// Top level wrapper for BSODomizer HD using the Cyclone V GX Starter Kit.
//
// Authors: Joe Grand and Zoz Brooks
//

module C5G_BSOD(

	//////////// CLOCK //////////
	input 		          		CLOCK_125_p,
	input 		          		CLOCK_50_B5B,
	input 		          		CLOCK_50_B6A,
	input 		          		CLOCK_50_B7A,
	input 		          		CLOCK_50_B8A,

	//////////// LED //////////
	output		     [7:0]		LEDG,
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,
	
	//////////// KEY //////////
	input 		          		CPU_RESET_n,
	input 		     [3:0]		KEY,

	//////////// HDMI-TX //////////
	output		          		HDMI_TX_CLK,
	output		    [23:0]		HDMI_TX_D,
	output		          		HDMI_TX_DE,
	output		          		HDMI_TX_HS,
	input 		          		HDMI_TX_INT,
	output		          		HDMI_TX_VS,

	//////////// I2C for Audio/HDMI-TX/Si5338/HSMC //////////
	output		          		I2C_SCL,
	inout 		          		I2C_SDA,

	//////////// SDCARD //////////
	output		          		SD_CLK,
	inout 		          		SD_CMD,
	inout 		     [3:0]		SD_DAT,

	//////////// LPDDR2 //////////
//	output		     [9:0]		DDR2LP_CA,
//	output		          		DDR2LP_CK_n,
//	output		          		DDR2LP_CK_p,
//	output		     [1:0]		DDR2LP_CKE,
//	output		     [1:0]		DDR2LP_CS_n,
//	output		     [3:0]		DDR2LP_DM,
//	inout 		    [31:0]		DDR2LP_DQ,
//	inout 		     [3:0]		DDR2LP_DQS_n,
//	inout 		     [3:0]		DDR2LP_DQS_p,
//	input 		          		DDR2LP_OCT_RZQ,

	//////////// GPIO, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
);
 
  
//=======================================================
//  Registers
//=======================================================

reg [32:0] counter;
reg state;   


//=======================================================
//  Wires
//=======================================================

wire clk148M_pll;
wire reset_n;

	
//=======================================================
//  Assignments
//=======================================================

assign LEDG[0] = state; 	 // heartbeat for testing
assign GPIO[22] = !SW[0];   // pass-through v. bsod mode select


//=======================================================
//  Core instantiations
//=======================================================

// PLL for 148.5MHz PCLK generation
pll sys_pll (
	.refclk(CLOCK_50_B5B),
	.rst(!CPU_RESET_n),
	.outclk_0(clk148M_pll),
	.locked(reset_n)
);

// ADV7513 HDMI Transceiver
hdmi_tx_ctrl hdmi (
	.clk(CLOCK_50_B5B),
	.reset(1'b0),
	.scl(I2C_SCL),
	.sda(I2C_SDA),
	.inttx(HDMI_TX_INT)
);

// Video Generator
top_sync_vg_pattern vg (
	.clk_in(clk148M_pll), 				// PCLK (148.5MHz) sent into video generator
	.resetb(reset_n),	
	.adv7513_hs(HDMI_TX_HS),     		// HS (HSync) 
	.adv7513_vs(HDMI_TX_VS),       	// VS (VSync)
	.adv7513_clk(HDMI_TX_CLK),		   // PCLK
	.adv7513_d(HDMI_TX_D),			   // Data lines
	.adv7513_de(HDMI_TX_DE)  			// Data enable
);
  	
		
//=======================================================
//  Structural coding
//=======================================================

//always @ blocks go here
//	always @(sensitivity list)
//		commmands-to-run-when-triggered;
always @ (posedge CLOCK_50_B5B) 
begin
	if (reset_n)
		counter <= counter + 1;
		state <= counter[26];
end

endmodule
