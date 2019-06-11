module stretch (
	input clk,
	input reset,
	input in,
	output reg out
	);
	
parameter SYSTEM_CLOCK = 50000000;
parameter MIN_DURATION = SYSTEM_CLOCK / 8;

reg [1:0] in_r;
reg [$clog2(MIN_DURATION) - 1:0] clk_r;

always @ (posedge clk) begin
	if (reset) begin
		out <= 0;
		in_r <= 0;
		clk_r <= 0;
	end
	else begin
		in_r = {in_r[0], in};
		if (in_r == 2'b01) begin
			clk_r <= MIN_DURATION - 1;
		end
		else if (clk_r)
			clk_r <= clk_r - 1'b1;
		out <= (clk_r == 0) ? in_r[0] : 1'b1;
	end
end

endmodule