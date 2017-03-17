#!/bin/sh

CC="i686-w64-mingw32-gcc"

nasm -f win32 -g -i../../cores/x86/ -o x86-core-wrap.o --prefix _ x86-core-wrap.S
$CC -c -O -g -m32 -I.. win-x86-cl.c
$CC -c -O -g -m32 ../preprocessor.c
$CC win-x86-cl.o preprocessor.o x86-core-wrap.o -m32 -o win-x86-cl.exe
