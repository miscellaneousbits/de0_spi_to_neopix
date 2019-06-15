// 24 bit X 512 dual port RAM

module dual_port_ram (
	input					clk_i,
	input		[23:0]	data_i,
	input		[8:0]		rdaddr_i,
	input		[8:0]		wraddr_i,
	input					wren_i,
	output	[23:0]	data_o
	);
	
wire [31:0] q_w;
assign data_o = q_w[23:0];


altsyncram	#(
	.address_aclr_b("NONE"),
	.address_reg_b("CLOCK0"),
	.clock_enable_input_a("BYPASS"), .clock_enable_input_b("BYPASS"),
	.clock_enable_output_b("BYPASS"),
	.intended_device_family("Cyclone IV E"),
	.lpm_type("altsyncram"),
	.numwords_a(512), .numwords_b(512),
	.operation_mode("DUAL_PORT"),
	.outdata_aclr_b("NONE"),
	.outdata_reg_b("CLOCK0"),
	.power_up_uninitialized("FALSE"),
	.read_during_write_mode_mixed_ports("DONT_CARE"),
	.widthad_a(9), .widthad_b(9),
	.width_a(32), .width_b(32),
	.width_byteena_a(1)
	)
altsyncram_inst_0 (
	.address_a (wraddr_i),
	.address_b (rdaddr_i),
	.clock0 (clk_i),
	.data_a ({8'b0, data_i}),
	.wren_a (wren_i),
	.q_b (q_w),
	.aclr0 (1'b0), .aclr1 (1'b0),
	.addressstall_a (1'b0), .addressstall_b (1'b0),
	.byteena_a (1'b1), .byteena_b (1'b1),
	.clock1 (1'b1),
	.clocken0 (1'b1), .clocken1 (1'b1), .clocken2 (1'b1), .clocken3 (1'b1),
	.data_b ({32{1'b1}}),
	.eccstatus (),
	.q_a (),
	.rden_a (1'b1), .rden_b (1'b1),
	.wren_b (1'b0));
endmodule

