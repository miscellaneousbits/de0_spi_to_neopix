module SPI_rx_slave(clk, reset, SCK, MOSI, SSEL, DATA, READY);

   input clk, reset;

   input SCK, SSEL, MOSI;

   output [7:0] DATA;
	output READY;

   // sync SCK to the FPGA clock using a 3-bits shift register
   reg [2:0] SCKr;
   wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges

   // same thing for SSEL
   reg [2:0] SSELr; 
   wire SSEL_active = ~SSELr[1];  // SSEL is active low
	
   // and for MOSI
   reg [1:0] MOSIr;
   wire MOSI_data = MOSIr[1];
	
   // we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
   reg [2:0] bitcnt;

   reg byte_received;  // high when a byte has been received
   reg [7:0] byte_data_received;
	reg [1:0] data_ready;

   // we use the LSB of the data received to control an LED
   reg [7:0] data;
	assign DATA = data;
	assign READY = data_ready[1];
	
   always @(posedge clk) begin
	  SCKr <= {SCKr[1:0], SCK};
	  SSELr <= {SSELr[1:0], SSEL};
	  MOSIr <= {MOSIr[0], MOSI};
	  if (reset) begin
		  data_ready <= 0;
		  bitcnt <= 0;
		  SCKr <= 0;
		  SSELr <= 0;
		  MOSIr <= 0;
	  end
	  else begin
		  byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);
		  if(~SSEL_active)
			 bitcnt <= 0;
		  else if(SCK_risingedge) begin
			 bitcnt <= bitcnt + 1'b1;
			 // implement a shift-left register (since we receive the data MSB first)
			 byte_data_received <= {byte_data_received[6:0], MOSI_data};
		  end
		  if(byte_received)
			 data <= byte_data_received;
		  data_ready <= {data_ready[0], byte_received};
	  end
   end

endmodule

