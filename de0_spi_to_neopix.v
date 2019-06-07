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


reg [7:0] de0_led = 8'hff;
assign LED = de0_led;

//=======================================================
//  REG/WIRE declarations
//=======================================================

//parameter NUM_LEDS = 256;
parameter NUM_LEDS = 256;

reg [$clog2(NUM_LEDS):0] led_count[0:1];

reg [$clog2(NUM_LEDS) - 1:0] spi_addr = 0;
reg [$clog2(NUM_LEDS) - 1:0] spi_addr1 = 0;
reg [1:0] spi_byte_index;
reg spi_bank = 0;

localparam SPI_STATE_IDLE = 0;
localparam SPI_STATE_BUSY = 1;

reg [1:0] spi_state = SPI_STATE_IDLE;

wire [7:0] spi_data;
reg [23:0] spi_word;
wire spi_ready;
reg [1:0] ssel = 2'b11;

wire [$clog2(NUM_LEDS):0] spi_banked_addr = spi_addr1 + (spi_bank ? NUM_LEDS : 0);
reg wren = 0;

reg ws_bank = 1;
wire [$clog2(NUM_LEDS) - 1:0] ws_addr;
wire [$clog2(NUM_LEDS):0] ws_banked_addr = ws_addr + (ws_bank ? NUM_LEDS : 0);
wire [31:0] q;

dual_port_ram	#(
	.NUM_LEDS(NUM_LEDS)
	)
ram (
	.clock (CLOCK_50),
	.data ({8'b0, spi_word}),
	.rdaddress ({8'b0, ws_banked_addr}),
	.wraddress ({8'b0, spi_banked_addr}),
	.wren (wren),
	.q (q)
	);
	
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
		spi_addr1 <= spi_addr;
		ssel <= {ssel[0], sel};
		if (wren)
			wren <= 0;
		if (spi_state == SPI_STATE_IDLE) begin
			if (ssel == 2'b10) begin
				spi_addr <= 0;
				spi_byte_index <= 0;
				led_count[~spi_bank] = 0;
				spi_state <= SPI_STATE_BUSY;
				spi_bank <= ~spi_bank;
			end
		end
		else /* if (spi_state == SPI_STATE_BUSY) */ begin
			if (ssel == 2'b01) begin
				spi_state <= SPI_STATE_IDLE;
			end				
			if (spi_ready && (spi_addr < NUM_LEDS)) begin
				case (spi_byte_index)
					0: begin
						spi_byte_index <= 1;
						spi_word[23:16] <= spi_data;
					end
					1: begin
						spi_byte_index <= 2;
						spi_word[15:8] <= spi_data;
					end
					2: begin
						spi_word[7:0] <= spi_data;
						wren <= 1;
						spi_byte_index <= 0;
						spi_addr <= spi_addr + 1'b1;
						led_count[spi_bank] <= led_count[spi_bank] + 1'b1;
					end
				endcase
			end
		end
	end

reg [7:0] redr, greenr, bluer;
wire ws_data_req, ws_new_addr;
wire [$clog2(NUM_LEDS * 3):0] ws_count;
assign ws_count = led_count[ws_bank];
wire reset_state;

ws2812
  #(
    .NUM_LEDS(NUM_LEDS),          // The number of LEDS in the chain
	 .SYSTEM_CLOCK(50000000)
    )
WS
   (
    .clk(CLOCK_50),  // Clock input.
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
			ws_bank <= spi_bank;
		if (ws_data_req) begin
			if (ws_addr < ws_count) begin
				greenr <= q[23:16];
				redr <= q[15:8];
				bluer <= q[7:0];
			end
			else begin
				greenr <= 0;
				redr <= 0;
				bluer <= 0;
			end
		end
	end

endmodule

