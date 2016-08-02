`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:59:22 02/16/2016 
// Design Name: 
// Module Name:    receiver_ctrl 
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


module hdmi_rx_ctrl(
	input wire clk,
	input wire reset,
	
	inout wire scl,
	inout wire sda
);

reg ready = 0;
reg [23:0] startup_delay = 0;

always @(posedge clk) begin
	if (reset) begin
		ready <= #1 0;
		startup_delay <= #1 0;
	end
	else begin
		if (!ready) begin
			startup_delay <= #1 startup_delay + 1;
			if (startup_delay == 24'd10000000)
				ready <= #1 1'b1;
		end
	end
end

reg [4:0] i2c_ctrl = 5'b00000;

wire i2c_start;
wire i2c_stop;
wire i2c_read;
wire i2c_write;
wire i2c_ack_out;

assign i2c_start   = i2c_ctrl[4];
assign i2c_stop    = i2c_ctrl[3];
assign i2c_read    = i2c_ctrl[2];
assign i2c_write   = i2c_ctrl[1];
assign i2c_ack_out = i2c_ctrl[0];

reg  [7:0] i2c_dout = 0;

wire i2c_done;
wire i2c_ack_in;

wire [7:0] i2c_din;
reg  [7:0] last_i2c_in;

wire i2c_al;

wire scl_pad_i;
wire scl_pad_o;
wire scl_padoen_oe;
wire sda_pad_i;
wire sda_pad_o;
wire sda_padoen_oe;

assign scl = scl_padoen_oe ? 1'bz : scl_pad_o;
assign sda = sda_padoen_oe ? 1'bz : sda_pad_o;
assign scl_pad_i = scl;
assign sda_pad_i = sda;

i2c_master_byte_ctrl i2c_controller (
	.clk(clk),
	.rst(1'b0),
	.nReset(1'b1),
	
	.ena(1'b1),
	.clk_cnt(5'h18),
	
	.start(i2c_start),
	.stop(i2c_stop),
	.read(i2c_read),
	.write(i2c_write),
	.ack_in(i2c_ack_out),
	
	.din(i2c_dout),
	
	.cmd_ack(i2c_done),
	.ack_out(i2c_ack_in),
	
	.dout(i2c_din),
	
	.i2c_busy(),
	.i2c_al(i2c_al),
	
	.scl_i(scl_pad_i),
	.scl_o(scl_pad_o),
	.scl_oen(scl_padoen_oe),
	
	.sda_i(sda_pad_i),
	.sda_o(sda_pad_o),
	.sda_oen(sda_padoen_oe)
);

localparam I2C_NOP = 0,
I2C_START = 1,
I2C_WRITE = 2,
I2C_WRITE_LAST = 3,
I2C_READ = 4,
I2C_READ_LAST = 5;

reg [2:0] i2c_command = 0;

always @(posedge clk) begin
	if (reset) begin
		i2c_ctrl <= #1 5'h0;
	end
	else begin
		if (i2c_done | i2c_al)
			i2c_ctrl <= 5'h0;
		else
			case (i2c_command)
					I2C_NOP:        i2c_ctrl <= #1 5'b00000;
					I2C_START:      i2c_ctrl <= #1 5'b10010;
					I2C_WRITE:      i2c_ctrl <= #1 5'b00010;
					I2C_WRITE_LAST: i2c_ctrl <= #1 5'b01010;
					I2C_READ:       i2c_ctrl <= #1 5'b00100;
					I2C_READ_LAST:  i2c_ctrl <= #1 5'b01101;
			endcase
	end
end

reg [4:0] setupaddr = 0;

wire [7:0] i2c_address;
wire [7:0] i2c_register;
wire [7:0] i2c_value;
wire [4:0] setupsize;

hdmi_rx_setup setupmem (
	.clk(clk),
	.reset(reset),
	
	.address(setupaddr),
	
	.addr(i2c_address),
	.register(i2c_register),
	.value(i2c_value),
	
	.size(setupsize)
);

localparam IDLE = 0,
STARTUP = 1;

reg [2:0] ctrlstate = IDLE;
reg [3:0] ctrlstep = 0;

reg [1:0] startupstep = 0;

always @(posedge clk) begin
	if (reset) begin
		i2c_command <= #1 3'h0;
		ctrlstate <= #1 IDLE;
		ctrlstep <= #1 0;
		setupaddr <= #1 0;
		startupstep <= #1 0;
	end
	else begin
		if (ready)
			case (ctrlstate)
			
				IDLE: begin
				end

				STARTUP: begin
						case (ctrlstep)
							0: begin
								setupaddr <= #1 0;
								ctrlstep <= #1 1;
							end
							1: begin
								i2c_dout <= #1 i2c_address;
								i2c_command <= #1 I2C_START;
								if (i2c_done) begin
									i2c_command <= #1 I2C_WRITE;
									ctrlstep <= #1 2;
								end
							end
							2: begin
								i2c_dout <= #1 i2c_register;
								if (i2c_done) begin
									i2c_command <= #1 I2C_WRITE_LAST;
									ctrlstep <= #1 3;
								end
							end
							3: begin
								i2c_dout <= #1 i2c_value;
								if (i2c_done) begin
									i2c_command <= #1 I2C_NOP;
									ctrlstep <= #1 4;
								end
							end
							4: begin
								if (setupaddr < setupsize) begin
									setupaddr <= #1 setupaddr + 1;
									ctrlstep <= #1 1;
								end
								else begin
									ctrlstate <= #1 IDLE;
									ctrlstep <= #1 0;
								end
							end
						endcase
				end
			endcase
	end
end

endmodule
