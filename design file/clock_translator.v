`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 11:50:10
// Design Name: 
// Module Name: clock_translator
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


module clock_translator(
    input clock_in,
    output reg clock_out
    );
    // get clock_out with required frequency from clock_in
    
    parameter in_frequency=100_000_000;//the frequency of clock_in
    parameter out_frequency=100_000;//the frequency of clock_out
    reg[30:0] count;
    
    wire max_count;
    assign  max_count=in_frequency/out_frequency/2;
    
    always @(posedge clock_in) begin
      if (count == max_count) begin
        count <= 0;
        clock_out <= ~clock_out;
      end else begin
        count <= count + 1;
      end
    end    
        
endmodule
