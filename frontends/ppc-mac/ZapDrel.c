#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <XCOFF.h>

#pragma options align=mac68k

typedef struct {
	FileHdr xh;
	SectionHdrEntry code;
	SectionHdrEntry data;
} PredefXCOFF;

void usage(char *prog)
{
	fprintf(stderr, "Usage: %s file\n", prog);
}

int main(int argc, char **argv)
{
	FILE *fd;
	PredefXCOFF file;
	unsigned short us;
		
	if (argc != 2) {
		usage(argv[0]);
		return 1;
	}

	if (!(fd = fopen(argv[1], "r+"))) {
		fprintf(stderr, "Could not open file %s", argv[1]);
		return 1;
	}

	fseek(fd, 0, SEEK_SET);
	
	if (!fread(&file, 1, sizeof(PredefXCOFF), fd)) {
		fprintf(stderr, "Could not read file %s", argv[1]);
		return 1;
	}
	
	us = file.xh.f_magic;
	if ((us != U802WRMAGIC) && (us != U802ROMAGIC) && (us != U802TOCMAGIC)) {
		fprintf(stderr, "%s is not an XCOFF file", argv[1]);
		return 1;
	}

	
	if (*((long *) &file.code.s_name[0]) != '.tex') {
		fprintf(stderr, "Did not find .text in expected location");
		return 1;
	}
	
	file.code.s_nreloc = 0;
	
	fseek(fd, 0, SEEK_SET);
	
	if (!fwrite(&file, 1, sizeof(PredefXCOFF), fd)) {
		fprintf(stderr, "Could not write file %s", argv[1]);
		return 1;
	}
	
	fclose(fd);
	
	return 0;
}

/*
// MrC :TOF:ZapDrel.c -i :CIncludes: -w 2 -align mac68k

// PPCLink :TOF:ZapDrel.c.o "{SharedLibraries}"StdCLib "{SharedLibraries}"InterfaceLib "{PPCLibraries}"StdCRuntime.o "{PPCLibraries}"PPCCRuntime.o -c 'MPS ' -t MPST -o ZapDrel

// ZapDrel :TOF:ppc-boot.S.o

// DumpPEF ZapDrel -do c -fmt on -dialect PPC32 -ntb -a -u -pi i

// DumpXCOFF :TOF:ppc-boot.S.o -a -do h -do r -do s -do y

// DumpXCOFF :TOF:mac-secondary.c.o -a -do h -do r -do s -do y


*/


