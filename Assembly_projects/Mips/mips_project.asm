#-------------------------------------------------------------------------------
#author: PJS_013
#data : 2020.05.14
#description : MIPS project number 3.3 - Binary Image
#-------------------------------------------------------------------------------

#only 24-bits 320x240 pixels BMP files are supported
.eqv 	BMP_FILE_SIZE 230454
.eqv 	BYTES_PER_ROW 960

	.data
.align 4
res:		.space 2
image:		.space BMP_FILE_SIZE
fnamein:	.asciiz "source.bmp"	#I reccommend to put there and in the line 16 the path to folder with the photo
fnameout:	.asciiz "dest.bmp"
x1_input: 	.asciiz "Enter x1 coordinate of top left corner\n"
y1_input: 	.asciiz "Enter y1 coordinate of top left corner\n"
x2_input: 	.asciiz "Enter x2 coordinate of bottom right corner\n"
y2_input: 	.asciiz "Enter y2 coordinate of bottom right corner\n"
error_message_coordinates_small: 	.asciiz "Coordinates cannot be smaller than 0\n"
error_message_coordinates_big_240: 	.asciiz "Coordinate y cannot be bigger than 240\n"
error_message_coordinates_big_320: 	.asciiz "Coordinate x cannot be bigger than 320\n"
error_message_x1_smaller_x2: 	.asciiz "Coordinate x2 cannot be smaller than x1\n"
error_message_y2_smaller_y1: 	.asciiz "Coordinate y1 cannot be smaller than y2\n"
error_message_open_file: 	.asciiz "Error - file was not opened correctly\n"
thresh_info:	.asciiz "Enter thresh value\n"
please_wait:	.asciiz "Please wait\n"


	.text
main:
	jal	read_bmp
	jal	read_x1
	move	$s1, $v0
	jal	read_y1
	move	$s2, $v0
	jal	read_x2
	move	$s3, $v0
	jal	read_y2
	move	$s4, $v0
	blt	$s3, $s1, error_x2_smaller_x1		#if x2 < x1 go to error_x2_smaller_x1
	blt	$s2, $s4, error_y1_smaller_y2		#if y1 < y2 go to error_y1_smaller_y2
	jal 	thres
	move	$a3, $v0

	#	$v0 -> thres
	#	$s1 -> x1
	#	$s2 -> y1
	#	$s3 -> x2
	#	$s4 -> y2
row:				#outer loop for traversing rows of bitmap
	bge 	$s4, $s2, row_out	#if y2>=y1 exit outer loop
	move	$s7, $s1
column:				#inner loop for traversing columns of bitmap
	bge 	$s7, $s3, column_out	#if x1>=x2 exit inner loop
	move 	$a0, $s7	#x
	move	$a1, $s4	#y
	jal 	get_pixel
	move	$a2, $v0	#saving the pixel color data in $a2
	jal	inequality
	
	addi 	$s7, $s7, 1	#incrementing x coordinate
	j column
column_out:
	addi	$s4, $s4, 1	#incrementing y coordinate
	j row
row_out:
	jal	save_bmp

exit:	li 	$v0,10		#Terminate the program
	syscall

# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: 
#	none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
#open file
	li 	$v0, 13
        la 	$a0, fnamein		#file name 
        li 	$a1, 0			#flags: 0-read file
        li 	$a2, 0			#mode: ignored
        syscall
        blt	$v0, 0, error_open_file	#if $v0 is smaller than 0, it means that the file was not opened correctly, then show error message
	move 	$s1, $v0      		# save the file descriptor - file handle
#read file
	li 	$v0, 14
	move 	$a0, $s1		#file descriptor
	la 	$a1, image		#address of input buffer
	li	$a2, BMP_FILE_SIZE	#maximum number of characters to read
	syscall

#close file
	li 	$v0, 16
	move 	$a0, $s1		#file descriptor
        syscall
	
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr 	$ra

# ============================================================================
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	sub	$sp, $sp, 4		#push $s1
	sw 	$s1, ($sp)
#open file
	li 	$v0, 13
        la 	$a0, fnameout		#file name 
        li 	$a1, 1			#flags: 1-write file
        li 	$a2, 0			#mode: ignored
        syscall
        blt	$v0, 0, error_open_file	#if $v0 is smaller than 0, it means that the file was not opened correctly, then show error message
	move 	$s1, $v0      		# save the file descriptor - file handle

#save file
	li 	$v0, 15
	move 	$a0, $s1		#file descriptor
	la 	$a1, image		#address of input buffer
	li 	$a2, BMP_FILE_SIZE	#maximum number of characters to read
	syscall

#close file
	li 	$v0, 16
	move 	$a0, $s1		#file descriptor
        syscall
	
	lw 	$s1, ($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr 	$ra


# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0x00RRGGBB - pixel color
#return value: none

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)

	la 	$t1, image + 10		#adress of file offset to pixel array
	lw 	$t2, ($t1)		#file offset to pixel array in $t2
	la 	$t1, image		#adress of bitmap
	add 	$t2, $t1, $t2		#adress of pixel array in $t2
	
	#pixel address calculation
	mul 	$t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move 	$t3, $a0		
	sll 	$t4, $a0, 1
	add 	$t3, $t3, $t4	#$t3= 3*x
	add 	$t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add 	$t2, $t2, $t1	#pixel address 
	
	#set new color
	sb 	$a2,($t2)		#store B
	srl 	$a2,$a2,8
	sb 	$a2,1($t2)		#store G
	srl 	$a2,$a2,8
	sb 	$a2,2($t2)		#store R
	
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr 	$ra
	
