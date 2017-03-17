	ifndef __PPC_VECTORS_I
__PPC_VECTORS_I set 1

	include 'ppc-context.i'
	
	if COPY_VECTORS
						; CopyVectors: store the word count only
	macro
	VECTOR &vecnum, &vecnwords
		dc.l	&vecnwords
	endm
	macro
	NO_MORE_VECTORS
		dc.l	-1
	endm
	
	else
						; Primary, NoCopyVectors: use assembler directives
	
	macro
	VECTOR &vecnum, &vecnwords
		if HIGH_VECTORS
			org	&vecnum | 0xFFF00000
		else
			org &vecnum
		endif
	endm
	macro
	NO_MORE_VECTORS
						; null
	endm
	
	endif
	
		; Format of SPRG1 (register store & state)
		;  This structure is either big- or little-endian, depending
		;  on the configuration variable little-endian?
	
INT_FORTH_UP	set 0x00			; Is enough Forth running to handle exceptions?
INT_R7			set 0x04
INT_CR			set 0x08
INT_EXC_VEC		set 0x0C
INT_CTR			set 0x10
INT_R0			set 0x14
INT_R1			set 0x18
INT_R3			set 0x1C

INT_V_BASE		set 0x20
INT_V_LINE		set 0x24
INT_V_WIDTH		set 0x28
INT_V_H			set 0x2C
; With FORTH_UP = 0, no data should be accessed beyond this point.
INT_EXC_SRR0	set 0x30
INT_EXC_SRR1	set 0x34
INT_EXC_DSISR	set 0x38
INT_EXC_DAR		set 0x3C

INT_EHANDLER	set 0x40			; Normal Forth exception handler
INT_UEHANDLER	set 0x44			; Exception handler used when the stack was way off => must quit immediately.
INT_SYSCALL		set 0x48			; System call handler
INT_DHANDLER	set 0x4C			; Decrementer handler (for alarms)
INT_DINIT		set 0x50			; Value the decrementer is loaded with (alarm granularity)
										; If 0, decrementer handler disabled
INT_HANDLER_RA	set 0x54		; Return address for handlers
INT_STK_BASE	set 0x58		; Vector's copy of stack-base
INT_RSTK_BASE	set 0x5C		;  and rstack-base
INT_VEC_BITS	set 0x60		; Configuration bits;	0x1: little-endian?
								;						0x2: in client?
								;						0x4: in client callback?
								;						0x8: real-mode?
INT_MY_SDR1		set 0x80		; My value for SDR1, used for checking
								;  when SDR1 has been changed. Set to an invalid
								;  value in virtual-mode when a callback which handles mapping 
								;  has been established.
								; Bottom line: INT_MY_SDR1 <> sdr1 implies "Client took over mapping"
								
INT_GO_SWD			set 0x8C	; the swap descriptor for 'go'
INT_CALLBACK_SWD	set 0x90	; the swap descriptor for '$callback'
INT_OF_CTX			set 0x94	; the OF context
INT_CLI_CTX_REAL	set 0x98	; real address of the client context
INT_CLI_CTX			set 0x9C	; the client context*
INT_CI_HANDLER		set 0xA0	; the PPC-specific Forth CI handler* (ci-handler)
INT_LL_CX_HANDLER	set 0xA4	; the assembly handler for exceptions caught while client running
INT_LL_CX_CB_HDLR	set 0xA8	; the assembly handler for exceptions caught during a client callback
INT_CLI_EXC_HANDLER	set 0xAC	; the Forth handler for exceptions caught while client running*
INT_NTRANS			set 0xB0	; the number of mappings (SPRG0 + 1)*
INT_OF_BATS			set 0xB4	; copies of OF's BATs (0x40 bytes)
INT_OF_IBATS		set 0xB4	; 	(IBATs/UBATs)
INT_OF_DBATS		set 0xD4	; 	(DBATs)
INT_PPGO_RET_ADDR	set 0xF4	; saved return address for ((go))
INT_SAVED_RSP		set 0xF8	; rsp saved upon ci invocation, client exception
								;  and restored at (ci/cx-return) so that the
								;  rstack stays in balance
INT_FORTH_CTX		set 0x100	; Saved Forth context for alarms (and sc too, if needed)
								;  (GPRs, LR, CR, CTR)
INT_TEMP_BATS		set 0x1A0	; A temporary set of BATs loaded when we get
								;  a client exception
INT_TEMP_IBATS		set 0x1A0
INT_TEMP_DBATS		set 0x1C0

INT_PLATFORM_USE	set 0x1E0	; 0x20 bytes for platform-specific use.

	endif