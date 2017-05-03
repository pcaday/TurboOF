default:


CC = cc
CORES = ../../cores
FORTH = ../../forth
NASMFLAGS = -g -i$(CORES)/x86_64/
CFLAGS = -O -g -m64 -I..
CINCLUDES = ../preprocessor.h

WINOBJ = ../preprocessor.o win-x86_64-cl.o x86_64-core-wrap.o
UNIXOBJ = ../preprocessor.o unix-x86_64-cl.o x86_64-core-wrap.o

win: 	CC = i686-w64-mingw64-gcc

win osx: NASMFLAGS += --prefix _

win: 	NASMFLAGS += -f win64
osx: 	NASMFLAGS += -f macho64
linux: 	NASMFLAGS += -f elf64

linux:	CFLAGS += -D_GNU_SOURCE

win: wintof.exe forth
osx linux: tof forth


tof: $(UNIXOBJ)
	$(CC) $(UNIXOBJ) -m64 -o tof

wintof.exe: $(WINOBJ)
	$(CC) $(WINOBJ) -m64 -o wintof.exe

%.o: %.c $(CINCLUDES)
	$(CC) -c $(CFLAGS) $< -o $@

forth:
	ln -s $(FORTH) forth

x86_64-core-wrap.o: x86_64-core-wrap.S x86_64-core-wrap.i $(CORES)/x86_64/x86_64-core.S $(CORES)/x86_64/x86_64-core.i
	nasm $(NASMFLAGS) -o x86_64-core-wrap.o x86_64-core-wrap.S

clean:
	rm -f *.o ../preprocessor.o tof wintof.exe
	([ -L forth ] && rm forth) || true

.PHONY: clean osx linux win
