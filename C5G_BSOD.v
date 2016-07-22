
//======================================================================
//
// C5G_BSOD.v
// ---------
// Top level wrapper for BSODomizer HD using the Cyclone V GX Starter Kit.
//
// Authors: Joe Grand [www.grandideastudio.com] and Zoz
//

// Define a delay of ''#1'' as 1 ns. Discretize the simulation in units of 1 ps. 
`timescale 1ns / 1ps

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
	output		     [23:0]		HDMI_TX_D,
	output		          		HDMI_TX_DE,
	output		          		HDMI_TX_HS,
	input 		          		HDMI_TX_INT,
	output		          		HDMI_TX_VS,

	//////////// I2C for Audio/HDMI-TX/Si5338/HSMC //////////
	output		          		I2C_SCL,
	inout 		          		I2C_SDA,

	//////////// HDMI-RX //////////
//	input		   	       		HDMI_RX_CLK,
//	input		    	[23:0]		HDMI_RX_D,
//	output		          		HDMI_RX_DE,
//	output		          		HDMI_RX_HS,
//	input 		          		HDMI_RX_INT,
//	output		          		HDMI_RX_VS,
//
//	//////////// I2C for HDMI-RX //////////
//	output		          		HDMI_RX_I2C_SCL,
//	inout 		          		HDMI_RX_I2C_SDA,
	
	//////////// SDCARD //////////
	output		          		SD_CLK,
	inout 		          		SD_CMD,
	inout 		     [3:0]		SD_DAT,

	//////////// LPDDR2 //////////
   output  			[9:0]  		DDR2LP_CA,
   output  			[1:0]  		DDR2LP_CKE,
   output             			DDR2LP_CK_n,
   output             			DDR2LP_CK_p,
   output      	[1:0]  		DDR2LP_CS_n,
   output      	[3:0]  		DDR2LP_DM,
   inout       	[31:0] 		DDR2LP_DQ,
   inout       	[3:0]  		DDR2LP_DQS_n,
   inout       	[3:0]  		DDR2LP_DQS_p,
   input              			DDR2LP_OCT_RZQ,

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

wire altclk_out;
wire clk148M_pll;
wire reset_n;

// LPDDR2
wire afi_clk; // clock for test controllers
wire afi_half_clk;

wire fpga_lpddr2_test_pass/*synthesis keep*/;
wire fpga_lpddr2_test_fail/*synthesis keep*/;
wire fpga_lpddr2_test_complete/*synthesis keep*/;
wire fpga_lpddr2_local_init_done/*synthesis keep*/;
wire fpga_lpddr2_local_cal_success/*synthesis keep*/;
wire fpga_lpddr2_local_cal_fail/*synthesis keep*/;
	
wire  test_software_reset_n;
wire  test_global_reset_n;   
wire  test_start_n;  

wire         	fpga_lpddr2_avl_ready;       	// avl.waitrequest_n
wire         	fpga_lpddr2_avl_burstbegin;   //    .beginbursttransfer
wire 	[26:0]  	fpga_lpddr2_avl_addr;         //    .address
wire         	fpga_lpddr2_avl_rdata_valid;  //    .readdatavalid
wire 	[31:0] 	fpga_lpddr2_avl_rdata;        //    .readdata
wire 	[31:0] 	fpga_lpddr2_avl_wdata;        //    .writedata
wire         	fpga_lpddr2_avl_read_req;     //    .read
wire         	fpga_lpddr2_avl_write_req;    //    .write
wire 	[2:0]		fpga_lpddr2_avl_size;         //    .burstcount


//=======================================================
//  Assignments
//=======================================================

assign LEDG[7] = state; 	 // heartbeat for testing
assign GPIO[30] = !SW[9];   // HDMI_SW (pass-through v. bsod mode select)

assign fpga_lpddr2_avl_size = 3'b001;


//=======================================================
//  Core instantiations
//=======================================================

// PLL for 148.5MHz PCLK generation
ALTCLKCTRL clk (
	.inclk(CLOCK_50_B8A),
	.outclk(altclk_out)
	);
	
hdmi_tx_pll pll (
	.refclk(altclk_out),
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
	.adv7513_de(HDMI_TX_DE),  			// Data enable
	.dip_sw(SW)								// DIP switches for pattern selection
);

// ADV7611 HDMI Receiver
//hdmi_rx_ctrl hdmi (
//	.clk(CLOCK_50_B5B),
//	.reset(1'b0),
//	.scl(HDMI_RX_I2C_SCL),
//	.sda(HDMI_RX_I2C_SDA),
//	.intrx(HDMI_RX_INT)
//);

// Video Receiver
//top_sync_vr vr (
//	.resetb(reset_n),	
//	.adv7611_hs(HDMI_RX_HS),     		// HS (HSync) 
//	.adv7611_vs(HDMI_RX_VS),       	// VS (VSync)
//	.adv7611_clk(HDMI_RX_CLK),		   // LLC (Line-locked output clock)
//	.adv7611_d(HDMI_RX_D),			   // Data lines
//	.adv7611_de(HDMI_RX_DE)  			// Data enable
//);
  	
	
fpga_lpddr2 fpga_lpddr2_inst(
/*input  wire       */   .pll_ref_clk(CLOCK_50_B5B),           	//	pll_ref_clk.clk
/*input  wire       */   .global_reset_n(test_global_reset_n),    // global_reset.reset_n
/*input  wire       */   .soft_reset_n(test_software_reset_n),    // soft_reset.reset_n
/*output wire       */   .afi_clk(afi_clk),                    	// afi_clk.clk
/*output wire       */   .afi_half_clk(afi_half_clk),             // afi_half_clk.clk
/*output wire       */   .afi_reset_n(),                				// afi_reset.reset_n
/*output wire       */   .afi_reset_export_n(),         				// afi_reset_export.reset_n
		
/*output wire [9:0] */   .mem_ca(DDR2LP_CA),                     	// memory.mem_ca
/*output wire [0:0] */   .mem_ck(DDR2LP_CK_p),                    //       .mem_ck
/*output wire [0:0] */   .mem_ck_n(DDR2LP_CK_n),                  //       .mem_ck_n
/*output wire [0:0] */   .mem_cke(DDR2LP_CKE[0]),                 //       .mem_cke
/*output wire [0:0] */   .mem_cs_n(DDR2LP_CS_n[0]),               //       .mem_cs_n
/*output wire [3:0] */   .mem_dm(DDR2LP_DM),                     	//       .mem_dm
/*inout  wire [31:0]*/   .mem_dq(DDR2LP_DQ),                     	//       .mem_dq
/*inout  wire [3:0] */   .mem_dqs(DDR2LP_DQS_p),                  //       .mem_dqs
/*inout  wire [3:0] */   .mem_dqs_n(DDR2LP_DQS_n),                //       .mem_dqs_n
		
/*inout  wire [3:0] */   .avl_ready_0(fpga_lpddr2_avl_ready),           	// avl_0.waitrequest_n
/*input  wire       */   .avl_burstbegin_0(fpga_lpddr2_avl_burstbegin),    //      .beginbursttransfer
/*input  wire [26:0]*/   .avl_addr_0(fpga_lpddr2_avl_addr),                //      .address
/*output wire       */   .avl_rdata_valid_0(fpga_lpddr2_avl_rdata_valid),  //      .readdatavalid
/*output wire [31:0]*/   .avl_rdata_0(fpga_lpddr2_avl_rdata),              //      .readdata
/*input  wire [31:0]*/   .avl_wdata_0(fpga_lpddr2_avl_wdata),              //      .writedata
/*input  wire [3:0] */   .avl_be_0(4'hF),                   					//      .byteenable
/*input  wire       */   .avl_read_req_0(fpga_lpddr2_avl_read_req),        //      .read
/*input  wire       */   .avl_write_req_0(fpga_lpddr2_avl_write_req),      //      .write
/*input  wire [2:0] */   .avl_size_0(fpga_lpddr2_avl_size),                //      .burstcount
		
/*input  wire       */   .mp_cmd_clk_0_clk(afi_half_clk),           			// mp_cmd_clk_0.clk
/*input  wire       */   .mp_cmd_reset_n_0_reset_n(test_software_reset_n), // mp_cmd_reset_n_0.reset_n
/*input  wire       */   .mp_rfifo_clk_0_clk(afi_half_clk),         			// mp_rfifo_clk_0.clk
/*input  wire       */   .mp_rfifo_reset_n_0_reset_n(test_software_reset_n), 	// mp_rfifo_reset_n_0.reset_n
/*input  wire       */   .mp_wfifo_clk_0_clk(afi_half_clk),         			  	// mp_wfifo_clk_0.clk
/*input  wire       */   .mp_wfifo_reset_n_0_reset_n(test_software_reset_n), 	// mp_wfifo_reset_n_0.reset_n
		
/*output wire       */   .local_init_done(fpga_lpddr2_local_init_done),      	// status.local_init_done
/*output wire       */   .local_cal_success(fpga_lpddr2_local_cal_success),  	//       .local_cal_success
/*output wire       */   .local_cal_fail(fpga_lpddr2_local_cal_fail),        	//       .local_cal_fail
	
/*input  wire       */   .oct_rzqin(DDR2LP_OCT_RZQ)                  			// oct.rzqin		
);
	
	
Avalon_bus_RW_Test fpga_lpddr2_Verify(
	.iCLK(afi_half_clk),
	.iRST_n(test_software_reset_n),
	.iBUTTON(test_start_n ),

	.local_init_done(fpga_lpddr2_local_init_done),
	.avl_waitrequest_n(fpga_lpddr2_avl_ready),                 
	.avl_address(fpga_lpddr2_avl_addr),                      
	.avl_readdatavalid(fpga_lpddr2_avl_rdata_valid),                 
	.avl_readdata(fpga_lpddr2_avl_rdata),                      
	.avl_writedata(fpga_lpddr2_avl_wdata),                     
	.avl_read(fpga_lpddr2_avl_read_req),                          
	.avl_write(fpga_lpddr2_avl_write_req),    
	.avl_burstbegin(fpga_lpddr2_avl_burstbegin),
		
	.drv_status_pass(fpga_lpddr2_test_pass),
	.drv_status_fail(fpga_lpddr2_test_fail),
	.drv_status_test_complete(fpga_lpddr2_test_complete)	
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


// LPDDR2 RW test code
reg [31:0]  cont;
always@(posedge CLOCK_50_B6A)
cont<=(cont==32'd4_000_001)?32'd0:cont+1'b1;

reg[4:0] sample;
always@(posedge CLOCK_50_B6A)
begin
	if(cont==32'd4_000_000)
		sample[4:0]={sample[3:0],KEY[0]};
	else 
		sample[4:0]=sample[4:0];
end

assign test_software_reset_n=(sample[1:0]==2'b10)?1'b0:1'b1;
assign test_global_reset_n   =(sample[3:2]==2'b10)?1'b0:1'b1;
assign test_start_n         =(sample[4:3]==2'b01)?1'b0:1'b1;

wire [2:0] test_result;
assign test_result[0] = KEY[0];
assign test_result[1] = (fpga_lpddr2_local_init_done& fpga_lpddr2_local_cal_success) ? (fpga_lpddr2_test_complete? fpga_lpddr2_test_pass : heart_beat[23]):1'b0;
assign test_result[2] =  heart_beat[23];

assign LEDG[2:0] = KEY[0]?test_result:3'b111;
	
reg [23:0] heart_beat;
always @ (posedge CLOCK_50_B6A)
begin
	heart_beat <= heart_beat + 1;
end

endmodule
