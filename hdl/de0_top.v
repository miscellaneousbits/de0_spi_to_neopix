// 2 SPI to NeoPixel strip drivers.

// sck_w  IO_0_IN[0]
// mosi_w IO_0_IN[1]
// miso_w IO_0[0]
// ssel0 IO_0[1]
// ssel1 IO_0[2]
// DO0  IO_0[3]
// DO1  IO_0[4]

module de0_top (
	input				CLOCK_50,
	output [7:0]	LED,
	input  [1:0]	KEY,
	input  [3:0]	SW,
	inout [33:0]	GPIO_0,
	input  [1:0]	GPIO_0_IN,
	inout [33:0]	GPIO_1,
	input  [1:0]	GPIO_1_IN, 
	inout [12:0]	GPIO_2,
	input  [2:0]	GPIO_2_IN
	);

localparam NUM_LEDS = 256;
localparam SYSTEM_CLOCK = 50_000_000;

localparam MIN_LED_PULSE_DURATION = SYSTEM_CLOCK / 10;
//localparam MIN_LED_PULSE_DURATION = 20000; // for sim

// Set all unused and input pins to hi-z
assign GPIO_0[1]		= 1'bz;
assign GPIO_0[2]		= 1'bz;
assign GPIO_0[33:5]	= 29'bz;
assign GPIO_1			= 13'bz;
assign GPIO_2			= 13'bz;

reg [2:0] init_reset_r = 3'd7;

// SPI input signals
wire sck_w			= GPIO_0_IN[0];
wire mosi_w			= GPIO_0_IN[1];
wire [1:0] sel_w	= {GPIO_0[2], GPIO_0[1]};

// Pixel strip bitstream output
wire miso_w;

wire reset_w = ~KEY[0] || (init_reset_r != 0);

wire [1:0] do_w, ws_bsy_w, ws_bsy_led_w, spi_bsy_led_w;

// Assign outputs
assign LED[7]			= ~reset_w;
assign LED[6:4]		= 0; // always off
assign LED[3:2]		= ws_bsy_led_w;
assign LED[1:0]		= spi_bsy_led_w;
assign GPIO_0[0]		= miso_w;
assign GPIO_0[4:3]	= do_w;
	
wire sysclk_w = CLOCK_50;

always @ (posedge sysclk_w)
	if (init_reset_r)
		init_reset_r <= init_reset_r - 1'b1;
		
// LED strip 0 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_inst_0 (
	.clk_i	(sysclk_w),
	.reset_i	(reset_w),
	.sck_i	(sck_w),
	.mosi_i	(mosi_w),
	.miso_o	(miso_w),
	.ssel_i	(sel_w[0]),
	.do_o		(do_w[0]),
	.ws_bsy_o(ws_bsy_w[0])
	);


// LED strip 1 controller
spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS),
	.SYSTEM_CLOCK(SYSTEM_CLOCK)
	)
spi_to_neopix_inst_1 (
	.clk_i	(sysclk_w),
	.reset_i	(reset_w),
	.sck_i	(sck_w),
	.mosi_i	(mosi_w),
	.miso_o	(miso_w),
	.ssel_i	(sel_w[1]),
	.do_o		(do_w[1]),
	.ws_bsy_o(ws_bsy_w[1])
	);
	
stretch_pulse #(
	.SYSTEM_CLOCK(SYSTEM_CLOCK),
	.MIN_DURATION(MIN_LED_PULSE_DURATION)
	)
stretch_spi_pulse_inst_0 (
	.clk_i	(sysclk_w),
	.reset_i	(reset_w),
	.in_i		(~sel_w[0]),
	.out_o	(spi_bsy_led_w[0])
	);

stretch_pulse #(
	.SYSTEM_CLOCK(SYSTEM_CLOCK),
	.MIN_DURATION(MIN_LED_PULSE_DURATION)
	)
stretch_spi_pulse_inst_1 (
	.clk_i	(sysclk_w),
	.reset_i	(reset_w),
	.in_i		(~sel_w[1]),
	.out_o	(spi_bsy_led_w[1])
	);

stretch_pulse #(
	.SYSTEM_CLOCK(SYSTEM_CLOCK),
	.MIN_DURATION(MIN_LED_PULSE_DURATION)
	)
stretch_ws_pulse_inst_0 (
	.clk_i	(sysclk_w),
	.reset_i	(reset_w),
	.in_i		(ws_bsy_w[0]),
	.out_o	(ws_bsy_led_w[0])
	);

stretch_pulse #(
	.SYSTEM_CLOCK(SYSTEM_CLOCK),
	.MIN_DURATION(MIN_LED_PULSE_DURATION)
	)
stretch_ws_pulse_inst_1 (
	.clk_i	(sysclk_w),
	.reset_i	(reset_w),
	.in_i		(ws_bsy_w[1]),
	.out_o	(ws_bsy_led_w[1])
	);


endmodule

