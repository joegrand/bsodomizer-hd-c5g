
//======================================================================
//
// C5G_BSOD.v
// ---------
// Top level wrapper for BSODomizer HD using the Cyclone V GX Starter Kit.
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
	output							HDMI_RX_RST_n,
	input		   	       		HDMI_RX_CLK,
	input		    	[23:0]		HDMI_RX_D,
	input			          		HDMI_RX_DE,
	input			          		HDMI_RX_HS,
	input 		          		HDMI_RX_INT,
	input			          		HDMI_RX_VS,

	//////////// I2C for HDMI-RX //////////
	output		          		HDMI_RX_I2C_SCL,
	inout 		          		HDMI_RX_I2C_SDA,
	
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

	//////////// GPIO //////////
	output							HDMI_SW
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
wire hdmi_tx_clk_148_5;  // PCLK for driving HDMI TX
wire hdmi_tx_clk_297;    // 2x PCLK for use w/ LPDDR2 port 1 clock
wire hdmi_tx_pll_locked;

// LPDDR2
wire afi_clk; // Avalon bus clock
wire afi_half_clk;

wire fpga_lpddr2_test_pass/*synthesis keep*/;
wire fpga_lpddr2_test_fail/*synthesis keep*/;
wire fpga_lpddr2_test_complete/*synthesis keep*/;
wire fpga_lpddr2_local_init_done/*synthesis keep*/;
wire fpga_lpddr2_local_cal_success/*synthesis keep*/;
wire fpga_lpddr2_local_cal_fail/*synthesis keep*/;
	
wire test_global_reset_n;
wire test_soft_reset_n;
wire test_start_n;  

wire         	fpga_lpddr2_avl_0_ready;        // avl_0.waitrequest_n
wire         	fpga_lpddr2_avl_0_burstbegin;   //    .beginbursttransfer
wire 	[26:0]  	fpga_lpddr2_avl_0_addr;         //    .address
wire         	fpga_lpddr2_avl_0_rdata_valid;  //    .readdatavalid
wire 	[31:0] 	fpga_lpddr2_avl_0_rdata;        //    .readdata
wire 	[31:0] 	fpga_lpddr2_avl_0_wdata;        //    .writedata
wire         	fpga_lpddr2_avl_0_read_req;     //    .read
wire         	fpga_lpddr2_avl_0_write_req;    //    .write
wire 	[2:0]		fpga_lpddr2_avl_0_size;         //    .burstcount

wire         	fpga_lpddr2_avl_1_ready;        // avl_1.waitrequest_n
wire         	fpga_lpddr2_avl_1_burstbegin;   //    .beginbursttransfer
wire 	[26:0]  	fpga_lpddr2_avl_1_addr;         //    .address
wire         	fpga_lpddr2_avl_1_rdata_valid;  //    .readdatavalid
wire 	[31:0] 	fpga_lpddr2_avl_1_rdata;        //    .readdata
wire 	[31:0] 	fpga_lpddr2_avl_1_wdata;        //    .writedata
wire         	fpga_lpddr2_avl_1_read_req;     //    .read
wire         	fpga_lpddr2_avl_1_write_req;    //    .write
wire 	[7:0]		fpga_lpddr2_avl_1_size;         //    .burstcount

wire RXnTX;
wire test_software_reset_n;


//=======================================================
//  Assignments
//=======================================================

assign LEDG[0] = state; 	// Heartbeat for testing

assign RXnTX = SW[9]; 		// Mode select: TX (0), RX/capture (1)
assign HDMI_SW = !RXnTX;	// HDMI_SW output to TS3DV642 HDMI Switch: Passthrough (0), FPGA (1)
assign HDMI_RX_RST_n = CPU_RESET_n;

