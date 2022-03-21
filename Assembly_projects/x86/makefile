CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o edit_row.o -f elf -l edit_row.lst edit_row.asm
cc :
	$(CC) -m32 -c -g -O0 main.c
link :
	$(CC) -m32 -o binary_image main.o edit_row.o
clean :
	rm *.o
	rm binary_image
	rm edit_row.lst
