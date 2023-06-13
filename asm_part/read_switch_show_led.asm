.data    		
	buf: .word 0x0000
.text				
start: 
	lui   $1,0xFFFF			
        ori   $28,$1,0xF000		
switled:
	lw $1, 0xC70($28)
	addi $8, $1, 0x00000001
	sw $8, 0xC60($28)
	j switled