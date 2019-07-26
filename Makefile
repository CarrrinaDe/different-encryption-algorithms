tasks: tasks.asm
	nasm -f elf32 -o tasks.o $<
	gcc -m32 -o $@ tasks.o

clean:
	rm -f tasks tasks.o
