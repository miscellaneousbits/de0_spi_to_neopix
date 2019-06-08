module stretch (
	input clk,
	input in,
	output out
	);
	
parameter MIN_DURATION_MS = 200;
parameter SYSTEM_CLOCK = 50000000;

localparam MIN_CLKS = (MIN_DURATION_MS * SYSTEM_CLOCK) / 1000;

reg out_r;
assign out = out_r;
reg [1:0] in_r;
reg [$clog2(MIN_CLKS):0] clks;

always @ (posedge clk) begin
	in_r = {in_r[0], in};
	if (clks < MIN_CLKS)
		clks <= clks + 1'b1;
	else
	   out_r <= in;
	if (in_r == 2'b01) begin
		clks <= 0;
		out_r <= 1;
	end
	if (in_r == 2'b10) begin
		if (clks == MIN_CLKS)
			out_r <= 0;
	end
end

endmodule