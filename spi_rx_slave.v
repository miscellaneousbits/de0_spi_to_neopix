module SPI_rx_slave(
   input clk,
	input reset,
   input SCK, SSEL, MOSI,
	output MISO,
   output reg [7:0] DATA,
	output READY
);

// sync SCK to the FPGA clock using a 3-bits shift register
reg [2:0] SCKr;
wire SCK_risingedge = (SCKr[2:1]==2'b01);
wire SCK_fallingedge = (SCKr[2:1]==2'b10);

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
reg [1:0] data_ready = 0;

// we use the LSB of the data received to control an LED
assign READY = data_ready[1];

always @(posedge clk) begin
	if (reset) begin
		data_ready <= 0;
		SCKr <= 0;
		SSELr <= 3'b111;
		MOSIr <= 0;
	end
	else begin
		SCKr <= {SCKr[1:0], SCK};
		SSELr <= {SSELr[1:0], SSEL};
		MOSIr <= {MOSIr[0], MOSI};
		byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'd7);
		if(~SSEL_active)
			bitcnt <= 0;
		else if(SCK_risingedge) begin
			bitcnt <= bitcnt + 1'b1;
			// We receive the data MSB first
			byte_data_received <= {byte_data_received[6:0], MOSI_data};
		end
		if(byte_received)
			DATA <= byte_data_received;
		data_ready <= {data_ready[0], byte_received};
	end
end

reg [7:0] byte_data_sent;

reg [7:0] cnt;
wire SSEL_startmessage = (SSELr[2:1]==2'b10);
assign MISO = SSEL_active ? byte_data_sent[7] : 1'bz;

always @(posedge clk) begin
	if(SSEL_active)
	begin
		if (~reset) begin
			if(SSEL_startmessage)
				cnt<=cnt + 1'b1;
			if(SSEL_startmessage)
				byte_data_sent <= 0;  // first byte sent in a message is the message count
			else if(SCK_fallingedge) begin
				if(bitcnt==3'b0)
					byte_data_sent <= byte_data_received;  // after that, we send 0s
				else
					byte_data_sent <= {byte_data_sent[6:0], 1'b0};
			end
		end
	end
end


endmodule

