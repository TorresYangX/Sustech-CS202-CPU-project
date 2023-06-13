.data
.text
.globl main

##################################################### begin_macro ###################################################
#功能：初始化全局寄存器,清空所有显示
#修改寄存器：gp, sp, fp
#测试状态：mars可信, 上板可信
.macro Initialization()
	lui $1, 0xFFFF
	ori $28, $1, 0xFC00
	lui $1, 0x0000
	ori $29, $1, 0x0100 # 栈指针
	lui $1, 0x0000
	ori $30, $1, 0x0200 #栈基址
.end_macro 


#功能：让CPU 睡眠msec毫秒。
#修改寄存器：null
#测试状态：mars可信（时间过高需调小）, 上板可信
.macro sleep(%msec)
	la $t3, %msec
	sll $t1 $t3 4  
	sll $t0 $t3 3
	add $t0 $t0 $t1 
	sub $t3 $t0 $t3 
	sll $t1 $t3 10 
	sll $t2 $t3 4  
	sll $t0 $t3 3
	sub $t3 $t1 $t2
	sub $t3 $t3 $t0
	_sleep:
	addi $t3 $t3 -1
	bne $t3 $zero _sleep
.end_macro 


#功能：设置s1-s7的值为1-7
#修改寄存器：s1-s7
#测试状态：mars可信,上板可信
.macro set_constant_oneToSeven()
	li $s1, 1
	li $s2, 2
	li $s3, 3
	li $s4, 4
	li $s5, 5
	li $s6, 6
	li $s7, 7
.end_macro


#功能：保存当前ra，sp指针移向下一位
#修改寄存器：s4++
#测试状态：mars可信，问题很大
.macro save_ra()
	addi $t5, $s4, 1
	addu $s4, $t5, $0
	sw $ra, 0($sp)
	addi $t5, $sp, -4
	addu $sp, $t5, $0
.end_macro 
	
	
#功能：sp指针移向上一位并读取上一次储存的ra
#修改寄存器：s5++
#测试状态：mars可信，问题很大
.macro load_ra()
	addi $t5, $s5, 1
	addu $s5, $t5, $0
	addi $t5, $sp, 4
	addu $sp, $t5, $0
	lw $ra, 0($sp)
.end_macro 
	
	
#功能：保存当前reg，sp指针移向下一位
#修改寄存器：s4++
#测试状态：mars可信, 问题很大
.macro save_reg(%reg)
	addi $t5, $s4, 1
	addu $s4, $t5, $0
	sw %reg, 0($sp)
	addi $t5, $sp, -4
	addu $sp, $t5, $0
.end_macro 
	
			
#功能：sp指针移向上一位并读取上一次储存的reg的内容
#修改寄存器：%reg,s5++
#测试状态：mars可信，问题很大
.macro load_reg(%reg)
	addi $t5, $s5, 1
	addu $s5, $t5, $0
	addi $t5, $sp, 4
	addu $sp, $t5, $0
	lw %reg, 0($sp)
.end_macro 
	

#初始化入栈次数和出栈次数
#修改寄存器:$s4, $s5
#测试状态：mars可信，上板可信
.macro init_s4_s5()
	li $s4, 0
	li $s5, 0
.end_macro 

	
#功能：将%reg转化为有符号数（前面补1）
#修改寄存器：%reg
# 测试状态：mars可信,上板应该可信
.macro to_signNUM(%reg)
	#判断最高位是1还是0
	andi $t0, %reg, 0x00000080
	beq $t0, $zero, pos_num_case
	neg_num_case:#负数:前面补1
		ori $t0, %reg, 0xFFFFFF00
		addu %reg, $t0, $0
	pos_num_case:#正数，不用补1
.end_macro 


#功能：获得%reg的符号位
#修改寄存器：$v0
#测试状态：mars可信,上板可信
.macro get_sign_bit(%reg)
	andi $v0, %reg, 0x00000080
.end_macro 


#功能：将负数转化为正数
#修改寄存器：自己
#测试状态：mars可信
.macro negToPos(%neg)
	nor $t0, %neg, $0
	addi %neg, $t0, 1
