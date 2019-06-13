// sck_w  IO_0_IN[0]
// mosi_w IO_0_IN[1]
// miso_w IO_0[0]
// ssel0 IO_0[1]
// ssel1 IO_0[2]
// DO0  IO_0[3]
// DO1  IO_0[4]

module de0_top (
	input CLOCK_50,
	output [7:0] LED,
	input  [1:0] KEY,
	input  [3:0] SW,
	inout [33:0] GPIO_0,
	input  [1:0] GPIO_0_IN,
	inout [33:0] GPIO_1,
	input  [1:0] GPIO_1_IN, 
	inout [12:0] GPIO_2,
	input  [2:0] GPIO_2_IN
);

localparam NUM_LEDS = 256;
localparam SYSTEM_CLOCK = 50000000;

// Set all unused and input pins to hi-z
assign GPIO_0[1] = 1'bz;
assign GPIO_0[2] = 1'bz;
assign GPIO_0[33:5] = 29'bz;
assign GPIO_1 = 'bz;
assign GPIO_2 = 13'bz;

// SPI input signals
wire sck_w = GPIO_0_IN[0];
wire mosi_w = GPIO_0_IN[1];
wire sel0_w = GPIO_0[1];
wire sel1_w = GPIO_0[2];

// Pixel strip bitstream output
wire do0_w, do1_w, miso_w;
reg [1:0] spi_led_r;
reg [1:0] ws_led_r;

// Assign outputs
assign LED[7] = 1; // always on
assign LED[6:4] = 0; // always off
assign LED[3:2] = ws_led_r;
assign LED[1:0] = spi_led_r;
assign GPIO_0[0] = miso_w;
assign GPIO_0[3] = do0_w;
assign GPIO_0[4] = do1_w;

reg [2:0] init_reset_r = 3'd7;

wire reset_w = ~KEY[0] || (init_reset_r != 0);
wire [1:0] ws_bsy_w;

always @ (posedge CLOCK_50) begin
	spi_led_r <= {~sel1_w, ~sel0_w};
	ws_led_r <= ws_bsy_w;
	if (init_reset_r)
		init_reset_r <= init_reset_r - 1'b1;
end

// LED strip 0 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_inst_0
	(
	.clk_i(CLOCK_50),
	.reset_i(reset_w),
	.sck_i(sck_w),
	.mosi_i(mosi_w),
	.miso_o(miso_w),
	.ssel_i(sel0_w),
	.do_o(do0_w),
	.ws_bsy_o(ws_bsy_w[0])
);


// LED strip 1 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_inst_1
	(
	.clk_i(CLOCK_50),
	.reset_i(reset_w),
	.sck_i(sck_w),
	.mosi_i(mosi_w),
	.miso_o(miso_w),
	.ssel_i(sel1_w),
	.do_o(do1_w),
	.ws_bsy_o(ws_bsy_w[1])
);

endmodule

