.data
.text
.globl main

##################################################### begin_macro ###################################################
#���ܣ���ʼ��ȫ�ּĴ���,���������ʾ
#�޸ļĴ�����gp, sp, fp
#����״̬��mars����, �ϰ����
.macro Initialization()
	lui $1, 0xFFFF
	ori $28, $1, 0xFC00
	lui $1, 0x0000
	ori $29, $1, 0x0100 # ջָ��
	lui $1, 0x0000
	ori $30, $1, 0x0200 #ջ��ַ
.end_macro 


#���ܣ���CPU ˯��msec���롣
#�޸ļĴ�����null
#����״̬��mars���ţ�ʱ��������С��, �ϰ����
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


#���ܣ�����s1-s7��ֵΪ1-7
#�޸ļĴ�����s1-s7
#����״̬��mars����,�ϰ����
.macro set_constant_oneToSeven()
	li $s1, 1
	li $s2, 2
	li $s3, 3
	li $s4, 4
	li $s5, 5
	li $s6, 6
	li $s7, 7
.end_macro


#���ܣ����浱ǰra��spָ��������һλ
#�޸ļĴ�����s4++
#����״̬��mars���ţ�����ܴ�
.macro save_ra()
	addi $t5, $s4, 1
	addu $s4, $t5, $0
	sw $ra, 0($sp)
	addi $t5, $sp, -4
	addu $sp, $t5, $0
.end_macro 
	
	
#���ܣ�spָ��������һλ����ȡ��һ�δ����ra
#�޸ļĴ�����s5++
#����״̬��mars���ţ�����ܴ�
.macro load_ra()
	addi $t5, $s5, 1
	addu $s5, $t5, $0
	addi $t5, $sp, 4
	addu $sp, $t5, $0
	lw $ra, 0($sp)
.end_macro 
	
	
#���ܣ����浱ǰreg��spָ��������һλ
#�޸ļĴ�����s4++
#����״̬��mars����, ����ܴ�
.macro save_reg(%reg)
	addi $t5, $s4, 1
	addu $s4, $t5, $0
	sw %reg, 0($sp)
	addi $t5, $sp, -4
	addu $sp, $t5, $0
.end_macro 
	
			
#���ܣ�spָ��������һλ����ȡ��һ�δ����reg������
#�޸ļĴ�����%reg,s5++
#����״̬��mars���ţ�����ܴ�
.macro load_reg(%reg)
	addi $t5, $s5, 1
	addu $s5, $t5, $0
	addi $t5, $sp, 4
	addu $sp, $t5, $0
	lw %reg, 0($sp)
.end_macro 
	

#��ʼ����ջ�����ͳ�ջ����
#�޸ļĴ���:$s4, $s5
#����״̬��mars���ţ��ϰ����
.macro init_s4_s5()
	li $s4, 0
	li $s5, 0
.end_macro 

	
#���ܣ���%regת��Ϊ�з�������ǰ�油1��
#�޸ļĴ�����%reg
# ����״̬��mars����,�ϰ�Ӧ�ÿ���
.macro to_signNUM(%reg)
	#�ж����λ��1����0
	andi $t0, %reg, 0x00000080
	beq $t0, $zero, pos_num_case
	neg_num_case:#����:ǰ�油1
		ori $t0, %reg, 0xFFFFFF00
		addu %reg, $t0, $0
	pos_num_case:#���������ò�1
.end_macro 


#���ܣ����%reg�ķ���λ
#�޸ļĴ�����$v0
#����״̬��mars����,�ϰ����
.macro get_sign_bit(%reg)
	andi $v0, %reg, 0x00000080
.end_macro 


#���ܣ�������ת��Ϊ����
#�޸ļĴ������Լ�
#����״̬��mars����
.macro negToPos(%neg)
	nor $t0, %neg, $0
	addi %neg, $t0, 1
.end_macro 


#���ܣ�ʵ�ֳ˷�
#�޸ļĴ�����v0
#���������v0��
.macro multi(%multiplier, %multiplicand)
	get_sign_bit(%multiplier)
	addu $t5, $v0, $0 #t5:%multiplier ����
	get_sign_bit(%multiplicand)
	addu $t6, $v0, $0 #t6:%multiplicand ����
	xor $t7, $t6, $t5 #�жϽ������,t7
	beq $t5, $0, skip_multiplier_rev
		negToPos(%multiplier)
	skip_multiplier_rev:
	beq $t6, $0, skip_multiplicand_rev
		negToPos(%multiplicand)
	skip_multiplicand_rev:
	li $t0, 1 #����1
	addu $t1, $0, %multiplier #t1:%multiplier
	addu $t2, $0, %multiplicand #t2:%multiplicand
	li $v0, 0 #�����v0��
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


#���ܣ�ʵ���޷���������
#�޸ļĴ�����a0,a1,s0
#������أ�������$v1;�̣�$v0
.macro divide(%dividend, %divisor)
	 addu $a0, $0, %dividend #a0:dividend
	 addu $a1, $0, %divisor #a1: divisor
	 li $s0 0                 #$s0�洢�����ĵ�32λ
    	 li $t2 0                 #$t2��¼����ִ�д���
    	 li $v0 0                 #$v0�洢��
