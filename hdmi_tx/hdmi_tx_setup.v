`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:51:26 02/18/2016 
// Design Name: 
// Module Name:    hdmi_tx_setup 
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

`define TXSIZE 28  // number of configuration "lines" in txsetup

module hdmi_tx_setup(
	input wire clk,
	input wire reset,
	
	input wire [4:0] address,
	
	output reg [7:0] addr = 8'h00,
	output reg [7:0] register = 8'h00,
	output reg [7:0] value = 8'h00,
	
	output wire [4:0] size
);

reg [23:0] txsetup [`TXSIZE-1:0];
assign size = `TXSIZE - 1;

initial begin
	txsetup [0] = 'h720100;  // Set N Value(6144)
	txsetup [1] = 'h720218;  // Set N Value(6144)
	txsetup [2] = 'h720300;  // Set N Value(6144)
	txsetup [3] = 'h721500;  // Input 444 (RGB or YCrCb) with Separate Syncs
	txsetup [4] = 'h721661;  // 44.1kHz fs, YPrPb 444
	txsetup [5] = 'h721846;  // CSC disabled
	txsetup [6] = 'h724080;  // General Control Packet Enable
	txsetup [7] = 'h724110;  // Power Down control
	txsetup [8] = 'h724848;  // Reverse bus, Data right justified
	txsetup [9] = 'h7248A8;  // Set Dither_mode: 12-to-10 bit
	txsetup [10] = 'h724C06; // 12 bit output
	txsetup [11] = 'h725500; // Set RGB444 in AVinfo Frame
	txsetup [12] = 'h725508; // Set active format Aspect
	txsetup [13] = 'h729620; // HPD Interrupt clear
	txsetup [14] = 'h729803; // ADI required write
	txsetup [15] = 'h729802; // ADI required write
	txsetup [16] = 'h729AE0; // ADI required write
	txsetup [17] = 'h729C30; // ADI required write
	txsetup [18] = 'h729D61; // Set clock divide
	txsetup [19] = 'h72A2A4; // ADI required write
	txsetup [20] = 'h72A3A4; // ADI required write
	txsetup [21] = 'h72AF16; // Set HDMI Mode
	txsetup [22] = 'h72BA60; // No clock delay
	txsetup [23] = 'h72DE9C; // ADI required write
	txsetup [24] = 'h72E0D0; // ADI required write
	txsetup [25] = 'h72E460; // ADI required Write
	txsetup [26] = 'h72F900; // ADI required write
	txsetup [27] = 'h72FA7D; // Nbr of times to search for good phase
end


always @(posedge clk) begin
	if (reset) begin
		addr <= #1 8'h00;
		register <= #1 8'h00;
		value <= #1 8'h00;
	end
	else begin
		addr <= #1 txsetup[address][23:16];
		register <= #1 txsetup[address][15:8];
		value <= #1 txsetup[address][7:0];
	end
end

endmodule
