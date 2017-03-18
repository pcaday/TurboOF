#!/bin/sh

nasm -f macho -g --prefix _ -i../../cores/x86/ x86-core-wrap.S
gcc -c -O -g -m32 -I.. unix-x86-cl.c
gcc -c -O -g -m32 ../preprocessor.c
gcc unix-x86-cl.o preprocessor.o x86-core-wrap.o -m32 -o unix-x86-cl
