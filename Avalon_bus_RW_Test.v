module Avalon_bus_RW_Test (

		iCLK,
		iRST_n,
		iBUTTON,

		local_init_done,
		avl_waitrequest_n,                 
		avl_address,                                        
		avl_writedata,                     
		avl_write,    
		avl_burstbegin,
		
		drv_status_test_complete,
		
		c_state
);

parameter      ADDR_W             =     27;
parameter      DATA_W             =     32;

input          iCLK;
input          iRST_n;
input          iBUTTON;

input				local_init_done;
input          avl_waitrequest_n;     //  avl.waitrequest_n
output [ADDR_W-1:0]  avl_address;     //     .address
output [DATA_W-1:0] avl_writedata;    //     .writedata
output         avl_write;             //     .write

output		drv_status_test_complete;

output			avl_burstbegin;
output	[3:0]c_state;		

//=======================================================
//  Signal declarations
//=======================================================
reg  [1:0]           pre_button;
reg                  trigger;
wire [DATA_W-1:0]    y;	
reg  [3:0]           c_state;		
reg	                avl_write;
reg	 [ADDR_W-1:0]   avl_address;  	
reg	 [DATA_W-1:0]   avl_writedata;
reg  [4:0]   write_count;


//=======================================================
//  Structural coding
//=======================================================
assign avl_burstbegin = avl_write;
		
always@(posedge iCLK or negedge iRST_n)
begin
	if (!iRST_n)
	begin 
		pre_button <= 2'b11;
		trigger <= 1'b0;
		c_state <= 4'b0;
		avl_write <= 1'b0;
		//write_count <= 5'b0;
	end
	else
	begin
		pre_button <= {pre_button[0], iBUTTON};
		trigger <= !pre_button[0] && pre_button[1];

	  case (c_state)
	  	0 : begin //idle
	  		avl_address <= {ADDR_W{1'b0}};
	  		if (local_init_done && trigger)
	  			c_state <= 1;
	  	end
	  	1 : begin //write
			if (avl_address < ('d1920 * 'd1080) / 2)  // sdc set multi-cycle 3
				avl_writedata <= 32'h0055AA55;
			else
				avl_writedata <= 32'h00BB6666;
				
			//avl_writedata <= avl_address;
			//if (write_count[3])
	  		//begin
	  		//	write_count <= 5'b0;
			   avl_write <= 1'b1;
				c_state <= 2;
			//end
			//else
			//  	write_count <= write_count + 1'b1;
	  	end
	  	2 : begin //finish write one data
	  		if (avl_waitrequest_n)
	  		begin
	  			avl_write <= 1'b0;
	  			c_state <= 3;
	  		end
	  	end
	  	3 : begin
	  	  if (avl_address == ('d1920 * 'd1080) - 1) //finish write all(burst) 
	  		begin
	  			avl_address <= {ADDR_W{1'b0}};
	  			c_state <= 9;
	  		end
	  		else //write the next data
	  		begin
	  			avl_address <= avl_address + 1'b1;
	  			c_state <= 1;
	  		end
      end
		9 : c_state <= 9; // done!
	    default : c_state <= 0;
	  endcase
  end
end
		
// test result
assign drv_status_test_complete = (c_state == 9) ? 1 : 0;

endmodule 