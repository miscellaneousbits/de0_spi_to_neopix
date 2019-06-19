// NeoPixel protocol

module ws2812 (
	input                              clk_i,       // Clock input.
	input                              reset_i,
	input                              start_i,
	output                             busy_o,
	output                             data_request_o, // This signal is asserted one cycle before red_i, green_i,
																		//and blue_i are sampled.
	output [$clog2(NUM_LEDS)-1:0]  	  address_o,  // The current LED number. This signal is incremented to the next
																	// value two cycles after the last time data_request_o was asserted.
	input [7:0]                        red_i,       // 8-bit red_r data
	input [7:0]                        green_i,     // 8-bit green_r data
	input [7:0]                        blue_i,      // 8-bit blue_r data
	output                             do_o,       	// Signal to send to WS2811 chain.
	input [$clog2(NUM_LEDS)-1:0]       led_count_i	// Number of actual LEDS
 );

parameter NUM_LEDS = 8;          		// The number of LEDS in the chain
parameter SYSTEM_CLOCK = 50_000_000;	// The frequency of the input clock signal, in Hz. This value must be correct in
													// order to have correct timing for the WS2811 protocol.
localparam integer CYCLE_COUNT = (SYSTEM_CLOCK / 800_000) - 3; // 800 KHz pixel clock

// SK6812
//localparam integer H0_CYCLE_COUNT = 0.25 * CYCLE_COUNT;
//localparam integer H1_CYCLE_COUNT = 0.5 * CYCLE_COUNT;

// WS2812B
localparam integer H0_CYCLE_COUNT = 0.32 * CYCLE_COUNT;
localparam integer H1_CYCLE_COUNT = 0.64 * CYCLE_COUNT;
	
localparam integer RESET_COUNT = SYSTEM_CLOCK * 0.000_080; // 80 microseconds

reg [$clog2(CYCLE_COUNT)-1:0] clock_div_r = CYCLE_COUNT[$clog2(CYCLE_COUNT)-1:0];			// Clock divider for a cycle
reg [$clog2(RESET_COUNT)-1:0] reset_counter_r = 0;		// Counter for a reset_i cycle
reg [$clog2(NUM_LEDS)-1:0]  address_r = 0;  // The current LED number. This signal is incremented to the next
assign address_o = address_r;

localparam STATE_RESET    = 3'd0;
localparam STATE_LATCH    = 3'd1;
localparam STATE_PRE      = 3'd2;
localparam STATE_TRANSMIT = 3'd3;
localparam STATE_POST     = 3'd4;

reg [2:0] state_r = STATE_RESET;				// FSM state_r;

assign busy_o = state_r != STATE_RESET;

localparam COLOR_G = 2'd0;
localparam COLOR_R = 2'd1;
localparam COLOR_B = 2'd2;

reg [1:0]	color_r = COLOR_G;				// Current color_r being transferred
reg [7:0]	red_r, blue_r;
reg [7:0]	current_byte_r = 0;	// Current byte to send
reg [2:0]	current_bit_r = 7;		// Current bit index to send
reg [1:0]	start_r = 0;
reg			start_now_r = 0;

wire reset_almost_done_w  =
	(state_r == STATE_RESET) &&
	(reset_counter_r == (RESET_COUNT - 1));
	
wire led_almost_done_w =
	(state_r == STATE_POST) &&
	(color_r == COLOR_B) &&
	(current_bit_r == 0) &&
	(address_r != led_count_i);

assign data_request_o = reset_almost_done_w || led_almost_done_w;
assign do_o = clock_div_r < (current_byte_r[7] ? H1_CYCLE_COUNT : H0_CYCLE_COUNT);

always @ (posedge clk_i) begin
	if (reset_i) begin
		address_r <= 0;
		state_r <= STATE_RESET;
		reset_counter_r <= 0;
		color_r <= COLOR_G;
		current_bit_r <= 7;
		start_r <= 0;
		start_now_r <= 0;
		current_byte_r <= 0;
		clock_div_r <= CYCLE_COUNT[$clog2(CYCLE_COUNT)-1:0];
	end
	else begin
		start_r <= {start_r[0], start_i};
		case (state_r)
		
		  STATE_RESET: begin
			  if (start_r == 2'b01)
				  start_now_r <= 1;
			  // De-assert do_o, and wait for 75 us.
			  if (reset_counter_r < RESET_COUNT - 1)
				  reset_counter_r <= reset_counter_r + 1'b1;
			  else if (start_now_r) begin
			     start_now_r <= 0;
				  state_r <= STATE_LATCH;
			  end
		  end
		  
		  STATE_LATCH: begin
			  // Latch the input
			  red_r <= red_i;
			  blue_r <= blue_i;

			  // Start sending green_r
			  color_r <= COLOR_G;
			  current_byte_r <= green_i;
			  current_bit_r <= 7;
			  
			  // Setup the new address_o
			  address_r <= address_r + 1'b1;
			  
			  state_r <= STATE_PRE;
		  end
		  
		  STATE_PRE: begin
			  // Assert do_o, start_i clock divider counter
			  clock_div_r <= 0;
			  state_r <= STATE_TRANSMIT;
		  end
		  
		  STATE_TRANSMIT: begin
			  clock_div_r <= clock_div_r + 1'b1;
			  if (clock_div_r == CYCLE_COUNT)
				  state_r <= STATE_POST;
		  end
		  
		  STATE_POST: begin
			  if (current_bit_r) begin
				  // Start sending next bit of data
				  current_byte_r <= {current_byte_r[6:0], 1'b0};
				  current_bit_r <= current_bit_r - 1'b1;
				  state_r <= STATE_PRE;
			  end
			  else begin
				  // Advance to the next color_r. If we were on blue_r, advance to the next LED
				  current_bit_r <= 7;
				  case (color_r)
					  COLOR_G: begin
						  color_r <= COLOR_R;
						  current_byte_r <= red_r;
						  state_r <= STATE_PRE;
					  end
					 COLOR_R: begin
						 color_r <= COLOR_B;
						 current_byte_r <= blue_r;
						 state_r <= STATE_PRE;
					 end
					 COLOR_B: begin
						 // If we were on the last LED, go back to reset
						 if (address_r == led_count_i) begin
							 state_r <= STATE_RESET;
							 address_r <= 0;
							 reset_counter_r <= 0;
						 end
						 else
							 state_r <= STATE_LATCH;
					 end
				  endcase
			  end
		  end
		  
		endcase
	end
end
	
endmodule
