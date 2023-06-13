.include "macros.asm"

################################## Normal Functions #################################################

#功能：从Switch(17~24)（地址：0xFFFFFC72）读出输入（高三位）并将case_num存在$a0中返回
#修改寄存器：$a0
#测试状态：上板可信
get_case_num:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t1, $t0, 5
	move $a0, $t1
	load_ra()
	jr $ra


#功能：从Switch(17~24)（地址：0xFFFFFC72）（第四位）判断a是否输入完毕（0-未输入完毕；1-输入完毕）
#修改寄存器：$a1
#测试状态：上板可信
get_enter_info_a:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t0, $t0, 4
	andi $a1, $t0, 1
	load_ra()
	jr $ra
	
	
#功能：从Switch(17~24)（地址：0xFFFFFC72）（第五位）判断b是否输入完毕（0-未输入完毕；1-输入完毕）
#修改寄存器：$a2
#测试状态：上板可信
get_enter_info_b:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t0, $t0, 3
	andi $a2, $t0, 1
	load_ra()
	jr $ra


#功能：奇偶位效验
#寄存器：a0为参数，对a0进行奇偶效验	
#修改寄存器：v0(even_odd_judge导致), 0-偶，1-奇
#测试状态:上板可信
Parity_test:
	save_ra()
	li $t0, 0#1的个数
	li $t1, 1#被比较的标准1
	li $t2, 0#计算比较位次数
	li $t3, 8
	Parity_test_loop:
		andi $t4, $a0, 1#取第一位
		bne $t4, $t1, next_bit
		addi $t0, $t0, 1
		next_bit:
		srl $a0, $a0, 1
		addi $t2, $t2, 1
	bne $t2, $t3, Parity_test_loop
	andi $v0, $t0, 0x00000001
	load_ra()
	jr $ra


#功能：闪烁led
#修改寄存器：t8
#测试状态：
flush:
	save_ra()
	li $t8, 0x000000FF
	set_s6($0, $t8) #0-7亮
	jal write_low
	sleep(1000)
	set_s6($t8, $zero)#8-16亮
	jal write_low
	sleep(1000)
	set_s6($0, $0)
	jal write_low
	set_s7($t8)#17-24亮
	jal write_high
	sleep(1000)
	set_s7($0)#全灭
	jal write_high
	sleep(1000)
	load_ra()
	jr $ra
	
#功能：计算1到a的累加和
#修改寄存器：v0,t0(递归参数)
#返回结果：v0
a_accumulate:
	load_reg($t0)
	load_reg($v0)
	addi $t0, $t0, 1
	add $v0, $v0, $t0
	beq $t0, $k0, a_accumulate_end
		save_ra()
		save_reg($v0)
		save_reg($t0)
		jal a_accumulate
	a_accumulate_end:
		load_ra()
		jr $ra
		

#功能：计算1到a的累加和,并显示入栈参数
#修改寄存器：v0,t0(递归参数)
#返回结果：v0
a_accumulate_show_in:
	load_reg($t0)
	load_reg($v0)
	addi $t0, $t0, 1
	add $v0, $v0, $t0
	beq $t0, $k0, a_accumulate_show_in_end
		save_ra()
		save_reg($v0)
		set_s6($zero, $v0)
		jal write_low
		sleep(3000)
		save_reg($t0)
		set_s6($zero, $t0)
		jal write_low
		sleep(3000)
		jal a_accumulate_show_in
	a_accumulate_show_in_end:
		load_ra()
		jr $ra
		
		
#功能：计算1到a的累加和,并显示出栈参数
#修改寄存器：v0,t0(递归参数)
#返回结果：v0
a_accumulate_show_out:
	load_reg($t0)
	set_s6($zero, $t0)
	jal write_low
	sleep(3000)
	load_reg($v0)
	set_s6($zero, $v0)
	jal write_low
	sleep(3000)
	addi $t0, $t0, 1
	add $v0, $v0, $t0
	beq $t0, $k0, a_accumulate_show_out_end
		save_ra()
		save_reg($v0)
		save_reg($t0)
		jal a_accumulate_show_out
	a_accumulate_show_out_end:
		load_ra()
		jr $ra
		

############################# I_O Functions ######################################################

#功能：读入Switch(1~16)（0xFFFFFC70）（低八位）的输入信号，并存在$k0寄存器中
#修改寄存器：$k0
read_a:
	save_ra()
	while_read_a:
		jal get_case_num
		beq $a0, $a3, check_enter_finish_a #若read过程中case_number改变,则返回程序起点
			load_ra()#目的主要是让sp指针回移
			j begin
		check_enter_finish_a:
		jal get_enter_info_a #判断a输入是否结束
		beq $a1, $zero, while_read_a
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	load_ra()
	jr $ra
	
	
#功能：读入Switch(1~16)（0xFFFFFC70）（高八位）的输入信号，并存在$k1寄存器中
#修改寄存器：$k1
read_b:
	save_ra()
	while_read_b:
		jal get_case_num
		beq $a0, $a3, check_enter_finish_b #若read过程中case_number改变,则返回程序起点
			load_ra()#目的主要是让sp指针回移
			j begin
		check_enter_finish_b:
		jal get_enter_info_b #判断输入是否结束
		beq $a2, $zero, while_read_b
	lw $t0, 0x70($gp)
	andi $t0, $t0, 0x0000FF00 #取高八位
	srl $t0, $t0, 8 #统一至0x000000FF形式
	move $k1, $t0
	load_ra()
	jr $ra

	
#功能：根据s7的值写入led(17-24)	
#修改寄存器：null
write_high:
	save_ra()
	sw $s7, 0x62($gp)
	load_ra()
	jr $ra
	
	
#功能：根据s6的值写入led(1-16)	
#修改寄存器：null
write_low:
	save_ra()
	sw $s6, 0x60($gp)
	load_ra()
	jr $ra
	

#功能：在led(17-24)(最高位)显示奇偶校验结果
#参数：a0
#修改寄存器：v0
write_parity_bit:
	save_ra()
	jal Parity_test #参数为a0
	li $t0, 1
	beq $v0, $zero ,even_case
	beq $v0, $t1, odd_case
	even_case:
		li $t0, 0x80
		set_s7($t0)
		jal write_high
		j end_odd_even_case
	odd_case:
		li $t0, 0x00
		set_s7($t0)
		jal write_high
		j end_odd_even_case
	end_odd_even_case:
	load_ra()
	jr $ra

		
#功能：在led(17-24)(23位)显示a<b比较结果,需要在外面比较出结果并存在a0中
#参数：a0（a0为1表示a<b；a0为0表示a>=b.显示a0的内容）
#修改寄存器：null
write_compare_bit:
	save_ra()
	bne $a0, $zero, aLb_case
	beq $a0, $zero, not_aLb_case
	aLb_case:
		li $t0, 0x40
		set_s7($t0)
		jal write_high
		j end_aLb_case
	not_aLb_case:
		li $t0, 0x00
		set_s7($t0)
		jal write_high
		j end_aLb_case
	end_aLb_case:
	load_ra()
	jr $ra


