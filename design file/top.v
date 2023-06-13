`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/22 14:34:15
// Design Name: 
// Module Name: top
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


module top(
input clock,
input fpga_rst,
input [23:0] switch,
output [23:0] leds,

//URAT Programmer Pinouts
input start_pg,
input rx,
output tx

//for test
//output rst,
//output upg_rst_test,
//output upg_done_o_test,
//output[1:0] ledaddr,
//output[31:0] addr_from_mem,
//output[31:0] read_data_2,
//output[31:0] instruction,
//output[31:0] pc_out,data_mem,alu_result,regout,
//output Zero,beq,bne,j,jal,jr,
//output RegWrite,MemRead,IORead
    );
    wire rst;
    wire upg_rst_test;
    wire upg_done_o_test;
    wire [1:0] ledaddr;
    wire [31:0] addr_from_mem;
    wire [31:0] read_data_2;
    wire [31:0] instruction;
    wire [31:0] pc_out,data_mem,alu_result;
    wire  Zero,beq,bne,j,jal,jr;
    wire RegWrite,MemRead,IORead;
    
    //降频
    wire clock_new;
    wire clock_uart;
//    clock_translator clk_trans(
//        .clock_in(clock),
//        .clock_out(clock_new)
//    );
    
    clk_wiz_0 clk_trans(
            .clk_in1(clock),
            .clk_out1(clock_new),//for fpga
            .clk_out2(clock_uart)//for uart
    );
//assign clock_new=clock;
    
    wire upg_clk_o;
    wire upg_wen_o; //Uart write out enable
    wire upg_done_o; //Uart rx data have done
    //data to which memory unit of program_rom/dmemory32
    wire [14:0] upg_adr_o;
    //data to program_rom or dmemory32
    wire [31:0] upg_dat_o;
    
    wire spg_bufg;
    BUFG U1(.I(start_pg), .O(spg_bufg)); // de-twitter
//    assign spg_bufg=start_pg;
   
    // Generate UART Programmer reset signal
    reg upg_rst;
    always @ (posedge clock) begin
    if (spg_bufg) upg_rst = 0;
    if (fpga_rst) upg_rst = 1;
    end
    //used for other modules which don't relate to UART
    //for test
    //wire rst;
    assign upg_rst_test=upg_rst;
    //for test
    assign upg_done_o_test=upg_done_o;
    assign rst = fpga_rst|!upg_rst;
//test    
//    assign rst = fpga_rst;
    
    uart_bmpg_0 uart(
            .upg_clk_i(clock_uart),
            .upg_rst_i(upg_rst),
            .upg_rx_i(rx),
            .upg_clk_o(upg_clk_o),
            .upg_wen_o(upg_wen_o),
            .upg_adr_o(upg_adr_o),
            .upg_dat_o(upg_dat_o),
            .upg_done_o(upg_done_o),
            .upg_tx_o(tx)    
    );
        
    
    //ifetch  取指令
    wire [31:0] addr_from_alu;   //地址 from alu or mem
//    wire [31:0] addr_from_mem;   //地址 from alu or mem
//    wire Zero,beq,bne,j,jal,jr;                //result from alu and 控制信号们
//    wire [31:0] instruction;                   //instruction
//    wire [31:0] pc_out;                        //pc下一个地址
    
    instruction_fetch ifetch(
        .clock(clock_new),
        .reset(rst),
        .addr_from_alu(addr_from_alu),
        .addr_from_mem(addr_from_mem),
        .Zero(Zero),
        .beq(beq),
        .bne(bne),
        .j(j),
        .jal(jal),
        .jr(jr),
        .instruction(instruction),
        .pc_out(pc_out),
         .upg_clk_i(upg_clk_o),
         .upg_wen_i(upg_wen_o&(!upg_adr_o[14])),
         .upg_adr_i(upg_adr_o),
         .upg_dat_i(upg_dat_o),
         .upg_done_i(upg_done_o),
          .upg_rst_i(upg_rst)
    );
    
    // controller  得到控制信号
//    wire [31:0] alu_result;
    wire lw,sw;
    wire RegDST,MemWrite,ALUSrc,I_format,R_format,Sftmd;
    wire [1:0] ALUOp;
//    wire MemorIOtoReg,MemRead,IORead,IOWrite;
    wire MemorIOtoReg,IOWrite;
    
    controller ctr(
        .instruction(instruction),
        .result_alu(alu_result[31:10]),
        .jr(jr),
        .j(j),
        .jal(jal),
        .beq(beq),
        .bne(bne),
        .lw(lw),
        .sw(sw),
        .RegDST(RegDST),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .I_format(I_format),
        .R_format(R_format),
        .Sftmd(Sftmd),
        .ALUOp(ALUOp),
        .MemorIOtoReg(MemorIOtoReg),
        .MemRead(MemRead),
        .IORead(IORead),
        .IOWrite(IOWrite)
    );
    
    // decoder 解码
    wire[31:0] imme_extend;
//    wire[31:0] data_mem,imme_extend;
//    wire[31:0] read_data_2;
    
    decoder decode(
        .clock(clock_new),
        .reset(rst),
        .instruction(instruction),
        .data_mem(data_mem),
        .result_alu(alu_result),
        .jal(jal),
        .RegWrite(RegWrite),
        .MemtoReg(MemorIOtoReg),
        .RegDst(RegDST),
        .pc(pc_out),
        .read_data_1(addr_from_mem),
        .read_data_2(read_data_2),
        .imme_extend(imme_extend)
    );
    
    // execute  执行
    
    execute exe(
        .Read_data_1(addr_from_mem),
        .Read_data_2(read_data_2),
        .Imme_extend(imme_extend),
        .instruction(instruction),
        .pc(pc_out),
        .ALUOp(ALUOp),
        .ALUSrc(ALUSrc),
        .I_format(I_format),
        .Sftmd(Sftmd),
        .Jr(jr),
        .Zero(Zero),
        .result_alu(alu_result),
        .result_addr(addr_from_alu)
    );
    
    // memory  内存的写入读出
    wire [31:0] addr_out;
    wire [31:0] m_wdata;
    wire [31:0] read_data;
    
    dememory mem(
        .clock(clock_new),
        .address(addr_out),
        .Memwrite(MemWrite),
        .write_data(m_wdata),
        .read_data(read_data),
        .upg_clk_i(upg_clk_o),
        .upg_wen_i(upg_wen_o&upg_adr_o[14]),
        .upg_adr_i(upg_adr_o),
        .upg_dat_i(upg_dat_o),
        .upg_done_i(upg_done_o),
        .upg_rst_i(upg_rst) 
    );
    
    
    // IO 噜啦噜啦噜，噜啦噜啦咧
    wire LEDCtrl;
    wire SwitchCtrl;
    wire [15:0] io_rdata;
    wire [15:0] io_wdata;
    MemOrIO morio(
        .mRead(MemRead),
        .mWrite(MemWrite),
        .ioRead(IORead),
        .ioWrite(IOWrite),
        .addr_in(alu_result),
        .addr_out(addr_out),
        .m_rdata(read_data),
        .io_rdata(io_rdata),
        .r_wdata(data_mem),
        .r_rdata(read_data_2),
        .m_wdata(m_wdata),
        .io_wdata(io_wdata),
        .LEDCtrl(LEDCtrl),
        .SwitchCtrl(SwitchCtrl)
    );
    
    switch switch_control(
        .clock(clock_new),
        .rst(rst),
        .switchaddr(alu_result[1:0]),
        .switchread(IORead),
        .switch_i(switch),
        .switchrdata_out(io_rdata)
    );
    
    led led_control(
        .clock(clock_new),
        .rst(rst),
        .ledwrite(IOWrite),
        .ledcs(LEDCtrl),
        .ledaddr(alu_result[1:0]),
        .ledwdata(io_wdata),
        .ledout(leds)
    );
    assign ledaddr=alu_result[1:0];
    
    
endmodule