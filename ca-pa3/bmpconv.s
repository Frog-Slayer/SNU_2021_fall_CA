#----------------------------------------------------------------
#
#  4190.308 Computer Architecture (Fall 2021)
#
#  Project #3: Image Convolution in RISC-V Assembly
#
#  October 25, 2021
#
#  Jaehoon Shim (mattjs@snu.ac.kr)
#  Ikjoon Son (ikjoon.son@snu.ac.kr)
#  Seongyeop Jeong (seongyeop.jeong@snu.ac.kr)
#  Systems Software & Architecture Laboratory
#  Dept. of Computer Science and Engineering
#  Seoul National University
#
#----------------------------------------------------------------

####################
# void bmpconv(unsigned char *imgptr, int h, int w, unsigned char *k, unsigned char *outptr)
####################

####################
# Restriction : use only x0, sp, ra, a0 ~ a4, t0 ~ t4
# cpi is fixed to 1.0 ==> just reduce the # of instructions
####################

	.globl bmpconv
bmpconv:
#--------------------------------------------------------------
# store given data
#---------------------------------------------------------------
	addi sp, sp, -200
	sw ra, 196(sp)
	sw a4, 16(sp) 
	sw a3, 12(sp)
	sw a2, 8(sp)
	sw a1, 4(sp)
	sw a0, 0(sp)

#---------------------------------------------------------------
# the # of bytes of each row should be a multiple of 4
# imgRowBytes = ((3 * w - 1) / 4 + 1 ) * 4 	  ====> with Padding
# outRowBytes = (((3*(w -2)) -1) / 4 + 1) * 4 ====> with Padding
#---------------------------------------------------------------
	add t0, a2, a2
	add t0, t0, a2
	addi t1, t0, -6
	sw t1, 20(sp)						#아웃풋의 행 non-padding byte 수
	addi t1, t1, -1
	addi t0, t0, -1
	srli t1, t1, 2
	srli t0, t0, 2
	addi t1, t1, 1
	addi t0, t0, 1
	slli t1, t1, 2
	slli t0, t0, 2
	sw t0, 24(sp)						#이미지의 행 Bytes 수
	sw t1, 28(sp)						#아웃풋의 행 Bytes 수 
	add a2, a4, x0						#현재 행 * 아웃풋 행 Bytes 수
#=================Weight 미리 구해서 stack에 저장===================
	addi t2, x0, 8
	
getWeight:
	blt t2, x0, getWeightOut
	andi t4, t2, 3				
	andi a4, t2, -4
	add t3, a3, a4
	lw t3, 0(t3)
	slli t4, t4, 3
	srl t3, t3, t4
	andi t3, t3, 0xFF
	slli t3, t3, 24
	srai t3, t3, 24
	slli t4, t2, 2
	addi t4, t4, 32
	add sp, sp, t4
	sw t3, 0(sp)
	sub sp, sp, t4
	addi t2, t2, -1
	j getWeight
getWeightOut:

#==============^위는 상수 시간 걸리니까 건드릴 거 없음======================
#====================================================================
	addi t3, a1, -3						#h -3
	lw a1, 24(sp)
	sub a4, a1, t1
	sw a4, 68(sp)
	lw a4, 28(sp)
	lw t1, 20(sp)
	sub a4, a4, t1
	sw a4, 72(sp)

rowLoop:
	blt t3, x0, rowExit					
	lw a3, 28(sp)
colLoop:								
	bge x0, a3, colExit
	lw t1, 72(sp)
	add t0, x0, x0						#t0; sum
	bge t1, a3, convEnd

ker22:
	slli t2, a1, 1
	add a0, a0, t2
	addi a0, a0, 6
	andi t2, a0, 3							# 하위 2비트 : 워드에서 몇 번째에 위치하고 있는지
	andi t4, a0, -4							# 나머지 : 몇 번째 워드인지 
	lw t4, 0(t4)							# 로드
	slli t2, t2, 3 							# n번째 byte ==> 8*n번째 비트
	srl t4, t4, t2							# 그만큼 오른쪽으로 이동
	andi a4, t4, 0xFF						# 제일 아래에 있는 한 바이트 가져옴
	lw t4, 64(sp)
	blt x0, t4, convAdd22
	beq t4, x0, ker21
	sub t0, t0, a4
	j ker21
convAdd22:
	add t0, t0, a4

ker21:
	addi a0, a0, -3
	lw t4, 60(sp)
	beq t4, x0, ker20
	blt x0, t4, convAdd21
	andi a4, a0, 3							
	andi t4, a0, -4							 
	lw t4, 0(t4)							 
	slli a4, a4, 3 							
	srl t4, t4, a4							
	andi t4, t4, 0xFF						
	sub t0, t0, t4
	j ker20
convAdd21:
	andi a4, a0, 3						
	andi t4, a0, -4						
	lw t4, 0(t4)						
	slli a4, a4, 3 						
	srl t4, t4, a4						
	andi t4, t4, 0xFF		
	add t0, t0, t4
	
ker20:
	addi a0, a0, -3
	andi t1, a0, 3							
	andi t4, a0, -4							
	lw a4, 0(t4)							
	slli t1, t1, 3 							
	srl a4, a4, t1							
	andi a4, a4, 0xFF						
	lw t4, 56(sp)
	blt t4, x0, convSub20
	beq t4, x0, ker12
	add t0, t0, a4
	j ker12
convSub20:
	sub t0, t0, a4

