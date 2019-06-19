create_clock -period 20 [get_ports CLOCK_50]
create_generated_clock -source CLOCK_50 -name CLOCK_25 -divide_by 2 [get_registers sysclk_r]
	
derive_clock_uncertainty
derive_pll_clocks