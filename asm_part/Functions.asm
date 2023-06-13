.include "macros.asm"

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
#�޸ļĴ�����$a1
#����״̬���ϰ����
get_enter_info_a:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t0, $t0, 4
	andi $a1, $t0, 1
	load_ra()
	jr $ra
	
	
#���ܣ���Switch(17~24)����ַ��0xFFFFFC72��������λ���ж�b�Ƿ�������ϣ�0-δ������ϣ�1-������ϣ�
#�޸ļĴ�����$a2
#����״̬���ϰ����
get_enter_info_b:
	save_ra()
	lw $t0, 0x72($gp)
	srl $t0, $t0, 3
	andi $a2, $t0, 1
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
	
#���ܣ�����1��a���ۼӺ�
#�޸ļĴ�����v0,t0(�ݹ����)
#���ؽ����v0
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
		

#���ܣ�����1��a���ۼӺ�,����ʾ��ջ����
#�޸ļĴ�����v0,t0(�ݹ����)
#���ؽ����v0
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
		
		
#���ܣ�����1��a���ۼӺ�,����ʾ��ջ����
#�޸ļĴ�����v0,t0(�ݹ����)
#���ؽ����v0
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

#���ܣ�����Switch(1~16)��0xFFFFFC70�����Ͱ�λ���������źţ�������$k0�Ĵ�����
#�޸ļĴ�����$k0
read_a:
	save_ra()
	while_read_a:
		jal get_case_num
		beq $a0, $a3, check_enter_finish_a #��read������case_number�ı�,�򷵻س������
			load_ra()#Ŀ����Ҫ����spָ�����
			j begin
		check_enter_finish_a:
		jal get_enter_info_a #�ж�a�����Ƿ����
		beq $a1, $zero, while_read_a
	lw $t0, 0x70($gp)
	andi $k0, $t0, 0xFF #ȡ�Ͱ�λ
	load_ra()
	jr $ra
	
	
#���ܣ�����Switch(1~16)��0xFFFFFC70�����߰�λ���������źţ�������$k1�Ĵ�����
#�޸ļĴ�����$k1
read_b:
	save_ra()
	while_read_b:
		jal get_case_num
		beq $a0, $a3, check_enter_finish_b #��read������case_number�ı�,�򷵻س������
			load_ra()#Ŀ����Ҫ����spָ�����
			j begin
		check_enter_finish_b:
		jal get_enter_info_b #�ж������Ƿ����
		beq $a2, $zero, while_read_b
	lw $t0, 0x70($gp)
	andi $t0, $t0, 0x0000FF00 #ȡ�߰�λ
	srl $t0, $t0, 8 #ͳһ��0x000000FF��ʽ
	move $k1, $t0
	load_ra()
	jr $ra

	
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


