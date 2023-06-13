`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 20:50:26
// Design Name: 
// Module Name: switch
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


module switch(
    input clock,			        
    input rst,			       
    input [1:0] switchaddr,		   
    input switchread,			   	   
    input [23:0] switch_i,
    output [15:0] switchrdata_out
    );
    reg [23:0] switchrdata;
        always@(negedge clock or posedge rst) begin
            if(rst) begin
                switchrdata <= 0;
            end
            else if(switchread) begin
                if(switchaddr==2'b00)
                    switchrdata[15:0] <= switch_i[15:0];   // data output,lower 16 bits non-extended
                else if(switchaddr==2'b10)
                    switchrdata[15:0] <= { 8'h00, switch_i[23:16]}; //data output, upper 8 bits extended with zero
            end
        end
    assign switchrdata_out=switchrdata[15:0];
    		
endmodule