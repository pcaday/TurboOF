#!/bin/sh

nasm -f elf -g -i../../cores/x86/ x86-core-wrap.S
gcc -c -O -g -m32 -D_GNU_SOURCE -I.. unix-x86-cl.c
gcc -c -O -g -m32 ../preprocessor.c
gcc unix-x86-cl.o preprocessor.o x86-core-wrap.o -m32 -o unix-x86-cl
