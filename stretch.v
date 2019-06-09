module stretch (
	input clk,
	input in,
	output out
	);
	
parameter SYSTEM_CLOCK = 50000000;
parameter MIN_DURATION_MS = SYSTEM_CLOCK / 8;

reg out_r;
assign out = out_r;
reg [1:0] in_r;
reg [$clog2(MIN_DURATION_MS):0] clks;

always @ (posedge clk) begin
	in_r = {in_r[0], in};
	if (clks < MIN_DURATION_MS)
		clks <= clks + 1'b1;
	else
	   out_r <= in;
	if (in_r == 2'b01) begin
		clks <= 0;
		out_r <= 1;
	end
end

endmodule