`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 12:11:56
// Design Name: 
// Module Name: instruction_fetch
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


module instruction_fetch(
    input clock,
    input reset,
    input [31:0] addr_from_alu,
    input [31:0] addr_from_mem,
    input Zero,     //the result of ALU by bne/beq  
    
    //current instruction
    input       beq,   //beq
    input       bne,   //bne
    input       j,     //j
    input       jal,   //jal  
    input       jr,    //jr
    
    output[31:0] instruction, //the next instruction we get 
    output[31:0] pc_out,// pc for out put
    
    //from uart
    input upg_rst_i, // UPG reset (Active High)
    input upg_clk_i, // UPG clock (10MHz)
    input upg_wen_i, // UPG write enable
    input[13:0] upg_adr_i, // UPG write address
    input[31:0] upg_dat_i, // UPG write data
    input upg_done_i // 1 if program finished
    );
    
    reg [31:0] pc;
    reg [31:0] pc_next; //record the next pc
    
    //set next pc according to different instruxtion
    always @(*) begin
        if(jr==1)
        begin
            pc_next <=addr_from_mem ;
        end
        
        else if(bne==1 && Zero==0)
        begin
            pc_next<=addr_from_alu * 4; 
        end
        
        else if(beq==1 && Zero==1)
        begin
            pc_next <= addr_from_alu * 4; 
        end
        
        else if(j==1)
        begin
            pc_next <= {4'b0000, instruction[25:0],2'b00};
        end
        
        else if(jal==1)
        begin
            pc_next <= {4'b0000, instruction[25:0],2'b00};
        end
    
        else begin
             pc_next <= pc + 4;      
        end
    end
    
    //set the next value of pc
    always @(negedge clock) begin
           if(reset == 1'b1) begin
                pc <= 32'h0000_0000;
           end
           else begin
                pc <= pc_next;
           end
    end
    
    assign pc_out =pc;
    
    //fetch instruction from RAM
//    prgrom RAM(
//        .clka(clock), 
//        .addra(pc[15:2]), 
//        .douta(instruction)
//    );
    
    wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i );
//    wire kickOff=1;
    prgrom instmem (
        .clka (kickOff ? clock : upg_clk_i ),
        .wea (kickOff ? 1'b0 : upg_wen_i ),
        .addra (kickOff ? pc[15:2] : upg_adr_i ),
        .dina (kickOff ? 32'h00000000 : upg_dat_i ),
        .douta (instruction)
);
    
    
    
    
    
endmodule