divv:
   	 slti $t1 $a1 1           #�жϳ����ĸ�32λ�Ƿ�Ϊ0 ����Ϊ0�������ض�С�ڳ��� ֱ�ӽ�����λ����           
    	 beq $t1 0 shift          
   	 sleu $t1 $s0 $a0         #�жϳ����Ƿ�������� ������ֱ�ӽ�����λ����            
   	 beq $t1 0 shift          
   	 sub $t7 $a0 $s0          #������С�ڳ��� ����=����-����
   	 move $a0, $t7
shift:                       
   	 sll $t3 $v0 1            #������һλ
   	 addu $v0 $t3, $0
   	 add $t3 $v0 $t1          #����������ж���������һλ��λ�����������ڳ�����1 ������0
   	 addu $v0, $t3, $0
   	 andi $t1 $a1 1           #$t1ȡ�����ĸ�32λ�����һλ
   	 srl $t3 $a1 1            #�����ĸ�32λ����һλ
   	 addu $a1, $t3 $0
   	 srl $t3 $s0 1            #�����ĵ�32λ����һλ
   	 addu $s0, $t3, $0
   	 sll $t3 $t1 31           #$t1����31λ
   	 addu $t1, $t3, $0
   	 or $t3 $s0 $t1           #�������ĵ�32λ��$t1ȡ�� �������ܽ�ԭ�ȸ�32λ���һλ�ɹ����Ƶ���32λ
   	 addu $s0, $t3, $0
   	 addi $t3 $t2 1           #��������1
   	 addu $t2, $t3, $0
  	 slti $t1 $t2 33          #�ж�ִ�д����Ƿ�ﵽ33�� ��δ�ﵽ������һ��ѭ��
   	 bne $t1 0  divv
   	 move $v1, $a0 #������$v1;�̣�$v0
 .end_macro 

##############################################################################################################################
		

#���ܣ��޸�s6��ֵ
#������%reg_H(�߰�λ), %reg_L���Ͱ�λ��(��Ϊ��0x000000FF��ʽ)
#�޸ļĴ�����s6, 
#����״̬��mar���ţ��ϰ����
.macro set_s6(%reg_H, %reg_L)
	sll $t1, %reg_H, 8
	or $s6, $t1, %reg_L
.end_macro 


#���ܣ���LED(17~24)�е�����%bitλ,ֻ�����s7
#������bit:1-8
#�޸ļĴ�����s7
#����״̬��mars����,�ϰ����
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
	beq $a1, $0, input_case #�ж�case�����Ƿ����, ����λ
	move $a3, $a0 #����a3���浱ǰcase����֮��get_case_num�ᱻ��ε���
	set_constant_oneToSeven() #s1-s7���δ�1-7
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
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	#�ж�a���������Ǹ���
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
		save_reg($zero)#��ջָ��ǰ����λ�������һ�εݹ�loadʱָ��Խ��
		jal a_accumulate
		set_s6($v0, $k0)
		jal write_low
		j case0
case1:
	lw $t0, 0x70($gp)
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	init_s4_s5()
	li $t0, 0
	li $v0, 0
	save_reg($zero)
	save_reg($zero)#��ջָ��ǰ����λ�������һ�εݹ�loadʱָ��Խ��
	jal a_accumulate
	add $t0, $s4, $s5
	set_s6($zero, $t0)
	jal write_low
	j case1
case2:
	lw $t0, 0x70($gp)
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	init_s4_s5()
	li $t7, 0
	li $v0, 0
	save_reg($zero)
	save_reg($zero)#��ջָ��ǰ����λ�������һ�εݹ�loadʱָ��Խ��
	jal a_accumulate_show_in
	j case2
case3:
	lw $t0, 0x70($gp)
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	init_s4_s5()
	li $t7, 0
	li $v0, 0
	save_reg($zero)
	save_reg($zero)#��ջָ��ǰ����λ�������һ�εݹ�loadʱָ��Խ��
	jal a_accumulate_show_out
    	j case3
case4:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	andi $t1, $t0, 0x0000FF00 #ȡ�߰�λ
	srl $k1, $t1, 8 #ͳһ��0x000000FF��ʽ
	get_sign_bit($k0)
	move $s0, $v0 #s0�д�a�ķ���λ
	get_sign_bit($k1)
	move $s1, $v0 #s1�д�b�ķ���λ
	add $t0, $k0, $k1 #a+b
	andi $s2, $t0, 0x000000FF #ȡ����ĵͰ�λ
	set_s6($zero, $s2)
	jal write_low
	get_sign_bit($s2) #ȡ����ķ���λ,��v0��
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
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	andi $t1, $t0, 0x0000FF00 #ȡ�߰�λ
	srl $k1, $t1, 8 #ͳһ��0x000000FF��ʽ
	get_sign_bit($k0)
	move $s0, $v0 #s0�д�a�ķ���λ
	get_sign_bit($k1)
	move $s1, $v0 #s1�д�b�ķ���λ
	sub $t2, $k0, $k1 #a-b
	andi $s2, $t2, 0x000000FF #ȡ����ĵͰ�λ
	set_s6($zero, $s2)
	jal write_low
	get_sign_bit($s2) #ȡ����ķ���λ,��v0��
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
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	andi $t1, $t0, 0x0000FF00 #ȡ�߰�λ
	srl $k1, $t1, 8 #ͳһ��0x000000FF��ʽ
	move $s0, $k0 #s0�д�a
	move $s1, $k1 #s1�д�b
	to_signNUM($s0)
	to_signNUM($s1)
	multi($s0, $s1)
	andi $s6, $v0, 0x0000FFFF #ȡ��ʮ��λ
	jal write_low
	j case6
	
