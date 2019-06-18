// SPI to NeoPixel protocol converter

module spi_to_neopix(
	input			clk_i,
	input			reset_i,
	input			sck_i,
	input			mosi_i,
	output		miso_o,
	input			ssel_i,
	output		do_o,
	output		ws_bsy_o,
	input	[1:0]	spi_mode_i
);

parameter NUM_LEDS = 8;
parameter SYSTEM_CLOCK = 50000000;

localparam SPI_STATE_IDLE = 0;
localparam SPI_STATE_BUSY = 1;

wire [$clog2(NUM_LEDS):0]		bank_0_offset_w = 1'b0;
wire [$clog2(NUM_LEDS):0]		bank_1_offset_w = NUM_LEDS[$clog2(NUM_LEDS):0];

reg [$clog2(NUM_LEDS) - 1:0]	led_count_r[0:1];

reg [$clog2(NUM_LEDS) - 1:0]	spi_addr_r = 0;
reg [$clog2(NUM_LEDS) - 1:0]	spi_addr_dly_r = 0;
reg [1:0]							spi_byte_index_r;
reg									spi_bank_r = 0;
reg [1:0]							spi_ssel_r = 2'b11;
reg [23:0]							spi_word_r;
reg [1:0]							spi_state_r = SPI_STATE_IDLE;

wire [7:0]							spi_data_w;
wire									spi_ready_r;
wire [$clog2(NUM_LEDS):0]		spi_banked_addr_w = spi_addr_dly_r + (spi_bank_r ? bank_1_offset_w : bank_0_offset_w);

reg [7:0]							ws_red_r, ws_green_r, ws_blue_r;
reg									ws_bank_r;
wire									ws_data_req_w;
wire [$clog2(NUM_LEDS) - 1:0] ws_addr_w;
wire [$clog2(NUM_LEDS):0]		ws_banked_addr_w = ws_addr_w + (ws_bank_r ? bank_1_offset_w : bank_0_offset_w);

reg									wren_r = 0;

wire [31:0] q_w;

dpram dpram_inst_0(
	.clock(clk_i),
	.data({8'd0, spi_word_r}),
	.rdaddress(ws_banked_addr_w),
	.wraddress(spi_banked_addr_w),
	.wren(wren_r),
	.q(q_w));

SPI_slave SPI_slave_inst_0 (
	.clk_i		(clk_i),
	.reset_i		(reset_i),
	.sck_i		(sck_i), 
	.mosi_i		(mosi_i),
	.miso_o		(miso_o),
	.ssel_i		(ssel_i), 
	.data_o		(spi_data_w), 
	.ready_o 	(spi_ready_r),
	.spi_mode_i	(spi_mode_i)
	);
	
always @ (posedge clk_i) begin
	if (reset_i) begin
		spi_addr_r <= 0;
		spi_addr_dly_r <= 0;
		spi_bank_r <= 0;
		spi_ssel_r <= 2'b11;
		wren_r <= 0;
		spi_state_r <= SPI_STATE_IDLE;
	end
	else begin
		spi_addr_dly_r <= spi_addr_r;
		spi_ssel_r <= {spi_ssel_r[0], ssel_i};
		if (wren_r)
			wren_r <= 0;
		if (spi_state_r == SPI_STATE_IDLE) begin
			if (spi_ssel_r == 2'b10) begin
				spi_addr_r <= 0;
				spi_byte_index_r <= 0;
				led_count_r[~spi_bank_r] = 0;
				spi_state_r <= SPI_STATE_BUSY;
				spi_bank_r <= ~spi_bank_r;
			end
		end
		else /* if (spi_state_r == SPI_STATE_BUSY) */ begin
			if (spi_ssel_r == 2'b01) begin
				spi_state_r <= SPI_STATE_IDLE;
			end				
			if (spi_ready_r && (spi_addr_r < NUM_LEDS)) begin
				case (spi_byte_index_r)
					0: begin
						spi_byte_index_r <= 1;
						spi_word_r[23:16] <= spi_data_w;
					end
					1: begin
						spi_byte_index_r <= 2;
						spi_word_r[15:8] <= spi_data_w;
					end
					2: begin
						spi_word_r[7:0] <= spi_data_w;
						wren_r <= 1;
						spi_byte_index_r <= 0;
						spi_addr_r <= spi_addr_r + 1'b1;
						led_count_r[spi_bank_r] <= spi_addr_r + 1'b1;
					end
				endcase
			end
		end
	end
end

ws2812 #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
ws2812_inst_0 (
	.clk_i			(clk_i),
	.reset_i			(reset_i),
	.start_i			(spi_ssel_r == 2'b01),
	.busy_o			(ws_bsy_o),
	.data_request_o(ws_data_req_w),
	.address_o		(ws_addr_w),				// The current LED number. This signal is incremented to the next
														// value two cycles after the last time data_request was asserted.
	.red_i			(ws_red_r),					// 8-bit red data
	.green_i			(ws_green_r),				// 8-bit green data
	.blue_i			(ws_blue_r),				// 8-bit blue data
	.do_o			   (do_o),						// Signal to send to WS2811 chain.
	.led_count_i	(led_count_r[ws_bank_r])// ACTUAL NUMBER OF LEDs
	);

always @ (posedge clk_i) begin
	if (reset_i)
		ws_bank_r <= 1;
	else begin
		if (~ws_bsy_o)
			ws_bank_r <= spi_bank_r;
		if (ws_data_req_w) begin
			ws_green_r <= q_w[23:16];
			ws_red_r <= q_w[15:8];
			ws_blue_r <= q_w[7:0];
		end
	end
end

endmodule

