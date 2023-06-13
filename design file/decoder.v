`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/21 14:36:34
// Design Name: 
// Module Name: decoder
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


module decoder(
   input         clock,
   input         reset,
   input [31:0]  instruction,    
   input [31:0]  data_mem,  //  read data from mem       
   input [31:0]  result_alu,  //    result from memory      
   input         jal,            
   input         RegWrite,        
   input         MemtoReg,        
   input         RegDst         ,     
   input [31:0]  pc,      
   
   output [31:0] read_data_1,    //  data1
   output [31:0] read_data_2,    //  data2
   output reg[31:0] imme_extend    // immediate number
    );
    
        wire [5:0]  opcode;
        wire [4:0]  rs;
        wire [4:0]  rt;
        wire [4:0]  rd;
        wire [4:0]  shamt;
        wire [5:0]  funct;
        wire [15:0] immediate;
        wire [25:0] address;
        assign opcode       = instruction[31:26];
        assign rs           = instruction[25:21];
        assign rt           = instruction[20:16];
        assign rd           = instruction[15:11];
        assign shamt        = instruction[10:6];
        assign funct        = instruction[5:0];
        assign immediate    = instruction[15:0];
        assign address      = instruction[25:0];
        
        //build registers and read data from registers
        reg[31:0]   register[0:31];
        
        assign read_data_1 = register[rs];
        assign read_data_2 = register[rt];
        
        // extend immediate number from 16-bit to 32 bit
        wire sign;
        assign sign=immediate[15];
        
        always @(*)
        begin
            if(sign==0||opcode == 6'b001101 || opcode == 6'b001101)
            begin
                imme_extend<={16'b0000_0000_0000_0000,immediate};
            end
            else begin 
                imme_extend<={16'b1111_1111_1111_1111,immediate};
            end
        end
         
        //write information to certain regeister
        reg[5:0] reg_addr_write;
        reg[31:0] reg_data_write;
        
        //to determine where to write
        
        always @(negedge clock) begin
                if(RegWrite == 1'b1) begin
                   
                    //determine the address of reg to write
                    if(jal == 1'b1) begin
                        //reg from $32
                        reg_addr_write <= 5'b11111; // 32
                    end
                        // reg from rd
                    else if(RegDst == 1'b1) begin
                        reg_addr_write <= rd;
                    end
                        // reg from rt
                    else if (RegDst == 1'b0) begin
                        reg_addr_write <= rt;
                    end
                    
                    //determine what to write
                     // jump and link
                     if(jal == 1'b1) begin
                         reg_data_write <= pc+4; 
                    end
                     //data from alu
                    else if(MemtoReg == 1'b0) begin
                        reg_data_write <= result_alu;
                    end
                     // data from memory 
                    else if(MemtoReg == 1'b1) begin
                          reg_data_write <= data_mem;
                    end
                
                end 
            end
            
            always @(posedge clock) begin
//            always @(*) begin
                    // initialization
                    if(reset == 1'b1) begin
                       register[0] <= 32'h0000_0000;
                       register[1] <= 32'h0000_0000;
                       register[2] <= 32'h0000_0000;
                       register[3] <= 32'h0000_0000;
                       register[4] <= 32'h0000_0000;
                       register[5] <= 32'h0000_0000;
                       register[6] <= 32'h0000_0000;
                       register[7] <= 32'h0000_0000;
                       register[8] <= 32'h0000_0000;
                       register[9] <= 32'h0000_0000;
                       register[10] <= 32'h0000_0000;
                       register[11] <= 32'h0000_0000;
                       register[12] <= 32'h0000_0000;
                       register[13] <= 32'h0000_0000;
                       register[14] <= 32'h0000_0000;
                       register[15] <= 32'h0000_0000;
                       register[16] <= 32'h0000_0000;
                       register[17] <= 32'h0000_0000;
                       register[18] <= 32'h0000_0000;
                       register[19] <= 32'h0000_0000;
                       register[20] <= 32'h0000_0000;
                       register[21] <= 32'h0000_0000;
                       register[22] <= 32'h0000_0000;
                       register[23] <= 32'h0000_0000;
                       register[24] <= 32'h0000_0000;
                       register[25] <= 32'h0000_0000;
                       register[26] <= 32'h0000_0000;
                       register[27] <= 32'h0000_0000;
                       register[28] <= 32'h0000_0000;
                       register[29] <= 32'h0000_0000;
                       register[30] <= 32'h0000_0000;
                       register[31] <= 32'h0000_0000;
                    end
                    else begin
                        // write in register is true
                        if(RegWrite == 1'b1) begin
                             register[reg_addr_write] <= reg_data_write;
                        end
                    end
              end
       
endmodule