// blink LED until LPDDR2 RAM test is complete
assign LEDG[1] = (fpga_lpddr2_local_init_done & fpga_lpddr2_local_cal_success) ? (fpga_lpddr2_test_complete ? 1'b1 : state):1'b0;

assign fpga_lpddr2_avl_0_size = 3'b001;


//=======================================================
//  Core instantiations
//=======================================================

// PLL for 148.5MHz PCLK generation
ALTCLKCTRL altclk (
	.inclk(CLOCK_50_B5B),
	.outclk(altclk_out)
	);
	
hdmi_tx_pll pll (
	.refclk(altclk_out),
	.rst(!CPU_RESET_n),
	.outclk_0(hdmi_tx_clk_148_5), // PCLK
	.outclk_1(hdmi_tx_clk_297),   // 2xPCLK
	.locked(hdmi_tx_pll_locked)
);

// ADV7513 HDMI Transceiver
hdmi_tx_ctrl hdmi_tx (
	.clk(CLOCK_50_B5B),
	.reset(!CPU_RESET_n),
	.scl(I2C_SCL),
	.sda(I2C_SDA),
	.inttx(HDMI_TX_INT)
);

// Video Generator
top_sync_vg_pattern vg (
	.clk_in(hdmi_tx_clk_148_5), 		// PCLK (148.5MHz) sent into video generator
	.resetb(CPU_RESET_n & hdmi_tx_pll_locked & !RXnTX & fpga_lpddr2_test_complete),	// Start if PLL is locked, TX mode selected, and LPDDR2 filling is complete 
	.adv7513_hs(HDMI_TX_HS),     		// HS (HSync) 
	.adv7513_vs(HDMI_TX_VS),       	// VS (VSync)
	.adv7513_clk(HDMI_TX_CLK),		   // PCLK
	.adv7513_d(HDMI_TX_D),			   // Data lines
	.adv7513_de(HDMI_TX_DE),  			// Data enable
	.dip_sw(SW),							// DIP switches for pattern selection
		
	.avl_clk(hdmi_tx_clk_297),			// LPDDR2 (read only)
	.local_init_done(fpga_lpddr2_local_init_done), 
	.avl_waitrequest_n(fpga_lpddr2_avl_1_ready),                 
	.avl_address(fpga_lpddr2_avl_1_addr),                      
	.avl_readdatavalid(fpga_lpddr2_avl_1_rdata_valid),                 
	.avl_readdata(fpga_lpddr2_avl_1_rdata),                      
	.avl_read(fpga_lpddr2_avl_1_read_req),                          
	.avl_burstbegin(fpga_lpddr2_avl_1_burstbegin),
	.avl_burstcount(fpga_lpddr2_avl_1_size)
);

// ADV7611 HDMI Receiver
hdmi_rx_ctrl hdmi_rx (
	.clk(CLOCK_50_B5B),
	.reset(!CPU_RESET_n), 
	.scl(HDMI_RX_I2C_SCL),
	.sda(HDMI_RX_I2C_SDA)
);
	
fpga_lpddr2 fpga_lpddr2_inst(
/*input  wire       */   .pll_ref_clk(CLOCK_50_B5B),           	//	pll_ref_clk.clk
/*input  wire       */   .global_reset_n(test_global_reset_n), 	// global_reset.reset_n
/*input  wire       */   .soft_reset_n(test_software_reset_n), 	// soft_reset.reset_n
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
		
/*output wire       */   .avl_ready_0(fpga_lpddr2_avl_0_ready),           	  // avl_0.waitrequest_n
/*input  wire       */   .avl_burstbegin_0(fpga_lpddr2_avl_0_burstbegin),    //      .beginbursttransfer
/*input  wire [26:0]*/   .avl_addr_0(fpga_lpddr2_avl_0_addr),                //      .address
/*output wire       */   .avl_rdata_valid_0(fpga_lpddr2_avl_0_rdata_valid),  //      .readdatavalid
/*output wire [31:0]*/   .avl_rdata_0(fpga_lpddr2_avl_0_rdata),              //      .readdata
/*input  wire [31:0]*/   .avl_wdata_0(fpga_lpddr2_avl_0_wdata),              //      .writedata
/*input  wire [3:0] */   .avl_be_0(4'hF),                   					  //      .byteenable
/*input  wire       */   .avl_read_req_0(fpga_lpddr2_avl_0_read_req),        //      .read
/*input  wire       */   .avl_write_req_0(fpga_lpddr2_avl_0_write_req),      //      .write
/*input  wire [2:0] */   .avl_size_0(fpga_lpddr2_avl_0_size),                //      .burstcount
	
/*output wire       */   .avl_ready_1(fpga_lpddr2_avl_1_ready),              // avl_1.waitrequest_n
/*input  wire       */	 .avl_burstbegin_1(fpga_lpddr2_avl_1_burstbegin),    //      .beginbursttransfer
/*input  wire [26:0]*/   .avl_addr_1(fpga_lpddr2_avl_1_addr),                //      .address
/*output wire       */   .avl_rdata_valid_1(fpga_lpddr2_avl_1_rdata_valid),  //      .readdatavalid
/*output wire [31:0]*/   .avl_rdata_1(fpga_lpddr2_avl_1_rdata),              //      .readdata
/*input  wire [31:0]*/   .avl_wdata_1(fpga_lpddr2_avl_1_wdata),              //      .writedata
/*input  wire [3:0] */   .avl_be_1(4'hF),                   					  //      .byteenable
/*input  wire       */   .avl_read_req_1(fpga_lpddr2_avl_1_read_req),        //      .read
/*input  wire       */   .avl_write_req_1(fpga_lpddr2_avl_1_write_req),      //      .write
/*input  wire [2:0] */   .avl_size_1(fpga_lpddr2_avl_1_size),                //      .burstcount

/*input  wire       */   .mp_cmd_clk_0_clk(afi_half_clk),           			  // mp_cmd_clk_0.clk
/*input  wire       */   .mp_cmd_reset_n_0_reset_n(test_software_reset_n),   // mp_cmd_reset_n_0.reset_n
/*input  wire       */   .mp_cmd_clk_1_clk(hdmi_tx_clk_297),           	  	  // mp_cmd_clk_1.clk
/*input  wire       */   .mp_cmd_reset_n_1_reset_n(CPU_RESET_n),   			  // mp_cmd_reset_n_1.reset_n		

/*input  wire       */   .mp_rfifo_clk_0_clk(afi_half_clk),         			  // mp_rfifo_clk_0.clk
/*input  wire       */   .mp_rfifo_reset_n_0_reset_n(test_software_reset_n), // mp_rfifo_reset_n_0.reset_n
/*input  wire       */   .mp_wfifo_clk_0_clk(afi_half_clk),         			  // mp_wfifo_clk_0.clk
/*input  wire       */   .mp_wfifo_reset_n_0_reset_n(test_software_reset_n), // mp_wfifo_reset_n_0.reset_n
/*input  wire       */   .mp_rfifo_clk_1_clk(hdmi_tx_clk_297),         	     // mp_rfifo_clk_1.clk
/*input  wire       */   .mp_rfifo_reset_n_1_reset_n(CPU_RESET_n), 			  // mp_rfifo_reset_n_1.reset_n
/*input  wire       */   .mp_wfifo_clk_1_clk(hdmi_tx_clk_297),         	     // mp_wfifo_clk_1.clk
/*input  wire       */   .mp_wfifo_reset_n_1_reset_n(CPU_RESET_n), 		     // mp_wfifo_reset_n_1.reset_n	

/*output wire       */   .local_init_done(fpga_lpddr2_local_init_done),      	// status.local_init_done
/*output wire       */   .local_cal_success(fpga_lpddr2_local_cal_success),  	//       .local_cal_success
/*output wire       */   .local_cal_fail(fpga_lpddr2_local_cal_fail),        	//       .local_cal_fail
	
/*input  wire       */   .oct_rzqin(DDR2LP_OCT_RZQ)                  			// oct.rzqin		
);
	
	
Avalon_bus_RW_Test fpga_lpddr2_Verify(
	.iCLK(afi_half_clk),
	.iRST_n(test_software_reset_n),
	.iBUTTON(test_start_n),

	.local_init_done(fpga_lpddr2_local_init_done),  // LPDDR2 (write only)
	.avl_waitrequest_n(fpga_lpddr2_avl_0_ready),                 
	.avl_address(fpga_lpddr2_avl_0_addr),                      
	.avl_writedata(fpga_lpddr2_avl_0_wdata),                     
	.avl_write(fpga_lpddr2_avl_0_write_req),    
	.avl_burstbegin(fpga_lpddr2_avl_0_burstbegin),
		
	.drv_status_test_complete(fpga_lpddr2_test_complete),
	
	.resetb(CPU_RESET_n & RXnTX),		// Start if RX mode selected	
	.adv7611_hs(HDMI_RX_HS),     		// HS (HSync) 
	.adv7611_vs(HDMI_RX_VS),       	// VS (VSync)
	.adv7611_clk(HDMI_RX_CLK),		   // LLC (Line-locked output clock)
	.adv7611_d(HDMI_RX_D),			   // Data lines
	.adv7611_de(HDMI_RX_DE)  			// Data enable
);


//=======================================================
//  Structural coding
//=======================================================

//always @ blocks go here
//	always @(sensitivity list)
//		commmands-to-run-when-triggered;
always @ (posedge CLOCK_50_B6A) 
begin
	if (CPU_RESET_n)
		counter <= counter + 1;
		state <= counter[26];
end

// LPDDR2 RW test code
reg [31:0] cont;
always @ (posedge CLOCK_50_B6A)
cont <= (cont == 32'd4_000_001) ? 32'd0 : cont + 1'b1;

reg[4:0] sample;
always @ (posedge CLOCK_50_B6A)
begin
	if(cont == 32'd4_000_000)
		sample[4:0] = {sample[3:0], KEY[0]};
	else 
		sample[4:0] = sample[4:0];
end

// start-up/reset sequence for LPDDR2 port
assign test_software_reset_n	= (sample[1:0] == 2'b10) ? 1'b0 : 1'b1;
assign test_global_reset_n   	= (sample[3:2] == 2'b10) ? 1'b0 : 1'b1;
assign test_start_n         	= (sample[4:3] == 2'b01) ? 1'b0 : 1'b1;

endmodule
