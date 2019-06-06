// sck  IO_0_IN[0]
// mosi IO_0_IN[1]
// miso IO_0[0]
// ssel IO_0[2]
// DO   IO_0[1]

module de0_spi_to_neopix(

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


reg [7:0] led = 8'hff;
assign LED = led;

//=======================================================
//  REG/WIRE declarations
//=======================================================

localparam NUM_LEDS = 8;

reg [7:0] led_colors0[0:(NUM_LEDS * 3) - 1];
reg [7:0] led_colors1[0:(NUM_LEDS * 3) - 1];
reg [$clog2(NUM_LEDS * 3) - 1:0] led_color_index = 0;
reg [$clog2(NUM_LEDS * 3):0] color_count0 = 0;
reg [$clog2(NUM_LEDS * 3):0] color_count1 = 0;
reg color_bank = 0;

localparam SPI_STATE_IDLE = 0;
localparam SPI_STATE_BUSY = 1;

reg [1:0] spi_state = SPI_STATE_IDLE;

wire [7:0] spi_data;
wire spi_ready;
reg [1:0] ssel = 2'b11;

wire sck, mosi, miso, sel, ws_do;
assign sck = GPIO_0_IN[0];
assign mosi = GPIO_0_IN[1];
assign GPIO_0[2] = 1'bz;
assign sel = GPIO_0[2];
assign GPIO_0[0] = miso;
assign GPIO_0[1] = ws_do;

assign miso = 1;

SPI_rx_slave rx (
	.clk(CLOCK_50), 
	.SCK(sck), 
	.MOSI(mosi), 
	.SSEL(sel), 
	.DATA(spi_data), 
	.READY(spi_ready));
	
//=======================================================
//  Structural coding
//=======================================================

   always @ (posedge CLOCK_50) begin
		ssel <= {ssel[0], sel};
		if (spi_state == SPI_STATE_IDLE) begin
			if (ssel == 2'b10) begin
				led_color_index <= 0;
				color_bank <= ~color_bank;
				spi_state <= SPI_STATE_BUSY;
			end
		end
		else /* if (spi_state == SPI_STATE_BUSY) */ begin
			if (ssel == 2'b01)
				spi_state <= SPI_STATE_IDLE;
			if (spi_ready && (led_color_index < NUM_LEDS)) begin
				case (color_bank)
				1'b0:
					led_colors0[led_color_index] <= spi_data;
				1'b1:
					led_colors1[led_color_index] <= spi_data;
				endcase
				led_color_index <= led_color_index + 1'b1;
				case (color_bank)
				1'b0:
					color_count0 <= led_color_index + 1'b1;
				1'b1:
					color_count1 <= led_color_index + 1'b1;
				endcase
			end
		end
	end

reg [7:0] redr, greenr, bluer;
wire ws_data_req, ws_new_addr;
wire [$clog2(NUM_LEDS) - 1:0] ws_addr;
wire [$clog2(NUM_LEDS * 3):0] ws_count;
assign ws_count = color_bank ? color_count1 : color_count0;
reg ws_bank = 0;
wire reset_state;

ws2812
  #(
    .NUM_LEDS(NUM_LEDS),          // The number of LEDS in the chain
	 .SYSTEM_CLOCK(50000000)
    )
WS
   (
    .clk(CLOCK_50),  // Clock input.
    .reset(~KEY[0]),        // Resets the internal state of the driver
	 .reset_state(reset_state),
	 .data_request(ws_data_req), // This signal is asserted one cycle before red_in, green_in, and blue_in are sampled.
    .new_address(ws_new_addr),  // This signal is asserted whenever the address signal is updated to its new value.
    .address(ws_addr),      // The current LED number. This signal is incremented to the next value two cycles after the last time data_request was asserted.
    .red_in(redr),       // 8-bit red data
    .green_in(greenr),     // 8-bit green data
    .blue_in(bluer),      // 8-bit blue data
    .DO(ws_do)           // Signal to send to WS2811 chain.
    );	 

   always @ (posedge CLOCK_50) begin
	   if (reset_state)
			ws_bank <= color_bank;
		if (ws_data_req) begin
			if (ws_addr * 3 < ws_count) begin
				case (ws_bank)
				1'b0: begin
					greenr = led_colors0[ws_addr * 3];
					redr = led_colors0[ws_addr * 3 + 1];
					bluer = led_colors0[ws_addr * 3 + 2];
				end
				1'b1: begin
					greenr = led_colors1[ws_addr * 3];
					redr = led_colors1[ws_addr * 3 + 1];
					bluer = led_colors1[ws_addr * 3 + 2];
				end
				endcase
			end
			else begin
				greenr = 0;
				redr = 0;
				bluer = 0;
			end
		end
	end

endmodule
