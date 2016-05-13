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


// ******************************************************************************************************************************** 
// Filename: afi_mux.v
// This module contains a set of muxes between the sequencer AFI signals and the controller AFI signals
// During calibration, mux_sel = 1, sequencer AFI signals are selected
// After calibration is succesfu, mux_sel = 0, controller AFI signals are selected
// ******************************************************************************************************************************** 

`timescale 1 ps / 1 ps

module afi_mux_lpddr2 (
	clk,
	mux_sel,
	afi_addr,
	afi_cs_n,
	afi_cke,
	afi_dqs_burst,
	afi_dm,
	afi_wlat,
	afi_rlat,
	afi_wdata,
	afi_wdata_valid,
	afi_rdata_en,
	afi_rdata_en_full,
	afi_rdata,
	afi_rdata_valid,
	afi_cal_success,
	afi_cal_fail,
	seq_mux_addr,
	seq_mux_cs_n,
	seq_mux_cke,
	seq_mux_dqs_burst,
	seq_mux_dm,
	seq_mux_wdata,
	seq_mux_wdata_valid,
	seq_mux_rdata_en,
	seq_mux_rdata_en_full,
	seq_mux_rdata,
	seq_mux_rdata_valid,
	phy_mux_addr,
	phy_mux_cs_n,
	phy_mux_cke,
	phy_mux_dqs_burst,
	phy_mux_dm,
	phy_mux_wlat,
	phy_mux_rlat,
	phy_mux_wdata,
	phy_mux_wdata_valid,
	phy_mux_rdata_en,
	phy_mux_rdata_en_full,
	phy_mux_rdata,
	phy_mux_rdata_valid,
	phy_mux_cal_success,
	phy_mux_cal_fail
);


parameter AFI_ADDR_WIDTH            = 0;
parameter AFI_BANKADDR_WIDTH        = 0;
parameter AFI_CS_WIDTH              = 0;
parameter AFI_WLAT_WIDTH            = 0;
parameter AFI_RLAT_WIDTH            = 0;
parameter AFI_DM_WIDTH              = 0;
parameter AFI_CONTROL_WIDTH         = 0;
parameter AFI_DQ_WIDTH              = 0;
parameter AFI_WRITE_DQS_WIDTH       = 0;
parameter AFI_RATE_RATIO            = 0;

parameter MRS_MIRROR_PING_PONG_ATSO = 0;

input clk;

input	mux_sel;


// AFI inputs from the controller
input         [AFI_ADDR_WIDTH-1:0]  afi_addr;
input           [AFI_CS_WIDTH-1:0]  afi_cke;
input           [AFI_CS_WIDTH-1:0]  afi_cs_n;
input	 [AFI_WRITE_DQS_WIDTH-1:0]  afi_dqs_burst;
input           [AFI_DM_WIDTH-1:0]  afi_dm;
output        [AFI_WLAT_WIDTH-1:0]  afi_wlat;
output        [AFI_RLAT_WIDTH-1:0]  afi_rlat;
input           [AFI_DQ_WIDTH-1:0]  afi_wdata;
input    [AFI_WRITE_DQS_WIDTH-1:0]  afi_wdata_valid;
input         [AFI_RATE_RATIO-1:0]  afi_rdata_en;
input         [AFI_RATE_RATIO-1:0]  afi_rdata_en_full;
output	        [AFI_DQ_WIDTH-1:0]  afi_rdata;
output	      [AFI_RATE_RATIO-1:0]  afi_rdata_valid;

output                              afi_cal_success;
output                              afi_cal_fail;

// AFI inputs from the sequencer
input         [AFI_ADDR_WIDTH-1:0]  seq_mux_addr;
input           [AFI_CS_WIDTH-1:0]  seq_mux_cs_n;
input           [AFI_CS_WIDTH-1:0]  seq_mux_cke;
input           [AFI_DM_WIDTH-1:0]  seq_mux_dm;
input    [AFI_WRITE_DQS_WIDTH-1:0]	seq_mux_dqs_burst;
input           [AFI_DQ_WIDTH-1:0]  seq_mux_wdata;
input    [AFI_WRITE_DQS_WIDTH-1:0]	seq_mux_wdata_valid;
input         [AFI_RATE_RATIO-1:0]  seq_mux_rdata_en;
input         [AFI_RATE_RATIO-1:0]  seq_mux_rdata_en_full;
output          [AFI_DQ_WIDTH-1:0]  seq_mux_rdata;
output        [AFI_RATE_RATIO-1:0]  seq_mux_rdata_valid;

// Mux output to the rest of the PHY logic
output        [AFI_ADDR_WIDTH-1:0]  phy_mux_addr;
output          [AFI_CS_WIDTH-1:0]  phy_mux_cs_n;
output          [AFI_CS_WIDTH-1:0]  phy_mux_cke;
output   [AFI_WRITE_DQS_WIDTH-1:0]  phy_mux_dqs_burst;
output          [AFI_DM_WIDTH-1:0]  phy_mux_dm;
input         [AFI_WLAT_WIDTH-1:0]  phy_mux_wlat;
input         [AFI_RLAT_WIDTH-1:0]  phy_mux_rlat;
output          [AFI_DQ_WIDTH-1:0]  phy_mux_wdata;
output   [AFI_WRITE_DQS_WIDTH-1:0]  phy_mux_wdata_valid;
output        [AFI_RATE_RATIO-1:0]  phy_mux_rdata_en;
output        [AFI_RATE_RATIO-1:0]  phy_mux_rdata_en_full;
input           [AFI_DQ_WIDTH-1:0]  phy_mux_rdata;
input         [AFI_RATE_RATIO-1:0]  phy_mux_rdata_valid;

input                               phy_mux_cal_success;
input                               phy_mux_cal_fail;


reg	     [AFI_ADDR_WIDTH-1:0]  afi_addr_r;
reg        [AFI_CS_WIDTH-1:0]  afi_cke_r;
reg        [AFI_CS_WIDTH-1:0]  afi_cs_n_r;

reg	[AFI_ADDR_WIDTH-1:0] seq_mux_addr_r;
reg	[AFI_CS_WIDTH-1:0] seq_mux_cs_n_r;
reg	[AFI_CS_WIDTH-1:0] seq_mux_cke_r;


always @(posedge clk)
begin
	afi_addr_r  <= afi_addr;
	afi_cs_n_r  <= afi_cs_n;
	afi_cke_r   <= afi_cke;

	seq_mux_addr_r <= seq_mux_addr;
	seq_mux_cs_n_r <= seq_mux_cs_n;
	seq_mux_cke_r <= seq_mux_cke;
end


wire [AFI_DQ_WIDTH-1:0] afi_wdata_int;
assign afi_rdata = phy_mux_rdata;
assign afi_wdata_int = afi_wdata;

assign afi_rdata_valid = mux_sel ? {AFI_RATE_RATIO{1'b0}} : phy_mux_rdata_valid;

assign seq_mux_rdata       = phy_mux_rdata;
assign seq_mux_rdata_valid = phy_mux_rdata_valid;

assign phy_mux_addr        = mux_sel ? seq_mux_addr_r : afi_addr_r;
assign phy_mux_cs_n      = mux_sel ? seq_mux_cs_n_r    : afi_cs_n_r;
assign phy_mux_cke       = mux_sel ? seq_mux_cke_r     : afi_cke_r;
assign phy_mux_dqs_burst = mux_sel ? seq_mux_dqs_burst : afi_dqs_burst;
assign phy_mux_dm        = mux_sel ? seq_mux_dm        : afi_dm;
assign afi_wlat = phy_mux_wlat;
assign afi_rlat = phy_mux_rlat;
assign phy_mux_wdata         = mux_sel ? seq_mux_wdata         : afi_wdata_int;
assign phy_mux_wdata_valid   = mux_sel ? seq_mux_wdata_valid   : afi_wdata_valid;
assign phy_mux_rdata_en      = mux_sel ? seq_mux_rdata_en      : afi_rdata_en;
assign phy_mux_rdata_en_full = mux_sel ? seq_mux_rdata_en_full : afi_rdata_en_full;

assign afi_cal_success = phy_mux_cal_success;
assign afi_cal_fail    = phy_mux_cal_fail;

endmodule
