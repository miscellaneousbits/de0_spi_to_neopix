module ws2812 #(
    parameter NUM_LEDS          = 4,          // The number of LEDS in the chain
    parameter SYSTEM_CLOCK      = 50000000    // The frequency of the input clock signal, in Hz. This value must be correct in order to have correct timing for the WS2811 protocol.
    )
   (
    input                              clk,          // Clock input.
	 input										reset,
	 
	 output                             reset_state,

    /////////////////////
    // Control signals //
    /////////////////////
    output                             data_request, // This signal is asserted one cycle before red_in, green_in, and blue_in are sampled.
    output                             new_address,  // This signal is asserted whenever the address signal is updated to its new value.
    output reg [$clog2(NUM_LEDS)-1:0] address,      // The current LED number. This signal is incremented to the next value two cycles after the last time data_request was asserted.
    
    input [7:0]                        red_in,       // 8-bit red data
    input [7:0]                        green_in,     // 8-bit green data
    input [7:0]                        blue_in,      // 8-bit blue data
    
    ////////////////////
    // External ports //
    ////////////////////
    output reg                         DO            // Signal to send to WS2811 chain.
    );
   
localparam integer LED_ADDRESS_WIDTH = $clog2(NUM_LEDS);         // Number of bits to use for address input

/////////////////////////////////////////////////////////////
// Timing parameters for the WS2811                        //
// The LEDs are reset by driving D0 low for at least 50us. //
// Data is transmitted using a 800kHz signal.              //
// A '1' is 50% duty cycle, a '0' is 25% duty cycle.       //
/////////////////////////////////////////////////////////////
localparam integer CYCLE_COUNT         = SYSTEM_CLOCK / 800_000;

// SK6812
localparam integer H0_CYCLE_COUNT   = 0.25 * CYCLE_COUNT;
localparam integer H1_CYCLE_COUNT   = 0.5 * CYCLE_COUNT;
// WS2812B
// localparam integer H0_CYCLE_COUNT   = 0.32 * CYCLE_COUNT;
// localparam integer H1_CYCLE_COUNT   = 0.64 * CYCLE_COUNT;
	
localparam integer RESET_COUNT      = 100 * CYCLE_COUNT;

reg [$clog2(CYCLE_COUNT)-1:0]       clock_div;           // Clock divider for a cycle
reg [$clog2(RESET_COUNT)-1:0]       reset_counter;       // Counter for a reset cycle

localparam STATE_RESET    = 3'd0;
localparam STATE_LATCH    = 3'd1;
localparam STATE_PRE      = 3'd2;
localparam STATE_TRANSMIT = 3'd3;
localparam STATE_POST     = 3'd4;
reg [2:0]                           state;              // FSM state;

assign reset_state = state == STATE_RESET;

localparam COLOR_G     = 2'd0;
localparam COLOR_R     = 2'd1;
localparam COLOR_B     = 2'd2;
reg [1:0]                           color;              // Current color being transferred
							  
reg [7:0]                           red;
reg [7:0]                           green;
reg [7:0]                           blue;

reg [7:0]                           current_byte;       // Current byte to send
reg [2:0]                           current_bit;        // Current bit index to send

wire                                reset_almost_done;
wire                                led_almost_done;

assign reset_almost_done = (state == STATE_RESET) && (reset_counter == RESET_COUNT-1);
assign led_almost_done   = (state == STATE_POST)  && (color == COLOR_B) && (current_bit == 0) && (address != 0);

assign data_request = reset_almost_done || led_almost_done;
assign new_address  = (state == STATE_PRE) && (current_bit == 7);

always @ (posedge clk) begin
	if (reset) begin
		address <= 0;
		state <= STATE_RESET;
		DO <= 0;
		reset_counter <= 0;
		color <= COLOR_G;
		current_bit <= 7;
	end
	else begin
		case (state)
		
		  STATE_RESET: begin
			  // De-assert DO, and wait for 75 us.
			  DO <= 0;
			  if (reset_counter == RESET_COUNT-1) begin
				  reset_counter <= 0;
				  state <= STATE_LATCH;
			  end
			  else begin
				  reset_counter <= reset_counter + 1'b1;
			  end
		  end
		  
		  STATE_LATCH: begin
			  // Latch the input
			  red <= red_in;
			  blue <= blue_in;

			  // Setup the new address
			  address <= address + 1'b1;
			  
			  // Start sending green
			  color <= COLOR_G;
			  current_byte <= green_in;
			  current_bit <= 7;
			  
			  state <= STATE_PRE;
		  end
		  
		  STATE_PRE: begin
			  // Assert DO, start clock divider counter
			  clock_div <= 0;
			  DO <= 1;
			  state <= STATE_TRANSMIT;
		  end
		  
		  STATE_TRANSMIT: begin
			  // De-assert DO after a certain amount of time, depending on if you're transmitting a 1 or 0.
			  if ((current_byte[7] == 0 && clock_div >= H0_CYCLE_COUNT) || (current_byte[7] == 1 && clock_div >= H1_CYCLE_COUNT))
				  DO <= 0;
			  // Advance cycle counter
			  if (clock_div == CYCLE_COUNT-1)
				  state <= STATE_POST;
			  clock_div <= clock_div + 1'b1;
		  end
		  
		  STATE_POST: begin
			  if (current_bit != 0) begin
				  // Start sending next bit of data
				  current_byte <= {current_byte[6:0], 1'b0};
				  current_bit <= current_bit - 1'b1;
				  state <= STATE_PRE;
			  end
			  else begin
				  // Advance to the next color. If we were on blue, advance to the next LED
				  case (color)
					  COLOR_G: begin
						  color <= COLOR_R;
						  current_byte <= red;
						  current_bit <= 7;
						  state <= STATE_PRE;
					  end
					 COLOR_R: begin
						 color <= COLOR_B;
						 current_byte <= blue;
						 current_bit <= 7;
						 state <= STATE_PRE;
					 end
					 COLOR_B: begin
						 // If we were on the last LED, send out reset pulse
						 if (address == 0) begin
							 state <= STATE_RESET;
						 end
						 else begin
							 state <= STATE_LATCH;
						 end
					 end
				  endcase
			  end
		  end
		  
		endcase
	end
end
   
endmodule
