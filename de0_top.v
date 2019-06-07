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
assign GPIO_2 = 0;
assign GPIO_1 = 0;
assign GPIO_0[33:5] = 0;

`define sck  GPIO_0_IN[0]
`define mosi GPIO_0_IN[1]
`define miso GPIO_0[0]
`define sel0 GPIO_0[1]
`define sel1 GPIO_0[2]
`define do0 GPIO_0[3]
`define do1 GPIO_0[4]

assign `miso = 1;

reg [29:0] clk_count= 0;
assign LED = clk_count[29:22];
localparam RESET_CLKS = 50000000;
reg [$clog2(RESET_CLKS) - 1:0] reset_count = RESET_CLKS;
wire reset = ~KEY[0] || reset_count;


always @ (posedge CLOCK_50) begin
	if (reset)
		clk_count <= 0;
	else
		clk_count <= clk_count + 1'b1;
	if (reset_count)
		reset_count <= reset_count - 1'b1;
end


spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS)
	)
neo0 (
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(`sck),
	.MOSI(`mosi),
	.SSEL(`sel0),
	.DO(`do0)
);


spi_to_neopix #(
	.NUM_LEDS(NUM_LEDS)
	)
neo1 (
	.CLK(CLOCK_50),
	.RESET(reset),
	.SCK(`sck),
	.MOSI(`mosi),
	.SSEL(`sel1),
	.DO(`do1)
);


endmodule