ker12:
	sub a0, a0, a1
	addi a0, a0, 6
	lw t4, 52(sp)
	beq t4, x0, ker11
	blt x0, t4, convAdd12
	andi a4, a0, 3							
	andi t4, a0, -4							 
	lw t4, 0(t4)							 
	slli a4, a4, 3 							 
	srl t4, t4, a4							 
	andi t4, t4, 0xFF						# 제일 아래에 있는 한 바이트 가져옴
	sub t0, t0, t4
	j ker11
convAdd12:
	andi a4, a0, 3						
	andi t4, a0, -4						
	lw t4, 0(t4)						
	slli a4, a4, 3 						
	srl t4, t4, a4						
	andi t4, t4, 0xFF		
	add t0, t0, t4
ker11:
	addi a0, a0, -3
	lw t4, 48(sp)
	beq t4, x0, ker10
	blt x0, t4, convAdd11
	andi a4, a0, 3							
	andi t4, a0, -4							 
	lw t4, 0(t4)							 
	slli a4, a4, 3 							 
	srl t4, t4, a4							 
	andi t4, t4, 0xFF						# 제일 아래에 있는 한 바이트 가져옴
	sub t0, t0, t4
	j ker10
convAdd11:
	andi a4, a0, 3						
	andi t4, a0, -4						
	lw t4, 0(t4)						
	slli a4, a4, 3 						
	srl t4, t4, a4						
	andi t4, t4, 0xFF		
	add t0, t0, t4
ker10:
	addi a0, a0, -3
	lw t4, 44(sp)
	beq t4, x0, ker02
	blt x0, t4, convAdd10
	andi t1, a0, 3							
	andi t4, a0, -4							 
	lw t4, 0(t4)							 
	slli t1, t1, 3 							 
	srl t4, t4, t1							 
	andi t4, t4, 0xFF						# 제일 아래에 있는 한 바이트 가져옴
	sub t0, t0, t4
	j ker02
convAdd10:
	andi t1, a0, 3						
	andi t4, a0, -4						
	lw t4, 0(t4)						
	slli t1, t1, 3 						
	srl t4, t4, t1						
	andi t4, t4, 0xFF		
	add t0, t0, t4
ker02:
	sub a0, a0, a1
	addi a0, a0, 6
	lw t4, 40(sp)
	blt t4, x0, convSub02
	beq t4, x0, ker01
	andi t4, a0, -4							
	lw t4, 0(t4)							
	srl t4, t4, t2							
	andi t4, t4, 0xFF						
	add t0, t0, t4
	j ker01
convSub02:
	andi t4, a0, -4						
	lw t4, 0(t4)						
	srl t4, t4, t2						
	andi t4, t4, 0xFF		
	sub t0, t0, t4

ker01:
	addi a0, a0, -3
	lw t4, 36(sp)
	beq t4, x0, ker00
	blt x0, t4, convAdd01
	andi t2, a0, 3							
	andi t4, a0, -4							
	lw t4, 0(t4)							
	slli t2, t2, 3 							
	srl t4, t4, t2							
	andi t4, t4, 0xFF						
	sub t0, t0, t4
	j ker00
convAdd01:
	andi t2, a0, 3						
	andi t4, a0, -4						
	lw t4, 0(t4)						
	slli t2, t2, 3 						
	srl t4, t4, t2						
	andi t4, t4, 0xFF		
	add t0, t0, t4
ker00:
	addi a0, a0, -3
	lw t4, 32(sp)
	blt x0, t4, convAdd00
	beq t4, x0, convEnd
	andi t1, a0, 3							
	andi t4, a0, -4							 
	lw t4, 0(t4)							 
	slli t1, t1, 3 							 
	srl t4, t4, t1							 
	andi t4, t4, 0xFF						# 제일 아래에 있는 한 바이트 가져옴
	sub t0, t0, t4
	j convEnd
convAdd00:
	andi t1, a0, 3						
	andi t4, a0, -4						
	lw t4, 0(t4)						
	slli t1, t1, 3 						
	srl t4, t4, t1						
	andi t4, t4, 0xFF		
	add t0, t0, t4
convEnd:

#==============saturation arithmetuc=============
	#t0 is the sum
	bge x0, t0, satLower			
	addi t2, x0, 0xFF
	bge t2, t0, satUpper
	add t0, x0, t2
	j satUpper
satLower:
	add t0, x0, x0						#sum < 0 ==> sum = 0
satUpper:
#==================save output===================
	andi t2, a2, 3				# word에서 몇 번째?
	andi t1, a2, -4				# 몇번째 word?
	slli t2, t2, 3				# n번째 byte ==> n*8 bit
	addi t4, x0, 0xFF			# mask 만들기
	sll t0, t0, t2				# 그만큼 왼쪽으로 이동
	sll t4, t4, t2
	xori t4, t4, -1				# mask 1...1001...1
	lw t2, 0(t1)
	and t2, t2, t4				# 들어갈 자리를 00으로 만들어줌
	or t4, t2, t0				# 넣어주기
	sw t4, 0(t1)
#===============================================
	addi a2, a2, 1
	addi a3, a3, -1
	addi a0, a0, 1
	j colLoop

colExit:

	lw t0, 68(sp)
	add a0, a0, t0
	addi t3, t3, -1
	j rowLoop

rowExit:
	lw a0, 0(sp)
	lw a1, 4(sp)
	lw a2, 8(sp)
	lw a3, 12(sp)
	lw a4, 16(sp) 
	lw ra, 196(sp)
	addi sp, sp, 200
	ret

#============================================================================