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
	sw $zero, 0x60($gp)
	sw $zero, 0x62($gp)
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
	addi $s4, $s4, 1
	sw $ra, 0($sp)
	addi $sp, $sp, -4
.end_macro 
	
	
#功能：sp指针移向上一位并读取上一次储存的ra
#修改寄存器：s5++
#测试状态：mars可信，问题很大
.macro load_ra()
	addi $s5, $s5, 1
	addi $sp, $sp, 4
	lw $ra, 0($sp)
.end_macro 
	
	
#功能：保存当前reg，sp指针移向下一位
#修改寄存器：s4++
#测试状态：mars可信, 问题很大
.macro save_reg(%reg)
	addi $s4, $s4, 1
	sw %reg, 0($sp)
	addi $sp, $sp, -4
.end_macro 
	
			
#功能：sp指针移向上一位并读取上一次储存的reg的内容
#修改寄存器：%reg,s5++
#测试状态：mars可信，问题很大
.macro load_reg(%reg)
	addi $s5, $s5, 1
	addi $sp, $sp, 4
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
		ori %reg, %reg, 0xFFFFFF00
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
   	 sub $a0 $a0 $s0          #余数不小于除数 余数=余数-除数
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

	

	
	
	
	
	
	
	
	
	
	