.end_macro 


#功能：实现乘法
#修改寄存器：v0
#结果返回在v0中
.macro multi(%multiplier, %multiplicand)
	get_sign_bit(%multiplier)
	addu $t5, $v0, $0 #t5:%multiplier 符号
	get_sign_bit(%multiplicand)
	addu $t6, $v0, $0 #t6:%multiplicand 符号
	xor $t7, $t6, $t5 #判断结果符号,t7
	beq $t5, $0, skip_multiplier_rev
		negToPos(%multiplier)
	skip_multiplier_rev:
	beq $t6, $0, skip_multiplicand_rev
		negToPos(%multiplicand)
	skip_multiplicand_rev:
	li $t0, 1 #常数1
	addu $t1, $0, %multiplier #t1:%multiplier
	addu $t2, $0, %multiplicand #t2:%multiplicand
	li $v0, 0 #结果在v0中
	mul_while:
		beq $t1, $0, end_mul_while
			andi $t3, $t1, 0x1
			bne $t3,$t0,out_mul_if 
				add $t4, $v0, $t2
				addu $v0, $0, $t4
			out_mul_if :
				sll $t4, $t2, 1
				addu $t2, $t4, $0
				srl $t4, $t1, 1
				addu $t1, $t4, $0
				j  mul_while
	end_mul_while:
		beq $t7, $0, skip_result_rev
			negToPos($v0)
	skip_result_rev:
.end_macro 


#功能：实现无符号数除法
#修改寄存器：a0,a1,s0
#结果返回：余数：$v1;商：$v0
.macro divide(%dividend, %divisor)
	 addu $a0, $0, %dividend #a0:dividend
	 addu $a1, $0, %divisor #a1: divisor
	 li $s0 0                 #$s0存储除数的低32位
    	 li $t2 0                 #$t2记录过程执行次数
    	 li $v0 0                 #$v0存储商
divv:
   	 slti $t1 $a1 1           #判断除数的高32位是否为0 若不为0被除数必定小于除数 直接进入移位部分           
    	 beq $t1 0 shift          
   	 sleu $t1 $s0 $a0         #判断除数是否大于余数 若大于直接进入移位部分            
   	 beq $t1 0 shift          
   	 sub $t7 $a0 $s0          #余数不小于除数 余数=余数-除数
   	 move $a0, $t7
shift:                       
   	 sll $t3 $v0 1            #商左移一位
   	 addu $v0 $t3, $0
   	 add $t3 $v0 $t1          #根据上面的判断情况对最后一位置位：若余数大于除数置1 否则置0
   	 addu $v0, $t3, $0
   	 andi $t1 $a1 1           #$t1取除数的高32位的最后一位
   	 srl $t3 $a1 1            #除数的高32位右移一位
   	 addu $a1, $t3 $0
   	 srl $t3 $s0 1            #除数的低32位右移一位
   	 addu $s0, $t3, $0
   	 sll $t3 $t1 31           #$t1左移31位
   	 addu $t1, $t3, $0
   	 or $t3 $s0 $t1           #将除数的低32位与$t1取或 这样便能将原先高32位最后一位成功右移到低32位
   	 addu $s0, $t3, $0
   	 addi $t3 $t2 1           #计数器加1
   	 addu $t2, $t3, $0
  	 slti $t1 $t2 33          #判断执行次数是否达到33次 若未达到进入下一次循环
   	 bne $t1 0  divv
   	 move $v1, $a0 #余数：$v1;商：$v0
 .end_macro 

##############################################################################################################################
		

#功能：修改s6的值
#参数：%reg_H(高八位), %reg_L（低八位）(均为：0x000000FF形式)
#修改寄存器：s6, 
#测试状态：mar可信，上板可信
.macro set_s6(%reg_H, %reg_L)
	sll $t1, %reg_H, 8
	or $s6, $t1, %reg_L
.end_macro 


#功能：在LED(17~24)中点亮第%bit位,只负责改s7
#参数：bit:1-8
#修改寄存器：s7
#测试状态：mars可信,上板可信
.macro set_s7(%register)
	addu $s7, $0, %register
