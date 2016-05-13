// (C) 2001-2016 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



`timescale 1 ps / 1 ps

module lpddr2_example_if0_p0_addr_cmd_pads(
    reset_n,
    reset_n_afi_clk,
    pll_afi_clk,
    pll_mem_clk,
    pll_mem_phy_clk,
    pll_afi_phy_clk,
    pll_c2p_write_clk,
    pll_write_clk,
    pll_hr_clk,
    phy_ddio_addr_cmd_clk,
    phy_ddio_address,
    dll_delayctrl_in,
    enable_mem_clk,
    phy_ddio_cs_n,
    phy_ddio_cke,
    phy_mem_address,
    phy_mem_cs_n,
    phy_mem_cke,
    phy_mem_ck,
    phy_mem_ck_n
);

parameter DEVICE_FAMILY = "";
parameter MEM_ADDRESS_WIDTH     = ""; 
parameter MEM_BANK_WIDTH        = ""; 
parameter MEM_CHIP_SELECT_WIDTH = ""; 
parameter MEM_CLK_EN_WIDTH 		= ""; 
parameter MEM_CK_WIDTH 			= ""; 
parameter MEM_ODT_WIDTH 		= ""; 
parameter MEM_CONTROL_WIDTH     = ""; 

parameter AFI_ADDRESS_WIDTH         = ""; 
parameter AFI_BANK_WIDTH            = ""; 
parameter AFI_CHIP_SELECT_WIDTH     = ""; 
parameter AFI_CLK_EN_WIDTH 			= ""; 
parameter AFI_ODT_WIDTH 			= ""; 
parameter AFI_CONTROL_WIDTH         = ""; 
parameter DLL_WIDTH                 = "";
parameter REGISTER_C2P              = "";
parameter IS_HHP_HPS                = "";

input	reset_n;
input	reset_n_afi_clk;
input	pll_afi_clk;
input	pll_mem_clk;

input   pll_mem_phy_clk;
input   pll_afi_phy_clk;

input	pll_write_clk;
input	pll_hr_clk;
input	pll_c2p_write_clk;
input	phy_ddio_addr_cmd_clk;
input 	[DLL_WIDTH-1:0] dll_delayctrl_in;
input   [MEM_CK_WIDTH-1:0] enable_mem_clk;


input	[AFI_ADDRESS_WIDTH-1:0]	phy_ddio_address;




input   [AFI_CHIP_SELECT_WIDTH-1:0] phy_ddio_cs_n;
input   [AFI_CLK_EN_WIDTH-1:0] phy_ddio_cke;

output  [MEM_ADDRESS_WIDTH-1:0] phy_mem_address;
output  [MEM_CHIP_SELECT_WIDTH-1:0] phy_mem_cs_n;
output  [MEM_CLK_EN_WIDTH-1:0] phy_mem_cke;
output  [MEM_CK_WIDTH-1:0]	phy_mem_ck;
output  [MEM_CK_WIDTH-1:0]	phy_mem_ck_n;

wire	[MEM_ADDRESS_WIDTH-1:0]	address_l;
wire	[MEM_ADDRESS_WIDTH-1:0]	address_h;
wire	adc_ldc_ck;
wire	[MEM_CHIP_SELECT_WIDTH-1:0] cs_n_l;
wire	[MEM_CHIP_SELECT_WIDTH-1:0] cs_n_h;
wire	[MEM_CLK_EN_WIDTH-1:0] cke_l;
wire	[MEM_CLK_EN_WIDTH-1:0] cke_h;
wire	hr_seq_clock;



reg   [AFI_ADDRESS_WIDTH-1:0] phy_ddio_address_hr;
reg   [AFI_CHIP_SELECT_WIDTH-1:0] phy_ddio_cs_n_hr;
reg   [AFI_CLK_EN_WIDTH-1:0] phy_ddio_cke_hr;

generate
if (REGISTER_C2P == "false") begin
	always @(*) begin
		phy_ddio_address_hr = phy_ddio_address;	
		phy_ddio_cs_n_hr = phy_ddio_cs_n;
		phy_ddio_cke_hr = phy_ddio_cke;
	end
end else begin
	always @(posedge pll_afi_clk) begin
		phy_ddio_address_hr <= phy_ddio_address;	
		phy_ddio_cs_n_hr <= phy_ddio_cs_n;
		phy_ddio_cke_hr <= phy_ddio_cke;
	end
end
endgenerate	




wire	[MEM_ADDRESS_WIDTH-1:0]	phy_ddio_address_ll;
wire	[MEM_ADDRESS_WIDTH-1:0]	phy_ddio_address_lh;
wire	[MEM_ADDRESS_WIDTH-1:0]	phy_ddio_address_hl;
wire	[MEM_ADDRESS_WIDTH-1:0]	phy_ddio_address_hh;
wire	[MEM_CHIP_SELECT_WIDTH-1:0] phy_ddio_cs_n_l;
wire	[MEM_CHIP_SELECT_WIDTH-1:0] phy_ddio_cs_n_h;
wire	[MEM_CLK_EN_WIDTH-1:0] phy_ddio_cke_l;
wire	[MEM_CLK_EN_WIDTH-1:0] phy_ddio_cke_h;

// each signal has a high and a low portion,
// connecting to the high and low inputs of the DDIO_OUT,
// for the purpose of creating double data rate
	assign phy_ddio_address_lh = phy_ddio_address_hr[2*MEM_ADDRESS_WIDTH-1:MEM_ADDRESS_WIDTH];
	assign phy_ddio_address_ll = phy_ddio_address_hr[MEM_ADDRESS_WIDTH-1:0];
	assign phy_ddio_cke_l = phy_ddio_cke_hr[MEM_CLK_EN_WIDTH-1:0];
	assign phy_ddio_cs_n_l = phy_ddio_cs_n_hr[MEM_CHIP_SELECT_WIDTH-1:0];

	assign phy_ddio_address_hh = phy_ddio_address_hr[4*MEM_ADDRESS_WIDTH-1:3*MEM_ADDRESS_WIDTH];
	assign phy_ddio_address_hl = phy_ddio_address_hr[3*MEM_ADDRESS_WIDTH-1:2*MEM_ADDRESS_WIDTH];
	assign phy_ddio_cke_h = phy_ddio_cke_hr[2*MEM_CLK_EN_WIDTH-1:MEM_CLK_EN_WIDTH];
	assign phy_ddio_cs_n_h = phy_ddio_cs_n_hr[2*MEM_CHIP_SELECT_WIDTH-1:MEM_CHIP_SELECT_WIDTH];


	wire	[MEM_ADDRESS_WIDTH-1:0]adc_ldc_ca;
	wire	[MEM_ADDRESS_WIDTH-1:0]hr_seq_clock_ca;
	
	genvar i;
	generate
	for (i = 0; i < MEM_ADDRESS_WIDTH; i = i + 1)
	begin :address_gen
	    
	    `ifndef SIMGEN
        	lpddr2_example_if0_p0_acv_ldc # (
        		.DLL_DELAY_CTRL_WIDTH(DLL_WIDTH),
        		.ADC_PHASE_SETTING(2),
        		.ADC_INVERT_PHASE("true"),
        		.IS_HHP_HPS(IS_HHP_HPS)
        	) acv_adc_ca_ldc (
        		.pll_hr_clk(pll_afi_phy_clk),
        		.pll_dq_clk(pll_write_clk),
        		.pll_dqs_clk (pll_mem_phy_clk),
        		.dll_phy_delayctrl (dll_delayctrl_in),
        		.adc_clk_cps (adc_ldc_ca[i]),
        		.hr_clk (hr_seq_clock_ca[i])
        	);
        `else
        	assign adc_ldc_ca[i] = pll_write_clk;
        	assign hr_seq_clock_ca[i] = pll_afi_phy_clk;
        `endif
	    
		cyclonev_ddio_out hr_to_fr_hi (
		    .areset(~reset_n),
			.datainhi(phy_ddio_address_lh[i]),
			.datainlo(phy_ddio_address_hh[i]),
			.dataout(address_h[i]),
			.clkhi (hr_seq_clock_ca[i]),
			.clklo (hr_seq_clock_ca[i]),
			.muxsel (hr_seq_clock_ca[i])
		);
		defparam hr_to_fr_hi.half_rate_mode = "true",
				hr_to_fr_hi.use_new_clocking_model = "true",
				hr_to_fr_hi.async_mode = "none";

		cyclonev_ddio_out hr_to_fr_lo (
		    .areset(~reset_n),
			.datainhi(phy_ddio_address_ll[i]),
			.datainlo(phy_ddio_address_hl[i]),
			.dataout(address_l[i]),
			.clkhi (hr_seq_clock_ca[i]),
			.clklo (hr_seq_clock_ca[i]),
			.muxsel (hr_seq_clock_ca[i])
		);
		defparam hr_to_fr_lo.half_rate_mode = "true",
				hr_to_fr_lo.use_new_clocking_model = "true",
				hr_to_fr_lo.async_mode = "none";
		
		altddio_out	uaddress_pad(
	    	.aclr	    (~reset_n),
	    	.aset	    (1'b0),
	    	.datain_h   (address_l[i]),
	    	.datain_l   (address_h[i]),
	    	.dataout    (phy_mem_address[i]),
	    	.oe	    	(1'b1),
	    	.outclock   (adc_ldc_ca[i]),
	    	.outclocken (1'b1)
        );
        
        defparam 
	    	uaddress_pad.extend_oe_disable = "UNUSED",
	    	uaddress_pad.intended_device_family = DEVICE_FAMILY,
	    	uaddress_pad.invert_output = "OFF",
	    	uaddress_pad.lpm_hint = "UNUSED",
	    	uaddress_pad.lpm_type = "altddio_out",
	    	uaddress_pad.oe_reg = "UNUSED",
	    	uaddress_pad.power_up_high = "OFF",
	    	uaddress_pad.width = 1;
	    	
	end
	endgenerate






	wire	[MEM_CHIP_SELECT_WIDTH-1:0]adc_ldc_cs;
	wire	[MEM_CHIP_SELECT_WIDTH-1:0]hr_seq_clock_cs;
	generate
	for (i = 0; i < MEM_CHIP_SELECT_WIDTH; i = i + 1)
	begin :cs_n_gen
	    
	        `ifndef SIMGEN
        	lpddr2_example_if0_p0_acv_ldc # (
        		.DLL_DELAY_CTRL_WIDTH(DLL_WIDTH),
        		.ADC_PHASE_SETTING(2),
        		.ADC_INVERT_PHASE("true"),
        		.IS_HHP_HPS(IS_HHP_HPS)
        	) acv_adc_cs_ldc (
        		.pll_hr_clk(pll_afi_phy_clk),
        		.pll_dq_clk(pll_write_clk),
        		.pll_dqs_clk (pll_mem_phy_clk),
        		.dll_phy_delayctrl (dll_delayctrl_in),
        		.adc_clk_cps (adc_ldc_cs[i]),
        		.hr_clk (hr_seq_clock_cs[i])
        	);
        	`else
        	assign adc_ldc_cs[i] = pll_write_clk;
        	assign hr_seq_clock_cs[i] = pll_afi_phy_clk;
        	`endif
	    
		cyclonev_ddio_out hr_to_fr_hi (
			.areset(~reset_n),
			.datainhi(phy_ddio_cs_n_l[i]),
			.datainlo(phy_ddio_cs_n_h[i]),
			.dataout(cs_n_h[i]),
			.clkhi (hr_seq_clock_cs[i]),
			.clklo (hr_seq_clock_cs[i]),
			.muxsel (hr_seq_clock_cs[i])
		);
		defparam hr_to_fr_hi.half_rate_mode = "true",
				hr_to_fr_hi.use_new_clocking_model = "true",
				hr_to_fr_hi.async_mode = "none";

		cyclonev_ddio_out hr_to_fr_lo (
			.areset(~reset_n),
			.datainhi(phy_ddio_cs_n_l[i]),
			.datainlo(phy_ddio_cs_n_h[i]),
			.dataout(cs_n_l[i]),
			.clkhi (hr_seq_clock_cs[i]),
			.clklo (hr_seq_clock_cs[i]),
			.muxsel (hr_seq_clock_cs[i])
		);
		defparam hr_to_fr_lo.half_rate_mode = "true",
				hr_to_fr_lo.use_new_clocking_model = "true",
				hr_to_fr_lo.async_mode = "none";
		
		altddio_out	ucs_n_pad(
    		.aclr	    (~reset_n),
    		.aset	    (1'b0),
    		.datain_h   (cs_n_l[i]),
    		.datain_l   (cs_n_h[i]),
    		.dataout    (phy_mem_cs_n[i]),
    		.oe	    	(1'b1),
    		.outclock   (adc_ldc_cs[i]),
    		.outclocken (1'b1)
        );
    
        defparam 
    		ucs_n_pad.extend_oe_disable = "UNUSED",
    		ucs_n_pad.intended_device_family = DEVICE_FAMILY,
    		ucs_n_pad.invert_output = "OFF",
    		ucs_n_pad.lpm_hint = "UNUSED",
    		ucs_n_pad.lpm_type = "altddio_out",
    		ucs_n_pad.oe_reg = "UNUSED",
    		ucs_n_pad.power_up_high = "OFF",
    		ucs_n_pad.width = 1;
    		
	end
	endgenerate

	wire	[MEM_CHIP_SELECT_WIDTH-1:0]adc_ldc_cke;
	wire	[MEM_CHIP_SELECT_WIDTH-1:0]hr_seq_clock_cke;
	
	generate
	for (i = 0; i < MEM_CLK_EN_WIDTH; i = i + 1)
	begin :cke_gen
	        `ifndef SIMGEN
        	lpddr2_example_if0_p0_acv_ldc # (
        		.DLL_DELAY_CTRL_WIDTH(DLL_WIDTH),
        		.ADC_PHASE_SETTING(2),
        		.ADC_INVERT_PHASE("true"),
        		.IS_HHP_HPS(IS_HHP_HPS)
        	) acv_adc_cke_ldc (
        		.pll_hr_clk(pll_afi_phy_clk),
        		.pll_dq_clk(pll_write_clk),
        		.pll_dqs_clk (pll_mem_phy_clk),
        		.dll_phy_delayctrl (dll_delayctrl_in),
        		.adc_clk_cps (adc_ldc_cke[i]),
        		.hr_clk (hr_seq_clock_cke[i])
        	);
        	`else
        	assign adc_ldc_cke[i] = pll_write_clk;
        	assign hr_seq_clock_cke[i] = pll_afi_phy_clk;
        	`endif
	    
		cyclonev_ddio_out hr_to_fr_hi (
			.areset(~reset_n),
			.datainhi(phy_ddio_cke_l[i]),
			.datainlo(phy_ddio_cke_h[i]),
			.dataout(cke_h[i]),
			.clkhi (hr_seq_clock_cke[i]),
			.clklo (hr_seq_clock_cke[i]),
			.muxsel (hr_seq_clock_cke[i])
		);
		defparam hr_to_fr_hi.half_rate_mode = "true",
				hr_to_fr_hi.use_new_clocking_model = "true",
				hr_to_fr_hi.async_mode = "none";

		cyclonev_ddio_out hr_to_fr_lo (
			.areset(~reset_n),
			.datainhi(phy_ddio_cke_l[i]),
			.datainlo(phy_ddio_cke_h[i]),
			.dataout(cke_l[i]),
			.clkhi (hr_seq_clock_cke[i]),
			.clklo (hr_seq_clock_cke[i]),
			.muxsel (hr_seq_clock_cke[i])
		);
		defparam hr_to_fr_lo.half_rate_mode = "true",
				hr_to_fr_lo.use_new_clocking_model = "true",
				hr_to_fr_lo.async_mode = "none";
		
        altddio_out ucke_pad(
            .aclr       (~reset_n),
            .aset       (1'b0),
            .datain_h   (cke_l[i]),
            .datain_l   (cke_h[i]),
            .dataout    (phy_mem_cke[i]),
            .oe         (1'b1),
	    	.outclock   (adc_ldc_cke[i]),
            .outclocken (1'b1)
        );
        
        defparam
            ucke_pad.extend_oe_disable = "UNUSED",
            ucke_pad.intended_device_family = DEVICE_FAMILY,
            ucke_pad.invert_output = "OFF",
            ucke_pad.lpm_hint = "UNUSED",
            ucke_pad.lpm_type = "altddio_out",
            ucke_pad.oe_reg = "UNUSED",
            ucke_pad.power_up_high = "OFF",
            ucke_pad.width = 1;
            
	end
	endgenerate



  wire  [MEM_CK_WIDTH-1:0] mem_ck_source;
  wire	[MEM_CK_WIDTH-1:0] mem_ck;


localparam USE_ADDR_CMD_CPS_FOR_MEM_CK = "false";

generate
genvar clock_width;
    for (clock_width=0; clock_width<MEM_CK_WIDTH; clock_width=clock_width+1)
    begin: clock_gen




if(USE_ADDR_CMD_CPS_FOR_MEM_CK == "true")
begin
     lpddr2_example_if0_p0_acv_ldc # (
     	.DLL_DELAY_CTRL_WIDTH(DLL_WIDTH),
     	.ADC_PHASE_SETTING(0),
     	.ADC_INVERT_PHASE("false"),
	.IS_HHP_HPS(IS_HHP_HPS)
     ) acv_ck_ldc (
     	.pll_hr_clk(pll_afi_phy_clk),
     	.pll_dq_clk(pll_write_clk),
     	.pll_dqs_clk (pll_mem_phy_clk),
     	.dll_phy_delayctrl (dll_delayctrl_in),
     	.adc_clk_cps (mem_ck_source[clock_width])
     );
end
else
begin
	wire [3:0] phy_clk_in;
	wire [3:0] phy_clk_out;
	assign phy_clk_in = {pll_afi_phy_clk,pll_write_clk,pll_mem_phy_clk,1'b0};
		
	cyclonev_phy_clkbuf phy_clkbuf (
		.inclk (phy_clk_in),
		.outclk (phy_clk_out)
	);

	wire [3:0] leveled_dqs_clocks;
	cyclonev_leveling_delay_chain leveling_delay_chain_dqs (
		.clkin (phy_clk_out[1]),
		.delayctrlin (dll_delayctrl_in),
		.clkout(leveled_dqs_clocks)
	);
	defparam leveling_delay_chain_dqs.physical_clock_source = "DQS";

	cyclonev_clk_phase_select clk_phase_select_dqs (
		`ifndef SIMGEN
		.clkin(leveled_dqs_clocks[0]),
		`else
		.clkin(leveled_dqs_clocks),
		`endif
		.clkout(mem_ck_source[clock_width])
	);
	defparam clk_phase_select_dqs.physical_clock_source = "DQS";
	defparam clk_phase_select_dqs.use_phasectrlin = "false";
	defparam clk_phase_select_dqs.phase_setting = 0;
end



    altddio_out umem_ck_pad(
    	.aclr       (1'b0),
    	.aset       (1'b0),
    	.datain_h   (enable_mem_clk[clock_width]),
    	.datain_l   (1'b0),
    	.dataout    (mem_ck[clock_width]),
    	.oe     	(1'b1),
    	.outclock   (mem_ck_source[clock_width]),
    	.outclocken (1'b1)
    );

    defparam
    	umem_ck_pad.extend_oe_disable = "UNUSED",
    	umem_ck_pad.intended_device_family = DEVICE_FAMILY,
    	umem_ck_pad.invert_output = "OFF",
    	umem_ck_pad.lpm_hint = "UNUSED",
    	umem_ck_pad.lpm_type = "altddio_out",
    	umem_ck_pad.oe_reg = "UNUSED",
    	umem_ck_pad.power_up_high = "OFF",
    	umem_ck_pad.width = 1;

	wire mem_ck_temp;

	assign mem_ck_temp = mem_ck[clock_width];

    lpddr2_example_if0_p0_clock_pair_generator    uclk_generator(
        .datain     (mem_ck_temp),
        .dataout    (phy_mem_ck[clock_width]),
        .dataout_b  (phy_mem_ck_n[clock_width])
    );
	end
endgenerate


endmodule
