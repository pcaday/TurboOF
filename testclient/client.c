void main(void)
{
	volatile unsigned long *ptr = (volatile unsigned long *) 0x60000000;
	
	*ptr = 0x03030303;
}

/*
// MrC :TOF:client:client.c -o :TOF:client:client.c.o

PPCLink :TOF:client:client.c.o -o :TOF:client:built:client.bin -outputformat xcoff -m main -t '????' -c '????' -codeorder source -dead off -rodatais code -ac 1024 -ad 1024 -codestart 1048576 -datastart 1572864


DumpXCOFF :TOF:client.bin -a -do h -do r -do t -do d -dialect powerPC32
DumpXCOFF :TOF:bootx.xcoff -a -do h -do r -do t -do d -dialect powerPC32

*/