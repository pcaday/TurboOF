	ifndef __PPC_BOOT_I
__PPC_BOOT_I	set 1

; Parameters for ppc-boot.S:

SECONDARY_FW	set 1
HIGH_VECTORS	set 0		; IP setting - generally 0 for secondary
COPY_VECTORS	set 1		; Copy interrupt vector code
							;  - generally 1 for secondary
							; *warning* COPY_VECTORS = 0 incompatible with ILE=LE
FLUSH_CACHES	set 0		; Flush caches? (maybe not a good idea if their translations not valid)
FLUSH_DCBI		set 0		; dcbi flushed data? (good if flush addr. not ROM)
NVRAM_IN_TEXT	set 1		; (Secondary) NVRAM in text?

; Primary FW only
TEXT_HIGH		set 0		; High part of text address
TEXT_LOW		set 0		; Low part of text address


; ROM information
STATIC_ROM_ADDR	set 0		; If 0, the ROM flush address after memory banks in r8, otherwise in ROM_FLUSH_HIGH
ROM_FLUSH_HIGH	set 0xFFC0	; ROM physical address - used to push data out of L1 data cache
							;  must refer to >= 2M currently
							; We can also use memory we don't care about.

; NVRAM control
NVRAM_MIN_LEN	set 6		; Set a minimum on the length of NVRAM (in words)
							;  that we will allow.

; NVRAM offsets of interest to us
NVRAM_XSUM		set 0		; Checksum ( 17 >>r xor )
NVRAM_LENGTH	set 4		; Length in computer words - (4b for PPC), 2 bytes
NVRAM_BITS		set 6		; 0x1: real-mode? 0x2: little-endian?
NVRAM_REAL_BASE	set 8
NVRAM_REAL_SIZE	set 0xC
NVRAM_VIRT_BASE	set 0x10
NVRAM_VIRT_SIZE	set 0x14	; Actually, we ignore this

NVRAM_RM_MASK	set 1		; Bitmasks for interesting bits of NVRAM_BITS
NVRAM_LE_MASK	set 2

; Addressing defaults
DEFT_REAL_BASE_MEM_END	set 1	; Default real-base is end of RAM (like Apple OF 3)
DEFT_REAL_BASE_HI	set 0x0100	; High halfwords of each default
DEFT_REAL_SIZE_HI	set 0x10
DEFT_VIRT_BASE_HI	set 0x7000
MIN_OF_SIZE_HI	set 0x10	; High half of minimum OF memory size.
							; Should be >= 128k for BATs
PT_SIZE			set 2		; Size of page table, from 0 (64k) to 9 (32M)

; Memory usage controls
INITVEC_LEN		set 0x100		; initvec@
								; page align
TSTORE_LEN		set 0x400		; translation store (12 bytes/transl)
SAVEAREA_LEN	set 0x400		; save area
BDICT_LEN		set 0x1800		; bootstrap dictionary = catalog
BDATA_LEN		set 0x1000		; bootstrap data space
STACK_LEN		set 0x1000		; stack
RSTACK_LEN		set 0x1000		; return stack

STACK_BUF		set 0x40		; underflow buffer for the stacks
RSTACK_CI_EXTRA	set 0x800		; in forth_quit, if the rstack is messed up,
								;  the amount in bytes the rstack is raised
								;  from rstack-base.
; Debug
DEBUG_OUTPUT	set 1

; SPRs
mmcr1			set 956
dmiss			set 976
dcmp			set 977
hash1			set 978
hash2			set 979
imiss			set 980
icmp			set 981
rpa				set 982
hid2_755		set 1011
l2pm			set 1016
hid2_750fx		set 1016
l2cr			set 1017
ictc			set 1019
thrm0			set 1020
thrm1			set 1021
thrm2			set 1022

; SWT instructions
	macro
	tlbld &rn
		dc.l 0x7C0007A4 | (&rn << 0xB)
	endm
	
	macro
	tlbli &rn
		dc.l 0x7C0007E4 | (&rn << 0xB)
	endm

; Macros

	macro
	lva &rn
	
		if HIGH_VECTORS
		lis		&rn, 0xFFF0
		else
		li		&rn, 0
		endif
	endm
	
	macro
	CANNOT_CROSS_PAGE &start, &end
		ifdef PPC_BOOT_PRESENT
		if (&end - &start) > 0x1000
	*error* range &start to &end is larger than one page
		endif

		if ((&end - commencement) ^ (&start - commencement)) & 0x1000
	*error* range &start to &end crosses a page boundary
		endif
		endif
	endm


	endif