.end_macro 

######################################################## end_macro ##########################################################

main:
	Initialization()
	jal flush
begin:
	Initialization()
input_case:
	jal get_enter_info
	jal get_case_num
	beq $a1, $0, input_case #判断case输入是否结束, 第六位
	move $a3, $a0 #设置a3储存当前case数，之后get_case_num会被多次调用
	set_constant_oneToSeven() #s1-s7依次存1-7
	beq $a3 $zero case0
    	beq $a3 $s1 case1
    	beq $a3 $s2 case2
    	beq $a3 $s3 case3
    	beq $a3 $s4 case4
    	beq $a3 $s5 case5
    	beq $a3 $s6 case6
    	beq $a3 $s7 case7
    	
case0:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	#判断a是正数还是负数
	andi $t0, $k0, 0x00000080
	beq $t0, $zero, case0_pos_num
	bne $t0, $zero, case0_neg_num
	case0_neg_num:
		jal shine
		j case0
	case0_pos_num:
		init_s4_s5()
		li $t0, 0
		li $v0, 0
		save_reg($zero)
		save_reg($zero)#将栈指针前移两位，避免第一次递归load时指针越界
		jal a_accumulate
		set_s6($v0, $k0)
		jal write_low
		j case0
case1:
	lw $t0, 0x70($gp)
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	init_s4_s5()
	li $t0, 0
	li $v0, 0
	save_reg($zero)
	save_reg($zero)#将栈指针前移两位，避免第一次递归load时指针越界
	jal a_accumulate
	add $t0, $s4, $s5
	set_s6($zero, $t0)
	jal write_low
	j case1
case2:
	lw $t0, 0x70($gp)
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	init_s4_s5()
	li $t7, 0
	li $v0, 0
	save_reg($zero)
	save_reg($zero)#将栈指针前移两位，避免第一次递归load时指针越界
	jal a_accumulate_show_in
	j case2
case3:
	lw $t0, 0x70($gp)
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	init_s4_s5()
	li $t7, 0
	li $v0, 0
	save_reg($zero)
	save_reg($zero)#将栈指针前移两位，避免第一次递归load时指针越界
	jal a_accumulate_show_out
    	j case3
case4:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	andi $t1, $t0, 0x0000FF00 #取高八位
	srl $k1, $t1, 8 #统一至0x000000FF形式
	get_sign_bit($k0)
	move $s0, $v0 #s0中存a的符号位
	get_sign_bit($k1)
	move $s1, $v0 #s1中存b的符号位
	add $t0, $k0, $k1 #a+b
	andi $s2, $t0, 0x000000FF #取结果的低八位
	set_s6($zero, $s2)
	jal write_low
	get_sign_bit($s2) #取结果的符号位,在v0中
	bne $s0, $s1, no_add_overflow
	beq $s0, $s1, may_add_overflow
	may_add_overflow:
		beq $v0, $s0, no_add_overflow
		bne $v0, $s0, add_overflow
		add_overflow:
			li $t0, 0x20
			set_s7($t0)
			jal write_high
			j case4
	no_add_overflow:
		set_s7($0)
		jal write_high
		j case4
case5:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	andi $t1, $t0, 0x0000FF00 #取高八位
	srl $k1, $t1, 8 #统一至0x000000FF形式
	get_sign_bit($k0)
	move $s0, $v0 #s0中存a的符号位
	get_sign_bit($k1)
	move $s1, $v0 #s1中存b的符号位
	sub $t2, $k0, $k1 #a-b
	andi $s2, $t2, 0x000000FF #取结果的低八位
	set_s6($zero, $s2)
	jal write_low
	get_sign_bit($s2) #取结果的符号位,在v0中
	beq $s0, $s1, no_sub_overflow
	bne $s0, $s1, may_sub_overflow
	may_sub_overflow:
		beq $v0, $s0, no_sub_overflow
		bne $v0, $s0, sub_overflow
		sub_overflow:
			li $t0, 0x20
			set_s7($t0)
			jal write_high
			j case5
	no_sub_overflow:
		set_s7($0)
		jal write_high
		j case5
		
