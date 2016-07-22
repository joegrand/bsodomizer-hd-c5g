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


`timescale 1ps/1ps

module altera_mem_if_single_clock_pll (pll_ref_clk, global_reset_n, pll_locked, reset_out_n, pll_clk);

	input pll_ref_clk;
	input global_reset_n;
	output pll_locked;
	output reset_out_n;
	output pll_clk;
	
	
	parameter DEVICE_FAMILY = "STRATIXV";
	parameter USE_GENERIC_PLL = 1;
	parameter REF_CLK_FREQ_STR = "100 MHz";
	parameter PLL_CLK_FREQ_STR = "100 MHz";
	
	parameter PLL_CLK_DIV = 1;
	parameter PLL_CLK_MULT = 1;
	parameter PLL_CLK_PHASE_PS = 0;
	parameter REF_CLK_PS = "10000";
	
	wire reset_out_n ;
	assign reset_out_n = pll_locked;

	generate
		if (USE_GENERIC_PLL) begin
			wire fbout;
	
			generic_pll pll1 (
				.refclk({pll_ref_clk}),
				.rst(~global_reset_n),
				.fbclk(fbout),
				.outclk(pll_clk),
				.fboutclk(fbout),
				.locked(pll_locked)
			);	
			defparam pll1.reference_clock_frequency = REF_CLK_FREQ_STR,
				pll1.output_clock_frequency = PLL_CLK_FREQ_STR,
				pll1.phase_shift = 0,
				pll1.duty_cycle = 50;
		end
		
		else begin
			wire [9:0] pll_clocks;
		
			assign pll_clk = pll_clocks[0];
			
			altpll	altpll_component (
						.areset (~global_reset_n),
						.inclk (pll_ref_clk),
						.locked (pll_locked),
						.clk (pll_clocks),
						.activeclock (),
						.clkbad (),
						.clkena ({6{1'b1}}),
						.clkloss (),
						.clkswitch (1'b0),
						.configupdate (1'b0),
						.enable0 (),
						.enable1 (),
						.extclk (),
						.extclkena ({4{1'b1}}),
						.fbin (1'b1),
						.fbmimicbidir (),
						.fbout (),
						.fref (),
						.icdrclk (),
						.pfdena (1'b1),
						.phasecounterselect ({4{1'b1}}),
						.phasedone (),
						.phasestep (1'b1),
						.phaseupdown (1'b1),
						.pllena (1'b1),
						.scanaclr (1'b0),
						.scanclk (1'b0),
						.scanclkena (1'b1),
						.scandata (1'b0),
						.scandataout (),
						.scandone (),
						.scanread (1'b0),
						.scanwrite (1'b0),
						.sclkout0 (),
						.sclkout1 (),
						.vcooverrange (),
						.vcounderrange ());
			defparam
				altpll_component.bandwidth_type = "AUTO",
				altpll_component.clk0_divide_by = PLL_CLK_DIV,
				altpll_component.clk0_duty_cycle = 50,
				altpll_component.clk0_multiply_by = PLL_CLK_MULT,
				altpll_component.clk0_phase_shift = PLL_CLK_PHASE_PS,
				altpll_component.compensate_clock = "CLK0",
				altpll_component.inclk0_input_frequency = REF_CLK_PS,
				altpll_component.intended_device_family = DEVICE_FAMILY,
				altpll_component.lpm_type = "altpll",
				altpll_component.operation_mode = "NORMAL",
				altpll_component.pll_type = "AUTO",
				altpll_component.port_activeclock = "PORT_UNUSED",
				altpll_component.port_areset = "PORT_USED",
				altpll_component.port_clkbad0 = "PORT_UNUSED",
				altpll_component.port_clkbad1 = "PORT_UNUSED",
				altpll_component.port_clkloss = "PORT_UNUSED",
				altpll_component.port_clkswitch = "PORT_UNUSED",
				altpll_component.port_configupdate = "PORT_UNUSED",
				altpll_component.port_fbin = "PORT_UNUSED",
				altpll_component.port_fbout = "PORT_UNUSED",
				altpll_component.port_inclk0 = "PORT_USED",
				altpll_component.port_inclk1 = "PORT_UNUSED",
				altpll_component.port_locked = "PORT_USED",
				altpll_component.port_pfdena = "PORT_UNUSED",
				altpll_component.port_phasecounterselect = "PORT_UNUSED",
				altpll_component.port_phasedone = "PORT_UNUSED",
				altpll_component.port_phasestep = "PORT_UNUSED",
				altpll_component.port_phaseupdown = "PORT_UNUSED",
				altpll_component.port_pllena = "PORT_UNUSED",
				altpll_component.port_scanaclr = "PORT_UNUSED",
				altpll_component.port_scanclk = "PORT_UNUSED",
				altpll_component.port_scanclkena = "PORT_UNUSED",
				altpll_component.port_scandata = "PORT_UNUSED",
				altpll_component.port_scandataout = "PORT_UNUSED",
				altpll_component.port_scandone = "PORT_UNUSED",
				altpll_component.port_scanread = "PORT_UNUSED",
				altpll_component.port_scanwrite = "PORT_UNUSED",
				altpll_component.port_clk0 = "PORT_USED",
				altpll_component.port_clk1 = "PORT_UNUSED",
				altpll_component.port_clk2 = "PORT_UNUSED",
				altpll_component.port_clk3 = "PORT_UNUSED",
				altpll_component.port_clk4 = "PORT_UNUSED",
				altpll_component.port_clk5 = "PORT_UNUSED",
				altpll_component.port_clk6 = "PORT_UNUSED",
				altpll_component.port_clk7 = "PORT_UNUSED",
				altpll_component.port_clk8 = "PORT_UNUSED",
				altpll_component.port_clk9 = "PORT_UNUSED",
				altpll_component.port_clkena0 = "PORT_UNUSED",
				altpll_component.port_clkena1 = "PORT_UNUSED",
				altpll_component.port_clkena2 = "PORT_UNUSED",
				altpll_component.port_clkena3 = "PORT_UNUSED",
				altpll_component.port_clkena4 = "PORT_UNUSED",
				altpll_component.port_clkena5 = "PORT_UNUSED",
				altpll_component.self_reset_on_loss_lock = "OFF",
				altpll_component.using_fbmimicbidir_port = "OFF",
				altpll_component.width_clock = 10;
			end
	
	endgenerate

endmodule
