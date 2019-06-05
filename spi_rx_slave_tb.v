`timescale 10ns/1ns

module tb;
   reg clk;

   reg SCK, MOSI, SSEL;
	wire MISO, START, END;
	wire [7:0] DATA;
	wire READY;
   
   SPI_rx_slave uut(
	   .clk(clk), 
		.SCK(SCK), 
		.MOSI(MOSI), 
		.MISO(MISO), 
		.SSEL(SSEL), 
		.DATA(DATA), 
		.START(START),
		.END(END),
		.READY(READY)
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
		SSEL = 1;

      #100 $finish();
   end

   always clk = #1 ~clk;
   
endmodule
