	.include "display.asm"

	.data

GEN_A:	.space 256
GEN_B:	.space 256
GEN_Z:	.space 256

# Students may modify the ".data" and "main" section temporarily
# for their testing. However, when evaluating your submission, all
# code from lines 1 to 58 will be replaced by other testing code
# (i.e., we will only keep code from lines 59 onward). If your
# solution breaks because you have ignored this note, then a mark
# of zero for Part 4 of the assignment is possible.

PATTERN_GLIDER:
	.word   0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000
        	0x0000 0x0000 0x0000 0x0000 0x0e00 0x0200 0x0400 0x0000

PATTERN_PULSAR:
	.word 	0x0000 0x0e38 0x0000 0x2142 0x2142 0x2142 0x0e38 0x0000
		0x0e38 0x2142 0x2142 0x2142 0x0000 0x0e38 0x0000 0x0000

PATTERN_PIPSQUIRTER:
	.word   0x0000 0x0020 0x0020 0x0000 0x0088 0x03ae 0x0431 0x0acd
        	0x0b32 0x6acc 0x6a90 0x06f0 0x0100 0x0140 0x00c0 0x0000

PATTERN_HONEYCOMB:
	.word   0x0000 0x0000 0x0000 0x0000 0x0000 0x0180 0x0240 0x05a0
        	0x0240 0x0180 0x0000 0x0000 0x0000 0x0000 0x0000 0x0000

PATTERN_EATER:
	.word   0x0000 0x0000 0x1800 0x24c0 0x2848 0x1054 0x0348 0x0240
        	0x1080 0x1f00 0x0000 0x0400 0x0a00 0x0407 0x0004 0x0002

	.globl main


	.text
main:
	la $a0, GEN_A
	la $a1, PATTERN_PULSAR
	jal bitmap_to_16x16		# Convert bitmap pattern...

	la $a0, GEN_A
	jal draw_16x16			# ... and draw it.

next_gen:
	jal life_next_generation	# Procedure uses 16x16 0/1 "dead/alive" data in GEN_A ...
	la $a0, GEN_A			# ... and then proceeds to draw the result ...
	jal draw_16x16

	addi $a0, $zero, 750		# 750 milliseconds (three-quarters of a second)
	addi $v0, $zero, 32		# sleep system call
	syscall

	beq $zero, $zero, next_gen	# ... over and over again. Comment out this line if
					# you just want to try life_next_generation once during testing.

	addi $v0, $zero, 10
	syscall


# STUDENTS MAY MODIFY CODE BELOW
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

	.data
	.eqv	PIXEL_ON  0x00ffffff
	.eqv	PIXEL_OFF 0x00000000

	GEN_L:	.space 256


# Available for any extra `.eqv` or data needed for your solution.

	.text


# life_next_generation:
#
# This procedure HAS NO PARAMETERS.
#
# Use GEN_A as the generation to draw
#
# Use GEN_B as a scratch array to compute the
# next generation (i.e., compute the value
# of the next generation in GEN_B, and once
# completed, copy over GEN_B into GEN_A

life_next_generation:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, GEN_A
	li $a1, 0		# row
	li $a2, 0		# column

life_gen_loop:
	or $t6, $a1, $zero	# $t6: copy of row
	or $t8, $a2, $zero	# $t8: copy of column
	jal sum_neighbours	# $v0 now holds the sum of neighbouring elements
	or $a1, $t6, $zero	# $a1: row
	or $a2, $t8, $zero	# $a2: column
	la $a0, GEN_A

	bne $a2, 16, is_two	# if you haven't reached the end of the line, check $v0

	li $a2, 0		# reset column counter to 0
	addi $a1, $a1, 1	# inc. row
	bne $a1, 16, life_gen_loop	# have you reached the end of the grid?

	j done_life_gen

is_two:
	bne $v0, 2, is_three
	or $s5, $v0, $zero	# $s5: sum of neighbours
	or $t6, $a1, $zero	# $t6: row
	or $t8, $a2, $zero	# $t8: column
	jal get_16x16
	or $a1, $t6, $zero	# $a1: row
	or $a2, $t8, $zero	# $a2: column
	beq $v0, 0, dead
	or $v0, $s5, $zero	# $v0: sum of neighbours
	j alive

