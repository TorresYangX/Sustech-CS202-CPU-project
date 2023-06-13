`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 19:48:08
// Design Name: 
// Module Name: MemOrIO
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


module MemOrIO(
    input mRead, // read memory, from Controller
    input mWrite, // write memory, from Controller
    input ioRead, // read IO, from Controller
    input ioWrite, // write IO, from Controller
    input[31:0] addr_in, // from alu_result in ALU
    output[31:0] addr_out, // address to Data-Memory
    input[31:0] m_rdata, // data read from Data-Memory
    input[15:0] io_rdata, // data read from IO,16 bits
    output reg[31:0] r_wdata, // data to Decoder(register file)
    input[31:0] r_rdata, // data read from Decoder(register file)
//    output reg[31:0] write_data, // data to memory or I/O£¨m_wdata, io_wdata£©
    output reg[31:0] m_wdata, // data into memory 
    output reg[15:0] io_wdata, // data into IO 
    output LEDCtrl,// LED Chip Select
    output SwitchCtrl // Switch Chip Select
    );
    assign addr_out = addr_in;
    assign LEDCtrl = (ioWrite == 1'b1)? 1'b1:1'b0;
    assign SwitchCtrl = (ioRead == 1'b1)? 1'b1:1'b0;
    
    always @(*) begin
            //lw
            if(mRead == 1'b1) begin
                r_wdata <= m_rdata;
            end 
            else if(ioRead == 1'b1) begin
              r_wdata <= {{16{1'b0}}, io_rdata}; 
            end 
            
            //sw           
            if(mWrite == 1'b1) begin
                 m_wdata <= r_rdata;
            end
            else if (ioWrite == 1'b1) begin
                 io_wdata <= r_rdata[15:0];
            end
            else begin
                m_wdata <= 32'hZZZZZZZZ;
                io_wdata <= 32'hZZZZZZZZ;
            end
      end
    
endmodule