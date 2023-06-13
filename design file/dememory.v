`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 18:54:35
// Design Name: 
// Module Name: dememory
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


module dememory(
        input               clock, 
        input   [31:0]      address, // read/write memory address
        input               Memwrite, //determine to write or read 
        input   [31:0]      write_data, // data to write
        output  [31:0]      read_data, // data to read

        // UART Programmer Pinouts
        input upg_rst_i, // UPG reset (Active High)
        input upg_clk_i, // UPG ram_clk_i (10MHz)
        input upg_wen_i, // UPG write enable
        input [13:0] upg_adr_i, // UPG write address
        input [31:0] upg_dat_i, // UPG write data
        input upg_done_i // 1 if programming is finished

    );
    
    wire clock_reverse;
    assign clock_reverse = !clock;
    
    wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i);    
//    wire kickOff=1;
    RAM ram (
    .clka (kickOff ? clock_reverse : upg_clk_i),
    .wea (kickOff ? Memwrite : upg_wen_i),
    .addra (kickOff ?address[15:2] : upg_adr_i),
    .dina (kickOff ? write_data: upg_dat_i),
    .douta (read_data)
    );
        
//   RAM ram (
//      .clka(clock_reverse), // input wire clka
//      .wea(Memwrite), // input wire [0 : 0] wea
//      .addra(address[15:2]), // input wire [13 : 0] addra
//      .dina(write_data), // input wire [31 : 0] dina
//      .douta(read_data) // output wire [31 : 0] douta
//    );

endmodule