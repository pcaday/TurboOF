default:


CC = cc
CORES = ../../cores
FORTH = ../../forth
NASMFLAGS = -g -i$(CORES)/x86/
CFLAGS = -O -g -m32 -I..
CINCLUDES = ../preprocessor.h

WINOBJ = ../preprocessor.o win-x86-cl.o x86-core-wrap.o
UNIXOBJ = ../preprocessor.o unix-x86-cl.o x86-core-wrap.o

win: 	CC = i686-w64-mingw32-gcc

win osx: NASMFLAGS += --prefix _

win: 	NASMFLAGS += -f win32
osx: 	NASMFLAGS += -f macho
linux: 	NASMFLAGS += -f elf

linux:	CFLAGS += -D_GNU_SOURCE

win: wintof.exe forth
osx linux: tof forth


tof: $(UNIXOBJ)
	$(CC) $(UNIXOBJ) -m32 -o tof

wintof.exe: $(WINOBJ)
	$(CC) $(WINOBJ) -m32 -o wintof.exe

%.o: %.c $(CINCLUDES)
	$(CC) -c $(CFLAGS) $< -o $@

forth:
	ln -s $(FORTH) forth

x86-core-wrap.o: x86-core-wrap.S x86-core-wrap.i $(CORES)/x86/x86-core.S $(CORES)/x86/x86-core.i
	nasm $(NASMFLAGS) -o x86-core-wrap.o x86-core-wrap.S

clean:
	rm -f *.o ../preprocessor.o tof wintof.exe
	([ -L forth ] && rm forth) || true

.PHONY: clean osx linux win
