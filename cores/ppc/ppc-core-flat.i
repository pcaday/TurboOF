	ifndef	__PPC_CORE_FLAT_I
__PPC_CORE_FLAT_I	set 1


WRITE_BACK	set 1

	
BCAT_NSIZE	set 0x18

	macro
	BCAT_START
		__bcat_start:
	endm
	
	macro
	BCAT_ENTRY &wLabel, &wName, &wNameLen, &wImmediate
		dc.b	&wNameLen
		dc.b	&wImmediate | 2
		dc.w	0
		dc.l	&wLabel - __bcat_start
		dc.b	&wName
		ds.b	15 - &wNameLen
		align	2
	endm
	
	macro
	BCAT_END
		__bcat_end:
		dc.l	0
	endm


dec_call	set 0
dec_lit		set 1
dec_pro		set 2
dec_epi		set 3
dec_br		set 4
dec_t_br	set 6
dec_f_br	set 7
dec_other	set 0xA

instr_len		set 4
compile_len		set 4
literal_len		set 12
prologue_len	set 8
epilogue_len	set 16
branch_len		set 4
cbranch_len		set 16



; initvec@ offsets - all addresses virtual unless specified otherwise
IV_DATA_BASE	set 0x0			; Beginning of dictionary
IV_BD_BASE		set 0x4			; Bootstrap dictionary
IV_STACK_BASE	set 0x8			; Stack top
IV_RSTACK_BASE	set 0xC			; Return stack top
IV_FTEXT_BASE	set 0x10		; Text
IV_AM_BASE		set 0x14		; Top of OF memory
IV_REAL_BASE	set 0x18		; Effective real-base
IV_REAL_SIZE	set 0x1C		; Effective real-size
IV_VIRT_BASE	set 0x20		; Effective virt-base
IV_VIRT_SIZE	set 0x24		; Effective virt-size
IV_EXISTING		set 0x28		; Memory banks ("existing")
IV_NEXISTING	set 0x2C		; #memory banks
IV_NVRAM		set 0x30		; NVRAM
IV_NVRAM_SIZE	set 0x34		; NVRAM length (bytes)
IV_DEVTREE		set 0x38		; Flattened device-tree
IV_DT_LEN		set 0x3C		; device-tree length
IV_TSTORE		set 0x40		; translation store -- internal
IV_INTERNALS	set 0x44		; vector savearea -- internal
IV_PT			set 0x48		; Page table base
IV_PT_SIZE		set 0x4C		; Page table extra size bits (0 - 9)

	
;;;; CI structures and definitions


;; Definition of a context, which stores most common processor state.
CTX_SIZE		set 0xB0

CTX_GPR			set 0x0
CTX_LR			set 0x80
CTX_CTR			set 0x84
CTX_CR			set 0x88
CTX_XER			set 0x8C
CTX_SPRG0		set 0x90
CTX_SPRG1		set 0x94
CTX_SPRG2		set 0x98
CTX_SPRG3		set 0x9C
CTX_SRR0		set 0xA0
CTX_SRR1		set 0xA4
CTX_MSR			set 0xA8
CTX_OTHER		set 0xAC	; pointer to the other context

;; Definition of the swapstore, which contains the OF and client contexts.
SS_CLI_CTX		set 0
SS_OF_CTX		set SS_CLI_CTX + CTX_SIZE
SS_SIZE			set CTX_SIZE << 1


;; Definition of a swap descriptor, used by the swapper
SWD_SIZE			set 0x18

SWD_DEST			set 0x00	; destination addr
SWD_RET				set 0x04	; return addr [filled in by swapper]
SWD_CALLING_CTX		set 0x08	; the context calling swap_entry
SWD_CALLED_CTX		set 0x0C	; the context in which to run the code
SWD_RET_CODE		set 0x10	; 2 constant words of return code, specified below

	macro
	MAKE_EMPTY_SWD
		dc.l	0x0
		dc.l	0x0
		dc.l	0x0
		dc.l	0x0
		mflr	r11		; the code to be used in the SWD_RET_CODE field
		bl	swap_return	;
	endm

;; Definition of the extended client save structure
XCS_SIZE			set 0x3084

XCS_SR				set 0		; the client's SRs
XCS_BAT				set 0x40	; when we are dealing with the BATs as a structure
XCS_IBAT			set 0x40	; the client's IBATs/UBATs
XCS_DBAT			set 0x60	; the client's DBATs, if not 601
XCS_SDR1			set 0x80	; the client's SDR1
XCS_VECTORS			set 0x84	; the client's vector code (ppp00000 - ppp02FFF)
	
	endif