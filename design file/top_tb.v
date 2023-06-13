`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/22 22:51:57
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_tb();

reg clk_in,reset;
reg [23:0]switch;
wire [23:0]led_out;
reg start_pg, rx;
wire tx;
//test
wire rst;
wire upg_rst_test;
wire upg_done_o_test;
wire[1:0] ledaddr;
wire[31:0] addr_from_mem;
wire[31:0] read_data_2;
wire[31:0] instruction;
wire[31:0] pc_out;
wire Zero,beq,bne,j,jal,jr ;
wire RegWrite,MemRead,IORead;
wire [31:0]data_mem,alu_result;
top top_sim(
    .clock(clk_in), 
    .fpga_rst(reset), 
    .switch(switch), 
    .leds(led_out),
    .start_pg(start_pg),
    .rx(rx),
    .tx(tx),
    .rst(rst),
    .upg_rst_test(upg_rst_test),
    .upg_done_o_test(upg_done_o_test),
    .ledaddr(ledaddr),
    .addr_from_mem(addr_from_mem),
     .read_data_2(read_data_2),
     .instruction(instruction),
     .pc_out(pc_out),
     .Zero(Zero),
     .jr(jr),
     .j(j),
     .jal(jal),
     .bne(bne),
     .beq(beq),
     .RegWrite(RegWrite),
     .data_mem(data_mem),
     .MemRead(MemRead),
     .IORead(IORead),
     .alu_result(alu_result)
    );

always begin
    # 5 clk_in=~clk_in;
end

initial begin
    clk_in= 1'b1;
    start_pg=1'b0;
    reset= 1'b0;
    switch= 24'b0000_0000_0000_0000_0000_0000;
    #4 reset=1'b1;
    #10 reset=1'b0;
    #100 switch=24'b0000_0000_0000_0100_0000_0000;
    #100 switch=24'b0000_0000_0000_0000_0000_0001;
    #100 switch=24'b0000_0000_0000_0000_0000_0010;
    #100 switch=24'b0000_0001_0000_0000_0000_0011;
    #100 switch=24'b0000_0000_0000_0000_0000_0100;
    #100 switch=24'b0010_0000_0000_0000_0000_0101;
    #100 switch=24'b0000_0000_0010_0000_0000_0110;
    #100 switch=24'b0000_0000_0000_0100_0000_0111;
//   #100 switch=24'b0000_0001_0000_0000_0000_0010;
//   #100 switch=24'b0000_0010_0000_0000_0000_0010;
//   #100 switch=24'b0000_0011_0000_0000_0000_0010;
//   #100 switch=24'b0000_0100_0000_0000_0000_0010;
//   #100 switch=24'b0000_0101_0000_0000_0000_0010;
    
end

endmodule
