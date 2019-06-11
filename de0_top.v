// sck  IO_0_IN[0]
// mosi IO_0_IN[1]
// miso IO_0[0]
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

parameter NUM_LEDS = 256;
parameter SYSTEM_CLOCK = 50000000;
parameter MIN_LED_PULSE = SYSTEM_CLOCK / 8;

// Set all unused and input pins to hi-z
assign GPIO_0[1] = 1'bz;
assign GPIO_0[2] = 1'bz;
assign GPIO_0[33:5] = 29'bz;
assign GPIO_1 = 'bz;
assign GPIO_2 = 13'bz;

// SPI input signals
wire sck = GPIO_0_IN[0];
wire mosi = GPIO_0_IN[1];
wire sel0 = GPIO_0[1];
wire sel1 = GPIO_0[2];

// Pixel strip bitstream output
wire do0, do1, miso;

// Assign outputs
assign LED[7] = 1;
assign LED[6:2] = 0;
assign GPIO_0[0] = miso;
assign GPIO_0[3] = do0;
assign GPIO_0[4] = do1;

reg [2:0] init_reset = 3'd7;

wire reset = ~KEY[0] || (init_reset != 0);

always @ (posedge CLOCK_50)
	if (init_reset)
		init_reset <= init_reset - 1'b1;

// Stretch LED activity indicators
stretch #(
	.MIN_DURATION(MIN_LED_PULSE),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
stretch_inst_0 (
	.clk(CLOCK_50),
	.reset(reset),
	.in(~sel0),
	.out(LED[0])
	);

stretch #(
	.MIN_DURATION(MIN_LED_PULSE),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
stretch_inst_1 (
	.clk(CLOCK_50),
	.reset(reset),
	.in(~sel1),
	.out(LED[1])
	);

// LED strip 0 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_inst_0
	(
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(sck),
	.MOSI(mosi),
	.MISO(miso),
	.SSEL(sel0),
	.DO(do0)
);


// LED strip 1 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_inst_1
	(
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(sck),
	.MOSI(mosi),
	.MISO(miso),
	.SSEL(sel1),
	.DO(do1)
);

endmodule