case6:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	andi $t1, $t0, 0x0000FF00 #取高八位
	srl $k1, $t1, 8 #统一至0x000000FF形式
	move $s0, $k0 #s0中存a
	move $s1, $k1 #s1中存b
	to_signNUM($s0)
	to_signNUM($s1)
	multi($s0, $s1)
	andi $s6, $v0, 0x0000FFFF #取低十六位
	jal write_low
	j case6
	
case7:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #取低八位
	andi $t1, $t0, 0x0000FF00 #取高八位
	srl $k1, $t1, 8 #统一至0x000000FF形式
	move $s0, $k0 #s0中存a
	move $s1, $k1 #s1中存b
	to_signNUM($s0)
	to_signNUM($s1)
	divide($s0, $s1)
	andi $s6, $v0, 0x000000FF #商
	jal write_low
	sleep(2000)
	andi $s6, $v1, 0x000000FF #余数 
	jal write_low
	sleep(2000)
	j case7
	
############################################################ begin_functions ####################################################	
	
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

	
	
#功能：从Switch(17~24)（地址：0xFFFFFC72）（第五位）判断a是否输入完毕（0-未输入完毕；1-输入完毕）
#修改寄存器：$a2
#测试状态：上板可信
get_enter_info_a:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t1, $t0, 3
	andi $a2, $t1, 1
	load_ra()
	jr $ra
	

#功能：从Switch(17~24)（地址：0xFFFFFC72）（第六位）判断case_num是否输入完毕（0-未输入完毕；1-输入完毕）
#修改寄存器：$a1
#测试状态：上板可信
get_enter_info:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t1, $t0, 2
	andi $a1, $t1, 1
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
	
shine:
	li $t0, 0xFF
	set_s6($t0, $t0)
	jal write_low
	set_s7($t0)
	jal write_high
	sleep(1000)
	jr $ra
	
#功能：计算1到a的累加和
#修改寄存器：v0,t0(递归参数)
#返回结果：v0
a_accumulate:
	load_reg($t0)
	load_reg($v0)
	addi $t5, $t0, 1
	addu $t0, $t5, $0
	add $t5, $v0, $t0
	addu $v0, $t5, $0
	beq $t0, $k0, a_accumulate_end
		save_ra()
		save_reg($v0)
		save_reg($t0)
		jal a_accumulate
	a_accumulate_end:
		load_ra()
		jr $ra
		

#功能：计算1到a的累加和,并显示入栈参数
#修改寄存器：v0,t7(递归参数)
#返回结果：v0
a_accumulate_show_in:
	load_reg($t7)
	load_reg($v0)
	addi $t5, $t7, 1
	addu $t7, $t5, $0
	add $t5, $v0, $t7
	addu $v0, $t5, $0
	beq $t7, $k0, a_accumulate_show_in_end
		save_ra()
		save_reg($v0)
		set_s6($zero, $v0)
		jal write_low
		sleep(1000)
		save_reg($t7)
		set_s6($zero, $t7)
		jal write_low
		sleep(1000)
		jal a_accumulate_show_in
	a_accumulate_show_in_end:
		load_ra()
		jr $ra
		
		
#功能：计算1到a的累加和,并显示出栈参数
#修改寄存器：v0,t7(递归参数)
#返回结果：v0
a_accumulate_show_out:
	load_reg($t7)
	set_s6($zero, $t7)
	jal write_low
	sleep(1000)
	load_reg($v0)
	set_s6($zero, $v0)
	jal write_low
	sleep(1000)
	addi $t5, $t7, 1
	addu $t7, $t5, $0
	add $t5, $v0, $t7
	addu $v0, $t5, $0
	beq $t7, $k0, a_accumulate_show_out_end
		save_ra()
		save_reg($v0)
		save_reg($t7)
		jal a_accumulate_show_out
	a_accumulate_show_out_end:
		load_ra()
		jr $ra
		

############################# I_O Functions ######################################################
	
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
	
##################################################### end_function ################################################
