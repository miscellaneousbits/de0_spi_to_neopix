`timescale 10ns/1ns

module tb;
   reg clk;

   reg SCK = 0, MOSI = 0, SSEL = 1;
	wire MISO;
   		
wire [12:0] GPIO_2;
wire [2:0] GPIO_2_IN;
assign GPIO_2_IN = {SSEL, MOSI, SCK};

de0_spi_to_neopix uut (
	.CLOCK_50(clk),
	.GPIO_2(GPIO_2),
	.GPIO_2_IN(GPIO_2_IN)
);
   
  task do_write;
    input [7:0] data; 
    begin
		MOSI = data[7];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[6];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[5];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[4];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[3];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[2];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[1];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
		MOSI = data[0];
		#100 SCK = ~SCK;
		#100 SCK = ~SCK;
    end
  endtask
   
   initial begin
      
      clk = 0;
		SCK = 0;
		MOSI = 0;
		SSEL = 1;
		#100 SSEL= 0;
		do_write(8'haa);
		do_write(8'h55);
		do_write(0);
		SSEL = 1;

		#100 SSEL= 0;
		do_write(8'h00);
		do_write(8'h55);
		do_write(8'haa);
		SSEL = 1;

      #3000 $finish();
   end

   always clk = #1 ~clk;
   
endmodule
