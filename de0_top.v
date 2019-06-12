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

// Pixel strip bitstream and spi miso outputs
wire do0, do1, miso;

// Assign outputs
assign LED[7] = 1; // always on LED
assign GPIO_0[0] = miso;
assign GPIO_0[3] = do0;
assign GPIO_0[4] = do1;

wire [1:0] bsy;

reg [1:0] led_r;

assign LED[1:0] = led_r;
assign LED[3:2] = bsy;
assign LED[4] = bsy[0] | bsy[1];

reg [2:0] init_reset = 3'd7;

wire reset = ~KEY[0] || (init_reset != 0);

reg [1:0] spi_mode;
assign LED[6:5] = spi_mode;

always @ (posedge CLOCK_50) begin
	spi_mode <= 2'b11 ^ SW[1:0];
	led_r = {~sel0, ~sel1};
	if (init_reset)
		init_reset <= init_reset - 1'b1;
end

// LED strip 0 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_0
	(
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(sck),
	.MOSI(mosi),
	.MISO(miso),
	.SSEL(sel0),
	.DO(do0),
	.BUSY(bsy[0]),
	.SPI_MODE(spi_mode)
);


// LED strip 1 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_1
	(
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(sck),
	.MOSI(mosi),
	.MISO(miso),
	.SSEL(sel1),
	.DO(do1),
	.BUSY(bsy[1]),
	.SPI_MODE(spi_mode)
);

endmodule