is_three:
	bne $v0, 3, dead
	j alive

alive:
	la $a0, GEN_B		# set the value in GEN_B
	li $a3, 1
	or $t6, $a1, $zero	# $t6: row
	or $t8, $a2, $zero	# $t8: column
	jal set_16x16
	la $a0, GEN_A		# change the address to read from back to GEN_A
	or $a1, $t6, $zero	# $a1: row
	or $a2, $t8, $zero	# $a2: column
	li $v0, 0
	addi $a2, $a2, 1	# inc. column counter
	j life_gen_loop

dead:
	la $a0, GEN_B		# set the value in GEN_B
	li $a3, 0
	or $t6, $a1, $zero	# $t6: row
	or $t8, $a2, $zero	# $t8: column
	jal set_16x16
	la $a0, GEN_A		# change the address to read from back to GEN_A
	or $a1, $t6, $zero	# $a1: row
	or $a2, $t8, $zero	# $a2: column
	li $v0, 0
	addi $a2, $a2, 1	# inc. column counter
	j life_gen_loop

done_life_gen:
	la $a0, GEN_A		# write to GEN_A (destination array)
	la $a1, GEN_B		# read from GEN_B (source array)
	jal copy_16x16

	la $a0, GEN_L
	jal draw_16x16

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra



# set_16x16:
#
# $a0 is 16x16 byte array
# $a1 is row (0 is topmost)
# $a2 is column (0 is leftmost)
# $a3 is the value to be stored (i.e., rightmost 8 bits)
#
# $t0: row length
# $t1: index
# $t2: counter
#
# If $a1 or $a2 are outside bounds of array, then
# nothing happens.
set_16x16:
	li $t0, 0x10
	bge $a1, $t0, out_of_range
	bge $a2, $t0, out_of_range
	bltz $a1, out_of_range
	bltz $a2, out_of_range

	li $t1, 0
	sll $t1,$a1,4
	add $t1,$t1,$a2

done_set:
	add $a0, $a0, $t1		# add to the address the index num
	sb $a3, 0($a0)
	sub $a0, $a0, $t1
	jr $ra

out_of_range:
	jr $ra


# get_16x16:
#
# $a0 is 16x16 byte array
# $a1 is row (0 is topmost)
# $a2 is column (0 is leftmost)
#
# $t0: row length
# $t1: index
# $t2: counter
#
# If $a1 or $a2 are outside bounds of array, then
# the value of zero is returned
#
# $v0 holds the value of the byte at that array location
get_16x16:
	li $v0,0
	li $t0, 0x10
	bge $a1, $t0, out_of_range_get
	bge $a2, $t0, out_of_range_get
	bltz $a1, out_of_range_get
	bltz $a2, out_of_range_get

	li $t1, 0
	sll $t1,$a1,4
	add $t1, $t1, $a2

done_get:
	add $a0, $a0, $t1		# add to the address the index num
	lb $v0, 0($a0)
	sub $a0, $a0, $t1

out_of_range_get:
	jr $ra


# copy_16x16:
#
# $a0 is the destination 16x16 byte array
# $a1 is the source 16x16 byte array
# $t0: counter
# $t1: offset of destination
# $t2: offset of source
#
copy_16x16:
	li $t0, 256
	li $t1, 0
	li $t2, 0

copy_loop:
	add $t1, $a0, $t0
	add $t2, $a1, $t0

	lb $t3, 0($t2)
	sb $t3, 0($t1)

	beq $t0, $zero, done_copy
	addi $t0, $t0, -1
	j copy_loop

done_copy:
	jr $ra