case7:
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	andi $t1, $t0, 0x0000FF00 #ȡ�߰�λ
	srl $k1, $t1, 8 #ͳһ��0x000000FF��ʽ
	move $s0, $k0 #s0�д�a
	move $s1, $k1 #s1�д�b
	to_signNUM($s0)
	to_signNUM($s1)
	divide($s0, $s1)
	andi $s6, $v0, 0x000000FF #��
	jal write_low
	sleep(2000)
	andi $s6, $v1, 0x000000FF #���� 
	jal write_low
	sleep(2000)
	j case7
	
############################################################ begin_functions ####################################################	
	
################################## Normal Functions #################################################

#���ܣ���Switch(17~24)����ַ��0xFFFFFC72���������루����λ������case_num����$a0�з���
#�޸ļĴ�����$a0
#����״̬���ϰ����
get_case_num:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t1, $t0, 5
	move $a0, $t1
	load_ra()
	jr $ra

	
	
#���ܣ���Switch(17~24)����ַ��0xFFFFFC72��������λ���ж�a�Ƿ�������ϣ�0-δ������ϣ�1-������ϣ�
#�޸ļĴ�����$a2
#����״̬���ϰ����
get_enter_info_a:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t1, $t0, 3
	andi $a2, $t1, 1
	load_ra()
	jr $ra
	

#���ܣ���Switch(17~24)����ַ��0xFFFFFC72��������λ���ж�case_num�Ƿ�������ϣ�0-δ������ϣ�1-������ϣ�
#�޸ļĴ�����$a1
#����״̬���ϰ����
get_enter_info:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t1, $t0, 2
	andi $a1, $t1, 1
	load_ra()
	jr $ra


#���ܣ���żλЧ��
#�Ĵ�����a0Ϊ��������a0������żЧ��	
#�޸ļĴ�����v0(even_odd_judge����), 0-ż��1-��
#����״̬:�ϰ����
Parity_test:
	save_ra()
	li $t0, 0#1�ĸ���
	li $t1, 1#���Ƚϵı�׼1
	li $t2, 0#����Ƚ�λ����
	li $t3, 8
	Parity_test_loop:
		andi $t4, $a0, 1#ȡ��һλ
		bne $t4, $t1, next_bit
		addi $t0, $t0, 1
		next_bit:
		srl $a0, $a0, 1
		addi $t2, $t2, 1
	bne $t2, $t3, Parity_test_loop
	andi $v0, $t0, 0x00000001
	load_ra()
	jr $ra


#���ܣ���˸led
#�޸ļĴ�����t8
#����״̬��
flush:
	save_ra()
	li $t8, 0x000000FF
	set_s6($0, $t8) #0-7��
	jal write_low
	sleep(1000)
	set_s6($t8, $zero)#8-16��
	jal write_low
	sleep(1000)
	set_s6($0, $0)
	jal write_low
	set_s7($t8)#17-24��
	jal write_high
	sleep(1000)
	set_s7($0)#ȫ��
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
	
#���ܣ�����1��a���ۼӺ�
#�޸ļĴ�����v0,t0(�ݹ����)
#���ؽ����v0
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
		

#���ܣ�����1��a���ۼӺ�,����ʾ��ջ����
#�޸ļĴ�����v0,t7(�ݹ����)
#���ؽ����v0
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
		
		
#���ܣ�����1��a���ۼӺ�,����ʾ��ջ����
#�޸ļĴ�����v0,t7(�ݹ����)
#���ؽ����v0
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
	
#���ܣ�����s7��ֵд��led(17-24)	
#�޸ļĴ�����null
write_high:
	save_ra()
	sw $s7, 0x62($gp)
	load_ra()
	jr $ra
	
	
#���ܣ�����s6��ֵд��led(1-16)	
#�޸ļĴ�����null
write_low:
	save_ra()
	sw $s6, 0x60($gp)
	load_ra()
	jr $ra
	

#���ܣ���led(17-24)(���λ)��ʾ��żУ����
#������a0
#�޸ļĴ�����v0
write_parity_bit:
	save_ra()
	jal Parity_test #����Ϊa0
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

		
#���ܣ���led(17-24)(23λ)��ʾa<b�ȽϽ��,��Ҫ������Ƚϳ����������a0��
#������a0��a0Ϊ1��ʾa<b��a0Ϊ0��ʾa>=b.��ʾa0�����ݣ�
#�޸ļĴ�����null
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
