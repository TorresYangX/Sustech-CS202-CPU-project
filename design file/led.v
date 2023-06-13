`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 21:06:33
// Design Name: 
// Module Name: led
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


module led(
    input clock,    		    // clock
    input rst, 		        // reset signal
    input ledwrite,		       	// witer data is true
    input ledcs,		      
    input[1:0] ledaddr,	       
    input[15:0] ledwdata,	  
    output reg [23:0]  ledout	 
    );
    
    always@(posedge clock or posedge rst) begin
            if(rst) begin
                ledout <= 24'h000000;
            end
            else if(ledcs && ledwrite) begin
                if(ledaddr == 2'b00)
                    ledout[23:0] <= { ledout[23:16], ledwdata[15:0] };
                else if(ledaddr == 2'b10 )
                    ledout[23:0] <= { ledwdata[7:0], ledout[15:0] };
            end
     end
endmodule
