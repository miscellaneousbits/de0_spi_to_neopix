module invert_debounce (
	input		clk_i,
	input		reset_i,
	input		in_i,
	output	out_o
	);
     
parameter SYSTEM_CLOCK = 50000000;
localparam MIN_DURATION = SYSTEM_CLOCK / 50; // 20 ms.
//localparam MIN_DURATION = 200; // for sim
 
reg  [$clog2(MIN_DURATION) - 1:0]  delaycount_reg;                     
reg  [$clog2(MIN_DURATION) - 1:0]  delaycount_next;
  
reg [1:0] dff;
reg out_r;
assign out_o = out_r;
                                 
wire q_add;                                     
wire q_reset;

always @( posedge clk_i ) begin
	if(reset_i) begin // At reset initialize FF and counter 
		dff <= {~in_i, ~in_i};
		delaycount_reg <= 0;
		out_r <= 0;
	end
	else begin
		dff <= {dff[0], ~in_i};
		delaycount_reg <= delaycount_next;
	end
	if (delaycount_reg[$clog2(MIN_DURATION) - 1] == 1'b1)
		out_r <= dff[1];
end

assign q_reset = (dff[0]  ^ dff[1]); // Ex OR button_in on conecutive clocks
                                     // to detect level change 
assign  q_add = ~delaycount_reg[$clog2(MIN_DURATION) - 1]; // Check count using MSB of counter         
     
 
always @(q_reset, q_add, delaycount_reg) begin
	case( {q_reset, q_add})
	2'b00 :
		delaycount_next <= delaycount_reg;
	2'b01 :
		delaycount_next <= delaycount_reg + 1'b1;
	default :
	// In this case q_reset = 1 => change in level. Reset the counter 
		delaycount_next <= 0;
	endcase    
end
     
endmodule