# sum_neighbours:
#
# $a0 is 16x16 byte array
# $a1 is row (0 is topmost)
# $a2 is column (0 is leftmost)
#
# $v0 holds the value of the bytes around the row and column
sum_neighbours:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t7, 0		# sum

	addi $a1, $a1, -1	# go up
	jal get_16x16
	add $t7, $t7, $v0

	addi $a2, $a2, 1	# go right
	jal get_16x16
	add $t7, $t7, $v0

	addi $a1, $a1, 1	# go down
	jal get_16x16
	add $t7, $t7, $v0

	addi $a1, $a1, 1	# go down
	jal get_16x16
	add $t7, $t7, $v0

	addi $a2, $a2, -1	# go left
	jal get_16x16
	add $t7, $t7, $v0

	addi $a2, $a2, -1	# go left
	jal get_16x16
	add $t7, $t7, $v0

	addi $a1, $a1, -1	# go up
	jal get_16x16
	add $t7, $t7, $v0

	addi $a1, $a1, -1	# go up
	jal get_16x16
	add $t7, $t7, $v0

	or $v0, $t7, $zero
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# bitmap_to_16x16:
#
# AT FIRST:
# $a0 holds the address of the first byte in the array
# $a1 holds the address of the first word holding a row's bitmap pattern
#
#
# UPDATED VALUES:
# $s0: copy of the orginal address
# $s1: copy of the location address (word)
# $a1: row
# $a2: column
# $a3: pixel colour (0 if black, 1 if white)
# $s7: current word in pattern
# $t1: current bit in pattern

bitmap_to_16x16:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	or $s0, $a0, $zero
	or $s1, $a1, $zero

	li $a1, 0
	li $a2, 0

row_loop:
	lw $s7, 0($s1)
	li $a2, 0

column_loop:
	li $a3, 0
	andi $t1, $s7, 0x01		# mask to get current bit
	beq $t1, $zero, update_bitmap	# if current bit == zero, update bitmap
	li $a3, 1			# otherwise, make the current pixel 1 and move on to update

update_bitmap:
	jal set_16x16			# set the current pixel into an array
	srl $s7, $s7, 1			# shift the current bit right one

	addi $a2, $a2, 1		# decrement column count by 1
	bne $a2, 16, column_loop	# if column count is not 16, loop column

	addi $s1, $s1, 4		# go to next word
	addi $a1, $a1, 1		# increment row
	bne $a1, 16, row_loop		# if row count isn't 16, loop row

done_bitmap:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# draw_16x16:
#
# $a0 holds the start address of the 16x16 byte array
# holding the pattern for the Bitmap Display tool.
#
# Assumption: A value of 0 at a specific row and column means
# the pixel at the row & column in the bitmap display is
# off (i.e., black). A value of 1 at a specific row and column
# means the pixel at the row & column in the bitmap display
# is on (i.e., white). All other values (i.e., 2 and greater)
# are ignored.
#
# jal register positions:
#
################# SET_PIXEL #####################
# $a0: row (counting from the top as row 0)
# $a1: column (counting from the left as column 0)
# $a2: colour (24-bit RGB value)
#################################################
#
################# get_16x16 #####################
# $a0 is 16x16 byte array
# $a1 is row (0 is topmost)
# $a2 is column (0 is leftmost)
#################################################
#
# Because the values change, comments on what each register
# holds is available within the text
#
draw_16x16:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	or $s6, $a0, $zero		# copy of original address
	li $s3, 0			# row
	li $s4, 0			# column
	addi $s5, $zero, PIXEL_ON	# colour: white

draw_loop:
	or $a0, $s6, $zero		# $a0: address
	or $a1, $s3, $zero		# $a1: row
	or $a2, $s4, $zero		# $a2: column
	jal get_16x16			# current bit can now be found in $v0

	bne $v0, $zero, light_pixel_up

	or $a0, $s3, $zero		# $a0: row
	or $a1, $s4, $zero		# $a1: column
	addi $a2, $zero, PIXEL_OFF	# colour: black
	jal set_pixel

	addi $s4, $s4, 1		# increment column count by 1
	bne $s4, 16, draw_loop		# if column count is not 16, loop

	addi $s3, $s3, 1		# increment row
	li $s4, 0
	bne $s3, 16, draw_loop		# if row count isn't 16, loop row
	j done_draw

light_pixel_up:
	or $a0, $s3, $zero		# $a0: row
	or $a1, $s4, $zero		# $a1: column
	or $a2, $s5, $zero		# $a2: colour
	jal set_pixel
	addi $s4, $s4, 1		# decrement column count by 1
	li $v0, 0
	j draw_loop

done_draw:
	or $a0, $s6, $zero		# reinstate $a0

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra



# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# STUDENTS MAY MODIFY CODE ABOVE
