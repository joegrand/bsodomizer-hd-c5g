`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:51:26 02/18/2016 
// Design Name: 
// Module Name:    hdmi_rx_setup 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

`define RXSIZE 51  // number of configuration "lines" in rxsetup

module hdmi_rx_setup(
	input wire clk,
	input wire reset,
	
	input wire [4:0] address,
	
	output reg [7:0] addr = 8'h00,
	output reg [7:0] register = 8'h00,
	output reg [7:0] value = 8'h00,
	
	output wire [4:0] size
);

reg [23:0] rxsetup [`RXSIZE-1:0];
assign size = `RXSIZE - 1;

initial begin
	rxsetup [0] = 'h98F480;  // CEC Map I2C address
	rxsetup [1] = 'h98F57C;  // INFOFRAME Map I2C address
	rxsetup [2] = 'h98F84C;  // DPLL Map I2C address
	rxsetup [3] = 'h98F964;  // KSV Map I2C address
	rxsetup [4] = 'h98FA6C;  // EDID Map I2C address
	rxsetup [5] = 'h98FB68;  // HDMI Map I2C address
	rxsetup [6] = 'h98FD44;  // CP Map I2C address
	rxsetup [7] = 'h647700;  // Disable the Internal EDID
	rxsetup [8] = 'h446c00;  // ADI required setting (ADV7611 Recommended Register Settings table 2.1)
	rxsetup [9] = 'h647700;  // Set the Most Significant Bit of the SPA location to 0
	rxsetup [10] = 'h645220;  // Set the SPA for port B.
	rxsetup [11] = 'h645300;  // Set the SPA for port B.
	rxsetup [12] = 'h64709E;  // Set the Least Significant Byte of the SPA location
	rxsetup [13] = 'h647403;  // Enable the Internal EDID for Ports
	rxsetup [14] = 'h980106;  // Prim_Mode =110b HDMI-GR
	rxsetup [15] = 'h9802F2;  // Auto CSC, YCrCb out, Set op_656 bit
	rxsetup [16] = 'h980340;  // 24 bit SDR 444 Mode 0 
	rxsetup [17] = 'h980528;  // AV Codes Off
	rxsetup [18] = 'h980B44;  // Power up part
	rxsetup [19] = 'h980C42;  // Power up part
	rxsetup [20] = 'h981455;  // Min Drive Strength
	rxsetup [21] = 'h981580;  // Disable Tristate of Pins
	rxsetup [22] = 'h981985;  // LLC DLL phase
	rxsetup [23] = 'h983340;  // LLC DLL enable
	rxsetup [24] = 'h44BA01;  // Set HDMI FreeRun
	rxsetup [25] = 'h644081;  // Disable HDCP 1.1 features
	rxsetup [26] = 'h689B03;  // ADI recommended setting
	rxsetup [27] = 'h68C101;  // ADI recommended setting
	rxsetup [28] = 'h68C201;  // ADI recommended setting
	rxsetup [29] = 'h68C301;  // ADI recommended setting
	rxsetup [30] = 'h68C401;  // ADI recommended setting
	rxsetup [31] = 'h68C501;  // ADI recommended setting
	rxsetup [32] = 'h68C601;  // ADI recommended setting
	rxsetup [33] = 'h68C701;  // ADI recommended setting
	rxsetup [34] = 'h68C801;  // ADI recommended setting
	rxsetup [35] = 'h68C901;  // ADI recommended setting
	rxsetup [36] = 'h68CA01;  // ADI recommended setting
	rxsetup [37] = 'h68CB01;  // ADI recommended setting
	rxsetup [38] = 'h68CC01;  // ADI recommended setting
	rxsetup [39] = 'h680000;  // Set HDMI Input Port A
	rxsetup [40] = 'h6883FE;  // Enable clock terminator for port A
	rxsetup [41] = 'h686F0C;  // ADI recommended setting
	rxsetup [42] = 'h68851F;  // ADI recommended setting
	rxsetup [43] = 'h688770;  // ADI recommended setting
	rxsetup [44] = 'h688D04;  // LFG
	rxsetup [45] = 'h688E1E;  // HFG
	rxsetup [46] = 'h681A8A;  // unmute audio
	rxsetup [47] = 'h6857DA;  // ADI recommended setting
	rxsetup [48] = 'h685801;  // ADI recommended setting
	rxsetup [49] = 'h687510;  // DDC drive strength
	rxsetup [50] = 'h9840E2;  // INT1 active high, active until cleared
end

always @(posedge clk) begin
	if (reset) begin
		addr <= #1 8'h00;
		register <= #1 8'h00;
		value <= #1 8'h00;
	end
	else begin
		addr <= #1 rxsetup[address][23:16];
		register <= #1 rxsetup[address][15:8];
		value <= #1 rxsetup[address][7:0];
	end
end

endmodule
