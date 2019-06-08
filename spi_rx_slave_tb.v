`timescale 10ns/1ns

module tb;
   reg clk;

   reg SCK = 0, MOSI = 0, SSEL0 = 1, SSEL1 = 1;
	wire MISO;
   		
// sck  IO_0_IN[0]
// mosi IO_0_IN[1]
// miso IO_0[0]
// ssel0 IO_0[1]
// ssel1 IO_0[2]
// DO0  IO_0[3]
// DO1  IO_0[4]

wire [33:0] GPIO_0;
wire [1:0] GPIO_0_IN;

assign GPIO_0_IN = {MOSI, SCK};
assign GPIO_0[1] = SSEL0;
assign GPIO_0[2] = SSEL1;

de0_top uut (
	.CLOCK_50(clk),
	.GPIO_0(GPIO_0),
	.GPIO_0_IN(GPIO_0_IN)
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
		SSEL0 = 1;
		SSEL1 = 1;
		
		#200 SSEL0 = 0;
		do_write(8'haa);
		do_write(8'h55);
		do_write(0);
		do_write(8'haa);
		do_write(8'h55);
		do_write(0);
		SSEL0 = 1;

		#90800 SSEL0 = 0;
		do_write(8'h00);
		do_write(8'h55);
		do_write(8'haa);
		SSEL0 = 1;

		#100 SSEL1 = 0;
		do_write(8'haa);
		do_write(8'h55);
		do_write(0);
		do_write(8'haa);
		do_write(8'h55);
		do_write(0);
		SSEL1 = 1;

		#90800 SSEL1 = 0;
		do_write(8'h00);
		do_write(8'h55);
		do_write(8'haa);
		SSEL1 = 1;

      #100000 $stop();
   end

   always clk = #1 ~clk;
   
endmodule
