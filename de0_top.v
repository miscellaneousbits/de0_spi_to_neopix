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
	inout [12:0] GPIO_2,
	input  [2:0] GPIO_2_IN,
	inout [33:0] GPIO_0,
	input  [1:0] GPIO_0_IN,
	inout [33:0] GPIO_1,
	input  [1:0] GPIO_1_IN 
);

parameter NUM_LEDS = 256;

assign GPIO_0[1] = 1'bz;
assign GPIO_0[2] = 1'bz;
assign GPIO_2 = 'bz;
assign GPIO_1 = 'bz;
assign GPIO_0[33:5] = 'bz;

wire sck = GPIO_0_IN[0];
wire mosi = GPIO_0_IN[1];
wire miso = GPIO_0[0];
wire sel0 = GPIO_0[1];
wire sel1 = GPIO_0[2];
wire do0 = GPIO_0[3];
wire do1 = GPIO_0[4];

assign miso = 1;

localparam RESET_CLKS = 63;
reg [$clog2(RESET_CLKS + 1) - 1:0] clk_count = 0;
assign LED[6:2] = 0;
assign LED[7] = 1;

reg [1:0] led = 0;
assign LED[1:0] = led;

wire reset = ~KEY[0] || (clk_count < RESET_CLKS);

always @ (posedge CLOCK_50) begin
	led[0] <= sel0;
	led[1] <= sel1;
	if (clk_count < RESET_CLKS)
		clk_count <= clk_count + 1'b1;
end


spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS)
	)
neo0 (
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(sck),
	.MOSI(mosi),
	.SSEL(sel0),
	.DO(do0)
);


spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS)
	)
neo1 (
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(sck),
	.MOSI(mosi),
	.SSEL(sel1),
	.DO(do1)
);


endmodule

