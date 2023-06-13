module execute(
     // input from decoder
   input[31:0] Read_data_1,    // input1
   input[31:0] Read_data_2,    // input2
   input[31:0] Imme_extend,    // output

   // input from instruction fetch
   input[31:0] instruction,
   input[31:0] pc,      //  pc

   // input from controller 
   input[1:0] ALUOp,     //{ (R_format || I_format) , (Branch || nBranch) }
   input ALUSrc,       // 1-第二个数是立即数（除了beq、bne）
   input I_format,     // 1-指令是 I-类型（除了beq、bne、lw、sw）
   input Sftmd,        // 1-shift 指令
   input Jr,           // 1-指令是 jr     0-表示不是 jr

   // output
   output          Zero,                // result is 0 from alu
   output      [31:0]  result_alu,          // result from alu
   output          [31:0]  result_addr         //address of instruction
    );
    
    wire [5:0] Function_opcode; //  instructions[5:0]
    wire [5:0] opcode;          //  instruction[31:26]
    wire [4:0] Shamt;           //  instruction[10:6], the amount of shift bits
    assign Function_opcode=instruction[5:0];
    assign opcode=instruction[31:26];
    assign Shamt=instruction[10:6];
    
//    // to determine whether the result of alu equals 0
//    assign Zero = (ALU_output[31:0] == 32'h00000000) ? 1'b1 : 1'b0;
    
    wire[31:0] pc_next;
    assign pc_next=(pc+4);
    
    
    
    //determine which is the real input
    wire [31:0] Ainput;
    wire [31:0] Binput;
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Imme_extend[31:0];
    
    //determine which detailed type is
    wire[5:0] Exe_code;
    assign Exe_code = (I_format==0) ?Function_opcode :{ 3'b000 , opcode[2:0] };
    wire [2:0] ALU_ctl;
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
    
    //result get from ALU
    reg [31:0] ALU_output;
    wire [2:0] Sftm;
    assign Sftm = Function_opcode[2:0];
    reg[31:0] Shift_Result;
    always @* begin
    
        //output is computation result
        case(ALU_ctl)
                3'b000: ALU_output <= Ainput & Binput;   //and,andi
                3'b001: ALU_output <= Ainput | Binput;   //or,ori
                3'b010: ALU_output <= Ainput + Binput ;  //add,addi,lw,sw
                3'b011: ALU_output <= Ainput + Binput;   //addu,addiu
                3'b100: ALU_output <= Ainput ^ Binput;   //xor,xori
                3'b101: ALU_output <= ~(Ainput | Binput);    //nor,lui
                3'b110: ALU_output <= Ainput - Binput;   //sub,slti,beq,bne
                3'b111: ALU_output <= Ainput - Binput;   //subu,sltiu,slt,sltu
                default: ALU_output <= 32'h0000_0000;   //default
        endcase    
        
        //output is shamet result
        if(Sftmd) begin
        case(Sftm[2:0])
            3'b000:Shift_Result <= Binput << Shamt; //Sll rd,rt,shamt 00000
            3'b010:Shift_Result <= Binput >> Shamt; //Srl rd,rt,shamt 00010
            3'b100:Shift_Result <= Binput << Ainput; //Sllv rd,rt,rs 00100
            3'b110:Shift_Result <=Binput >> Ainput; //Srlv rd,rt,rs 00110
            3'b011:Shift_Result <= Binput >>> Shamt; //Sra rd,rt,shamt 00011
            3'b111:Shift_Result <= Binput >>> Ainput; //Srav rd,rt,rs 00111
            default:Shift_Result <= Binput;
            endcase
            end
        else begin
             Shift_Result = Binput ;
        end   
        end
        
    //to determine which one set tobe result
    reg [31:0] ALU_Result;
    always @(*) begin
            //set type operation (slt, slti, sltu, sltiu)
            if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) begin
                if (Exe_code[0]==1||(Ainput[31]==0&&Binput[31]==0)||(Ainput[31]==1&&Binput[31]==1))
                    ALU_Result <= (Ainput<Binput)?1:0;
                else
                    begin
                       if(Ainput[31]==1&&Binput[31]==0)
                            ALU_Result=1;
                        else
                            ALU_Result=0;
                        end
                 end
            // lui operation
            else if((ALU_ctl==3'b101) && (I_format==1)) begin
                ALU_Result[31:0] <= {Binput[15:0],{16{1'b0}}};
            end
            // shift operation
            else if(Sftmd == 1'b1) begin
                ALU_Result <= Shift_Result;
            end
            // ther types of operation in ALU (arithmatic or logic calculation
            else begin
                ALU_Result <= ALU_output[31:0];
            end
            
    end
    
    //the result is an address
    wire [32:0] branch_addr;
    assign branch_addr = pc_next[31:2] +  Imme_extend[31:0];
    assign result_addr = branch_addr[31:0];
            
    // to determine whether the result of alu equals 0
    assign Zero = (ALU_output[31:0] == 32'h00000000) ? 1'b1 : 1'b0;
    assign result_alu=ALU_Result;
    

endmodule