# ============================================================================
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
#return value:
#	$v0 - 0x00RRGGBB - pixel color

	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)

	la 	$t1, image + 10	#adress of file offset to pixel array
	lw 	$t2, ($t1)		#file offset to pixel array in $t2
	la 	$t1, image		#adress of bitmap
	add 	$t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul 	$t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move 	$t3, $a0		
	sll 	$t4, $a0, 1
	add 	$t3, $t3, $t4	#$t3= 3*x
	add 	$t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add 	$t2, $t2, $t1	#pixel address 
	
	#get color
	lbu 	$v0,($t2)		#load B
	lbu 	$t1,1($t2)		#load G
	sll 	$t1,$t1,8
	or 	$v0, $v0, $t1
	lbu 	$t1,2($t2)		#load R
        sll 	$t1,$t1,16
	or 	$v0, $v0, $t1
					
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra

# ============================================================================
inequality:
#description: 
#	checks the inequality thres>=0.21*R+0.72*G+0.07*B
#	depending on the outcome of the inequality it sets $a2 either to 0x00000000 (black) or 0x00FFFFFF (white)
#	and calls function put pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate
#	$a2 - 0x00RRGGBB - pixel color
#return value:
#	none
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	
	#get colors of pixel
	srl	$t1, $a2, 16		#R
	move	$t5, $t1
	srl	$t1, $a2, 8
	sll	$t2, $t5, 8
	xor	$t1, $t1, $t2		#G
	move	$t6, $t1
	or	$t2, $t2, $t6
	sll	$t2, $t2, 8
	xor	$a2, $a2, $t2		#B
	move	$t7, $a2
	
	
	li	$t1, 21
	li	$t2, 72
	li	$t3, 7
	mul	$t1, $t1, $t5		#21*R
	mul	$t2, $t2, $t6		#72*G
	mul	$t3, $t3, $t7		#7*B
					#Instead of using floating point numbers I decided to work on integer values, so to still have the inequality working
					#I'm multiplying the thres value in function thres
	add	$t1, $t1, $t2		#21*R+72*G
	add	$t1, $t1, $t3		#$t1 = 21*R+72*G+7*B
	
	bge	$a3, $t1, white		#if 100 * thres >= $t1 go to white
	li 	$a2, 0x00000000		#setting black colour in $a2
	jal	put_pixel		
	j 	go_back
white:	
	li 	$a2, 0x00FFFFFF		#setting white colour in $a2
	jal	put_pixel
go_back:
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra


# ============================================================================
read_x1:
#description: 
#	returns coordinate x1
#arguments:
#	none
#return value:
#	$v0 -> x1
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	
	li	$v0, 4
	la	$a0, x1_input
	syscall
	
	li	$v0, 5
	syscall				#read value of x1
	blt	$v0, 0, error_coordinates_small		#check if x1 is not smaller than 0
	bgt	$v0, 320, error_coordinates_big_320	#check if x1 is not larger than 320
	
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra

# ============================================================================
read_y1:
#description: 
#	returns coordinate y1
#arguments:
#	none
#return value:
#	$v0 -> y1
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	
	li	$v0, 4
	la	$a0, y1_input
	syscall
	
	li	$v0, 5
	syscall				#read value of y1
	blt	$v0, 0, error_coordinates_small		#check if y1 is not smaller than 0
	bgt	$v0, 240, error_coordinates_big_240	#check if y1 is not larger than 240
	
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra
	
# ============================================================================
read_x2:
#description: 
#	returns coordinate x2
#arguments:
#	none
#return value:
#	$v0 -> x2
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	
	li	$v0, 4
	la	$a0, x2_input
	syscall
	
	li	$v0, 5
	syscall				#read value of x2
	blt	$v0, 0, error_coordinates_small		#check if x2 is not smaller than 0
	bgt	$v0, 320, error_coordinates_big_320	#check if x2 is not larger than 320
	
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra
# ============================================================================
read_y2:
#description: 
#	returns coordinate y2
#arguments:
#	none
#return value:
#	$v0 -> y2
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	
	li	$v0, 4
	la	$a0, y2_input
	syscall
	
	li	$v0, 5
	syscall				#read value of y2
	blt	$v0, 0, error_coordinates_small		#check if y2 is not smaller than 0
	bgt	$v0, 240, error_coordinates_big_240	#check if y2 is not larger than 240
	
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra
	
# ============================================================================
thres:
#description: 
#	returns value of thres
#arguments:
#	none
#return value:
#	$v0 -> thres
	sub 	$sp, $sp, 4		#push $ra to the stack
	sw 	$ra,($sp)
	
	li	$v0, 4
	la	$a0, thresh_info
	syscall
	
	li	$v0, 5
	syscall			#read value of thres
	
	mul	$v0,$v0, 100		#multiply value of thres by 100
	
#	li	$v1, 4
#	la	$a0, please_wait
#	syscall
	
	lw 	$ra, ($sp)		#restore (pop) $ra
	add 	$sp, $sp, 4
	jr	$ra

# ============================================================================
#description: 
#	number of error displaying functions
#arguments:
#	none
#return value:
#	none
error_open_file:
	li	$v0, 4
	la	$a0, error_message_open_file
	syscall
	j	exit

error_coordinates_small:
	li	$v0, 4
	la	$a0, error_message_coordinates_small
	syscall
	j	exit
	
error_coordinates_big_240:
	li	$v0, 4
	la	$a0, error_message_coordinates_big_240
	syscall
	j	exit
	
error_coordinates_big_320:
	li	$v0, 4
	la	$a0, error_message_coordinates_big_320
	syscall
	j	exit
	
error_x2_smaller_x1:
	li	$v0, 4
	la	$a0, error_message_x1_smaller_x2
	syscall
	j	exit
	
error_y1_smaller_y2:
	li	$v0, 4
	la	$a0, error_message_y2_smaller_y1
	syscall
	j	exit
