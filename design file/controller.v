`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 13:39:25
// Design Name: 
// Module Name: controller
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



module controller(

    input[31:0] instruction, // 31:26 op , 5:0 fuction
    input[21:0] result_alu, //31:10 from  result of alu
    
    output jr,          
    output j,         
    output jal,         
    output beq,      
    output bne,    
    output lw,    
    output sw,     
    output RegDST,      
    output RegWrite,    
    output MemWrite,    
    output ALUSrc,      
    output I_format,
    output R_format,    
    output Sftmd,       

    output[1:0] ALUOp,
    output MemorIOtoReg,
    output MemRead,
    output IORead,
    output IOWrite

    );
    wire [5:0] op;
    wire [5:0] func;
    
    assign op= instruction[31:26];
    assign func= instruction[5:0];
    
    assign R_format = (op==6'b000000);
    assign I_format =(op[5:3]==3'b001); //"I_format" is used to identify if the instruction is I_type(except for beq, bne, lw and sw)
    assign lw = (op==6'b100011);
    assign sw = (op==6'b101011);
    
    assign jr   = ((func==6'b001000) && (op==6'b000000)) ;
    assign j    = (op==6'b000010) ;
    assign jal  = (op==6'b000011) ;
    assign beq  = (op==6'b000100) ;
    assign bne  = (op==6'b000101) ;
    
    assign RegDST = R_format;   // output rd 
    assign RegWrite = (R_format || lw || jal || I_format) && !(jr);     // write in reg 
//    assign MemWrite = ((sw==1) && (result_alu[21:0]!= 22'h000003));     // write in memory
    assign MemWrite = ((sw==1) && (result_alu[21:0]!= 22'h3FFFFF));     // write in memory
    assign ALUSrc = I_format || lw || sw;   //1 indicate the 2nd data is immidiate (except beq.bne)
    assign Sftmd = (((func==6'b000000)||(func==6'b000010)||(func==6'b000011)||(func==6'b000100)||(func==6'b000110)||(func==6'b000111))&& R_format); //1 indicate the instruction is shift instructio
    assign ALUOp = {(R_format || I_format),(beq || bne)};
    //ALUOp is multi bit width port
    /* if the instruction is R-type or I_format, ALUOp is 2'b10;
    if the instruction is"beq" or "bne", ALUOp is 2'b01£»
    if the instruction is"lw" or "sw", ALUOp is 2'b00£»*/
  
//    assign MemRead = ((lw==1) );  // read in memory 
//    assign MemRead = ((lw==1) && (result_alu[21:0]!= 22'h000003));  // read in memory 
    assign MemRead = ((lw==1) && (result_alu[21:0]!= 22'h3FFFFF));  // read in memory 
    
//    assign IORead= ((lw==1) );    
//    assign IORead= ((lw==1) && (result_alu[21:0]== 22'h000003));    
    assign IORead= ((lw==1) && (result_alu[21:0]== 22'h3FFFFF));    
    
//    assign IOWrite= ((sw==1) );
//    assign IOWrite= ((sw==1) && (result_alu[21:0]== 22'h000003));
    assign IOWrite= ((sw==1) && (result_alu[21:0]== 22'h3FFFFF));
    assign MemorIOtoReg = IORead || MemRead;
    
    
    
endmodule