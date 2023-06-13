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
	sw $zero, 0x60($gp)
	sw $zero, 0x62($gp)
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
	addi $s4, $s4, 1
	sw $ra, 0($sp)
	addi $sp, $sp, -4
.end_macro 
	
	
#���ܣ�spָ��������һλ����ȡ��һ�δ����ra
#�޸ļĴ�����s5++
#����״̬��mars���ţ�����ܴ�
.macro load_ra()
	addi $s5, $s5, 1
	addi $sp, $sp, 4
	lw $ra, 0($sp)
.end_macro 
	
	
#���ܣ����浱ǰreg��spָ��������һλ
#�޸ļĴ�����s4++
#����״̬��mars����, ����ܴ�
.macro save_reg(%reg)
	addi $s4, $s4, 1
	sw %reg, 0($sp)
	addi $sp, $sp, -4
.end_macro 
	
			
#���ܣ�spָ��������һλ����ȡ��һ�δ����reg������
#�޸ļĴ�����%reg,s5++
#����״̬��mars���ţ�����ܴ�
.macro load_reg(%reg)
	addi $s5, $s5, 1
	addi $sp, $sp, 4
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
		ori %reg, %reg, 0xFFFFFF00
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
   	 sub $a0 $a0 $s0          #������С�ڳ��� ����=����-����
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

	

	
	
	
	
	
	
	
	
	
	
