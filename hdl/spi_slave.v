// SPI slave protocol with echo

module SPI_slave(
	input				clk_i,
	input				reset_i,
	input				sck_i, ssel_i, mosi_i,
	output			miso_o,
	output [7:0]	data_o,
	output			ready_o,
	input [1:0]		spi_mode_i
);

wire sclk_w = sck_i ^ spi_mode_i[1];

// sync sck_i to the FPGA clock using a 3-bits shift register
reg [2:0] sck_r = 0;
wire sck_risingedge_w = (sck_r[2:1] == {spi_mode_i[0], ~spi_mode_i[0]});
wire sck_fallingedge_w = (sck_r[2:1] == {~spi_mode_i[0], spi_mode_i[0]});

// same thing for ssel_i
reg [2:0] ssel_r = 3'b111;
wire ssel_active_w = ~ssel_r[1];  // ssel_i is active low

// and for mosi_i
reg [1:0] mosi_r = 0;

// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
reg [2:0] bitcnt_r;

reg byte_received_r;  // high when a byte has been received
reg [7:0] byte_data_received_r;
reg [1:0] data_ready_r = 0;
reg [7:0] data_r;

// we use the LSB of the data received to control an LED
assign ready_o = data_ready_r[1];
assign data_o = data_r;

always @(posedge clk_i) begin
	if (reset_i) begin
		data_ready_r <= 0;
		sck_r <= 0;
		ssel_r <= 3'b111;
		mosi_r <= 0;
	end
	else begin
		sck_r <= {sck_r[1:0], sclk_w};
		ssel_r <= {ssel_r[1:0], ssel_i};
		mosi_r <= {mosi_r[0], mosi_i};
		byte_received_r <= ssel_active_w && sck_risingedge_w && (bitcnt_r==3'd7);
		if(~ssel_active_w)
			bitcnt_r <= 0;
		else if(sck_risingedge_w) begin
			bitcnt_r <= bitcnt_r + 1'b1;
			// We receive the data MSB first
			byte_data_received_r <= {byte_data_received_r[6:0], mosi_r[1]};
		end
		if(byte_received_r)
			data_r <= byte_data_received_r;
		data_ready_r <= {data_ready_r[0], byte_received_r};
	end
end

reg [7:0] byte_data_sent_r;
reg [7:0] cnt_r;

wire ssel_start_w = (ssel_r[2:1]==2'b10);

assign miso_o = ssel_active_w ? byte_data_sent_r[7] : 1'bz;

always @(posedge clk_i) begin
	if(ssel_active_w)
	begin
		if (~reset_i) begin
			if(ssel_start_w)
				cnt_r<=cnt_r + 1'b1;
			if(ssel_start_w)
				byte_data_sent_r <= 0;  // first byte sent in a message is the message count
			else if(sck_fallingedge_w) begin
				if(bitcnt_r==3'b0)
					byte_data_sent_r <= byte_data_received_r; // echo received data
				else
					byte_data_sent_r <= {byte_data_sent_r[6:0], 1'b0};
			end
		end
	end
end

endmodule

