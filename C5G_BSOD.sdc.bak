#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 8.000ns [get_ports CLOCK_125_p]
create_clock -period 20.000ns [get_ports CLOCK_50_B5B]
create_clock -period 20.000ns [get_ports CLOCK_50_B6A]
create_clock -period 20.000ns [get_ports CLOCK_50_B7A]
create_clock -period 20.000ns [get_ports CLOCK_50_B8A]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************
set_false_path -from [get_clocks CLOCK_50_B6A] -to [get_clocks {fpga_lpddr2_inst|fpga_lpddr2_pll0|pll0|pll_config_clk}]
set_false_path -from [get_clocks CLOCK_50_B6A] -to [get_clocks {fpga_lpddr2_inst|fpga_lpddr2_pll0|pll0|pll_afi_half_clk}]
set_false_path -from [get_clocks CLOCK_50_B6A] -to [get_clocks {fpga_lpddr2_inst|fpga_lpddr2_pll0|pll0|pll_avl_clk}]
set_false_path -from [get_clocks CLOCK_50_B6A] -to [get_clocks {fpga_lpddr2_inst|fpga_lpddr2_pll0|pll0|pll_afi_clk}]


#**************************************************************
# Set Multicycle Path
#**************************************************************
set_multicycle_path -from {Avalon_bus_RW_Test:fpga_lpddr2_Verify|avl_address*} -to {Avalon_bus_RW_Test:fpga_lpddr2_Verify|avl_writedata*} -setup -end 6
set_multicycle_path -from {Avalon_bus_RW_Test:fpga_lpddr2_Verify|cal_data*} -to {Avalon_bus_RW_Test:fpga_lpddr2_Verify|avl_writedata*} -setup -end 6

set_multicycle_path -from {Avalon_bus_RW_Test:fpga_lpddr2_Verify|avl_address*} -to {Avalon_bus_RW_Test:fpga_lpddr2_Verify|avl_writedata*} -hold -end 6
set_multicycle_path -from {Avalon_bus_RW_Test:fpga_lpddr2_Verify|cal_data*} -to {Avalon_bus_RW_Test:fpga_lpddr2_Verify|avl_writedata*} -hold -end 6

set_multicycle_path -from {top_sync_vg_pattern:vg|avl_address*} -to {top_sync_vg_pattern:vg|avl_writedata*} -setup -end 6
set_multicycle_path -from {top_sync_vg_pattern:vg|avl_address*} -to {top_sync_vg_pattern:vg|avl_writedata*} -hold -end 6


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



