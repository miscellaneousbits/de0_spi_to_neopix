module stretch_pulse (
	input			clk_i,
	input			reset_i,
	input			in_i,
	output reg	out_o
	);
	
reg [1:0] in_r;

	
parameter SYSTEM_CLOCK = 50000000;
parameter MIN_DURATION = (SYSTEM_CLOCK / 10) - 1;

reg [$clog2(MIN_DURATION + 1) - 1:0] count_r;
	
always @(posedge clk_i) begin
	if (reset_i) begin
		count_r <= 0;
		in_r <= {in_i, in_i};
		out_o <= 0;
	end
	else begin
		out_o <= count_r ? 1'b1 : in_i;
		in_r <= {in_r[0], in_i};
		if (in_r == 2'b01)
			count_r <= MIN_DURATION[$clog2(MIN_DURATION + 1) - 1:0];
		else if (count_r)
			count_r <= count_r - 1'b1;
	end
end

endmodule
