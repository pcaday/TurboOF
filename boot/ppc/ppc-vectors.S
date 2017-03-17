; SPRG usage:
;
;  SPRG0: #translations - 1
;  SPRG1: register store - Forth state -- format in ppc-vectors.i
;  SPRG2: compressed translations
;  SPRG3: scratch

; Format of SPRG2:
;  virt1 virt2 virt3 ... virtn size1 size2 ... sizen phys-mode1 phys-mode2 ... phys-moden



	include 'ppc-boot.i'
	include	'ppc-vectors.i'
	include 'ppc-squares.S'

vectors:

	VECTOR 0x000, (_0x0000_end - _0x0000_begin) >> 2
; 0x0000 - reserved
_0x0000_begin:
	mtsprg	3, r2				; Most likely, someone jumped to 0
	mfsprg	r2, 1				;  No harm, we'll just report it.
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	li		r7, 0x000
	
forth_quit:
	stw		r7, INT_EXC_VEC(r2)		; Store this before destroying it.

	lwz		r7, INT_FORTH_UP(r2)
; cache line
	andi.	r7, r7, 1
	beq		restore_r2_r7_cr	; If Forth is not running,
								;  just try returning where we left off.
forth_running:
	mfsrr0	r7
	stw		r7, INT_EXC_SRR0(r2)
	mfsrr1	r7
	stw		r7, INT_EXC_SRR1(r2)
	mfdsisr	r7
	stw		r7, INT_EXC_DSISR(r2)
; cache line
	mfdar	r7
	stw		r7, INT_EXC_DAR(r2)

	lwz		r7, INT_VEC_BITS(r2)
	rlwinm.	r7, r7, 0, 0x2		; In client?
	bnea	__got_client_exception

	lwz		r7, INT_STK_BASE(r2)
	addi	r7, r7, 4			; dsp for empty stack
	sub		r7, r7, r31			; Check whether the data stack pointer is OK
; cache line
	cmplwi	r7, STACK_LEN - STACK_BUF
	bgt-	dsp_dead

	lwz		r7, INT_RSTK_BASE(r2)
	sub		r7, r7, r30			; Check whether the return stack pointer is OK
	cmplwi	r7, RSTACK_LEN - STACK_BUF
	bge-	rsp_dead

	li		r7, INT_EHANDLER	; Everything looks OK, handle normally.
	b		sp_check_done

; cache line
dsp_dead:	
	add		r31, r7, r31		; Restore a sane dsp; will reset the stack soon.
rsp_dead:
	lwz		r30, INT_RSTK_BASE(r2)		; Restore a sane rsp
	subi	r30, r30, RSTACK_CI_EXTRA	;  add some extra for CI
	li		r7, INT_UEHANDLER
sp_check_done:
	lwzx	r7, r2, r7			; Load the appropriate handler
	
	mtsrr0	r7
	
	lwz		r7, INT_VEC_BITS(r2)
	rlwinm.	r7, r7, 0, 0x1		; little-endian?
	
	mfsrr1	r7
; cache line	
restore_r2_r7_cr_msr:
	rlwinm	r7, r7, 0, 0xFFFEFFFF
	rlwinm	r7, r7, 0, 0xFFFF807F	; Preserve EE, high word processor-specific
	rlwinm	r7, r7, 0, 0xFFFFFFC0	; Also preserve IP
	
	ori		r7, r7, 0x3032		; ME, FP, IR, DR, RI on
		
	beq		setup_msr_be
	
	oris	r7, r7, 1			; Set LE, ILE if little-endian? is true
	ori		r7, r7, 1
	
setup_msr_be:	
	mtsrr1	r7
; cache line
	b		restore_r2_r7_cr
	nop
	nop
restore_r2_r7_cr_ctr:
	lwz		r7, INT_CTR(r2)
	mtctr	r7

restore_r2_r7_cr:
	lwz		r7, INT_CR(r2)
	mtcr	r7
	lwz		r7, INT_R7(r2)
; cache line
	mfsprg	r2, 3
	rfi

	if HIGH_VECTORS
__forth_quit		set (forth_quit - _0x0000_begin) + 0xFFF00000
__restore_r2_r7_cr	set (restore_r2_r7_cr - _0x0000_begin) + 0xFFF00000
__restore_r2_r7_cr_ctr	set (restore_r2_r7_cr_ctr - _0x0000_begin) + 0xFFF00000
__restore_r2_r7_cr_msr	set (restore_r2_r7_cr_msr - _0x0000_begin) + 0xFFF00000
	else
__forth_quit		set (forth_quit - _0x0000_begin)
__restore_r2_r7_cr	set (restore_r2_r7_cr - _0x0000_begin)
__restore_r2_r7_cr_ctr	set (restore_r2_r7_cr_ctr - _0x0000_begin)
__restore_r2_r7_cr_msr	set (restore_r2_r7_cr_msr - _0x0000_begin)
	endif

_0x0000_end:
	

	VECTOR 0x100, (_0x0100_end - _0x0100_begin) >> 2
; 0x0100 - system reset
_0x0100_begin:
	if COPY_VECTORS = 0 && SECONDARY_FW = 0
		; Primary FW must handle this & determine what to do with the reset.

	else
	
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)

	li		r7, 0x100
	ba		__forth_quit			; Try to quit, unrecoverable or not.

	endif

	nop
; cache line

; r2: internals, cr, r7: scratch; r7, cr saved in internals, r2 saved in SPRG3
;  srr0, srr1, dar, dsisr, vec# noted in internals
got_client_exception:
	lwz		r7, INT_CLI_CTX_REAL(r2)
	stw		r11, CTX_GPR + 0x2C(r7)		; Save r11 and r12 before swap trashes them
	stw		r12, CTX_GPR + 0x30(r7)

	lwz		r7, INT_VEC_BITS(r2)		; Determine whether we are in a callback
	andi.	r7, r7, 4					; Load the appropriate handler.
	bne		gce_in_cb					; The decision is made here because
	lwz		r7, INT_LL_CX_HANDLER(r2)	;  we have access to internals and CR.
	b		gce_cb_done	
; cache line
gce_in_cb:	
	lwz		r7, INT_LL_CX_CB_HDLR(r2)
gce_cb_done:
	mtsrr0	r7
	
	; Load up a temporary set of BATs so we
	;  can turn IR and DR on and run Forth.
	; These will be replaced by install-ath.
	
	lwz		r7, INT_TEMP_IBATS + 0x00(r2)
	mtspr	ibat0u, r7
	isync
	lwz		r7, INT_TEMP_IBATS + 0x04(r2)
	mtspr	ibat0l, r7
	isync
; cache line
	lwz		r7, INT_TEMP_IBATS + 0x08(r2)
	mtspr	ibat1u, r7
	isync
	lwz		r7, INT_TEMP_IBATS + 0x0C(r2)
	mtspr	ibat1l, r7
	isync
	lwz		r7, INT_TEMP_IBATS + 0x10(r2)
	mtspr	ibat2u, r7
; cache line
	isync
	lwz		r7, INT_TEMP_IBATS + 0x14(r2)
	mtspr	ibat2l, r7
	isync
	lwz		r7, INT_TEMP_IBATS + 0x18(r2)
	mtspr	ibat3u, r7
	isync
	lwz		r7, INT_TEMP_IBATS + 0x1C(r2)
; cache line
	mtspr	ibat3l, r7
	isync

	ba		__got_client_exception2
	
	if HIGH_VECTORS
__got_client_exception	set (got_client_exception - _0x0100_begin) + 0xFFF00100
	else
__got_client_exception	set (got_client_exception - _0x0100_begin) + 0x0100
	endif
	
_0x0100_end:


	VECTOR 0x200, (_0x0200_end - _0x0200_begin) >> 2
; 0x0200 - machine check
_0x0200_begin:
	mtsprg	3, r2
	mfsprg	r2, 1					; We may want to explicitly set up SRR1 again
	stw		r7, INT_R7(r2)				;  -- processors are not required to move MSR to SRR1.
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x200
	ba		__forth_quit
_0x0200_end:


; Format of translations for SWT/DSI/ISI handlers:
;  virt1 virt2 virt3 ... virtn size1 size2 ... sizen phys-mode1 phys-mode2 ... phys-moden

	VECTOR 0x300, (_0x0300_end - _0x0300_begin) >> 2
; 0x0300 - DSI
_0x0300_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	mfdsisr	r7
	rlwinm.	r7, r7, 0, 0x40000000	; page fault?
	bne+	dsi_page_fault			; yes, try to find the translation
; cache line
	mfdsisr	r7						; reload; we don't care about timing now.
	rlwinm.	r7, r7, 0, 0x00400000
	li		r7, 0x300				; DABR match? bad idea,
	bnea	__restore_r2_r7_cr		;	but keep going.
	ba		__forth_quit			; otherwise quit.

dsi_page_fault:
	mfdar	r7
	crset	cr6_eq
	stw		r0, INT_R0(r2)
	
; cache line
page_fault:
		; First, we check whether the client has taken over mapping
		;  by checking whether INT_MY_SDR1 is equal to the actual SDR1.
		;  If not, SDR1 has been changed, or INT_MY_SDR1 has been set
		;  to an invalid value since a callback implementing mapping has
		;  been set. In either case, we just throw an error (see ppc-ci-notes).
	stw		r1, INT_R1(r2)
	mfsdr1	r0
	lwz		r1, INT_MY_SDR1(r2)
	cmplw	r0, r1
	bne		pf_notfound_no_r3
	
		; If we have control, we find the translation in our tables.	
	mfsprg	r0, 0
	mfsprg	r1, 2
	mr.		r0, r0
; cache line	
	stw		r3, INT_R3(r2)
	mfctr	r3
	blt		pf_notfound_no_ctr
	stw		r3, INT_CTR(r2)
	mtctr	r0
	lwz		r0, 0(r1)
	beq		pf_pretest
pf_loop:
	lwzu	r3, 4(r1)
; cache line	
	cmplw	r7, r3
	blt		pf_test
	mr		r0, r3
	bdnz	pf_loop
pf_pretest:
	addi	r1, r1, 4
pf_test:
	mfsprg	r3, 0
	subf	r0, r0, r7
	slwi	r3, r3, 2
; cache line
	lwzux	r2, r1, r3
	cmplw	r0, r2
	addi	r1, r1, 4
	bge		pf_notfound
	clrrwi	r0, r0, 12
	lwzx	r2, r3, r1

			; Find a spot in the primary PTEG.
			; We are sure to have a page table because SWT'ing processors will
			;  never send a page fault DSI/ISI.
	
			; We will cross over into the ISI handler region for code space reasons.
	
	rlwinm	r1, r7, 10, 22, 25
	add		r2, r2, r0					; r2 now contains the lower word of the new PTE.
; cache line
	rlwinm	r0, r7, 26, 7, 25
	mfsdr1	r3							; Get the page table address from SDR1.
	rlwimi	r1, r1, 4, 18, 21			;  (should this be our own resources?)
	ba		__page_fault_2

pf_notfound:
	mfsprg	r2, 1
	lwz		r7, INT_CTR(r2)
	mtctr	r7
pf_notfound_no_ctr:
	lwz		r3, INT_R3(r2)
; cache line
pf_notfound_no_r3:
	lwz		r0, INT_R0(r2)
	lwz		r1, INT_R1(r2)
	li		r7, 0x400
	bnea	cr6, __forth_quit			; Get appropriate vec# for reporting
	li		r7, 0x300
	ba		__forth_quit
	
	if HIGH_VECTORS
__page_fault		set (page_fault - _0x0300_begin) + 0xFFF00300
	else
__page_fault		set (page_fault - _0x0300_begin) + 0x300
	endif

_0x0300_end:



	VECTOR 0x400, (_0x0400_end - _0x0400_begin) >> 2
; 0x0400 - ISI
_0x0400_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	mfsrr1	r7
	rlwinm.	r7, r7, 0, 0x40000000		; page fault?
	beq-	isi_quit
; cache line
	crclr	cr6_eq
	mfsrr0	r7						; If so, get the address that caused it and handle.
	stw		r0, INT_R0(r2)				; Store this off here so we can start on a cache line.
	ba		__page_fault
	
isi_quit:
	li		r7, 0x400
	ba		__forth_quit			; If not, quit

	nop
	nop
; cache line
page_fault_2:
			; Continuing on, we will try to locate an unreferenced/invalid PTE in the primary PTEG,
			;  or otherwise pick some pseudorandom one.

	xoris	r0, r0, 0x9D
	xori	r1, r1, 0x4000
	xor		r0, r0, r1			; Primary hash << 6
								; r0 contains primary hash, r2 contains PTE low word, r3 contains SDR1
	slwi	r1, r3, 16			; Get the pt mask
	rlwimi	r3, r0, 0, 16, 31 	; Wiggle 10 bits of hash into primary PTEG address, discarding low half of r3
	and		r0, r0, r1			; Mask off hash
	li		r1, 8
	or		r3, r3, r0			; and put the rest of it in.
; cache line
	mfmsr	r0					; Get LE
	mtctr	r1
	rlwinm	r1, r0, 2, 0x4		; If LE = 1, munge the address appropriately
pf2_e_l:
	lwzx	r0, r1, r3
	mr.		r0, r0				; Valid?
	addi	r3, r3, 8
	bge		pf2_got_nv			; No, snag it.
	bdnz	pf2_e_l
; cache line
	li		r0, 8
	subi	r3, r3, 64			; Reset the counter
	mtctr	r0
	xori	r1, r1, 4			; Choose other word
pf2_ur_l:
	lwzx	r0, r1, r3
	andi.	r0, r0, 0x100		; Referenced?
	addi	r3, r3, 8
	beq		pf2_got				; No, snag it.
; cache line
	bdnz	pf2_ur_l
	
	mfdec	r0					; Choose a PTE according to some low order bits
	rlwinm	r0, r0, 1, 26, 28	; of the decrementer, which should be pseudorandom enough
	subf	r3, r0, r3
	b		pf2_got

pf2_got_nv:
	xori	r1, r1, 4
pf2_got:
	subi	r0, r1, 8			; The munging continues...
	rlwinm	r1, r7, 10, 26, 31	; API, H=0
; cache line
	stwx	r2, r3, r0			; Store second word of PTE
	rlwinm	r2, r7, 4, 28, 31	; Seg#
	ori		r1, r1, 0x8000
	rlwimi	r2, r2, 4, 24, 27
	oris	r1, r1, 0x893A
	xori	r0, r0, 4
	rlwimi	r1, r2, 7, 17, 24	; First word of PTE
	mfsprg	r2, 1				; Get back savearea
; cache line	
	stwx	r1, r3, r0			; Store first word of PTE
	lwz		r0,	INT_R0(r2)			; ...R0
	lwz		r1, INT_R1(r2)			; ...R1
	lwz		r3, INT_R3(r2)			; ...R3
	ba		__restore_r2_r7_cr_ctr


	if HIGH_VECTORS
__page_fault_2		set (page_fault_2 - _0x0400_begin) + 0xFFF00400
	else
__page_fault_2		set (page_fault_2 - _0x0400_begin) + 0x400
	endif

_0x0400_end:


	VECTOR 0x500, (_0x0500_end - _0x0500_begin) >> 2
; 0x0500 - external interrupt
_0x0500_begin:
	include 'ppc-extint-vector-m2.S'
	
;	rfi						; go away, we don't allow your kind here.
_0x0500_end:


	VECTOR 0x600, (_0x0600_end - _0x0600_begin) >> 2
; 0x0600 - alignment
_0x0600_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x600				; Your operands had better be aligned...
	ba		__forth_quit
	
; DSISR@600:
;	bits 15-21	 operation type
;	bits 22-26	 source/dest reg
;	bits 27-31	 base reg for updating ld/st

;	mfdsisr	r0
;	rlwinm	r0, r0, 26, 0x3FC
_0x0600_end:
	
	VECTOR 0x700, (_0x0700_end - _0x0700_begin) >> 2
; 0x0700 - program
_0x0700_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x700
	ba		__forth_quit
_0x0700_end:


	VECTOR 0x800, (_0x0800_end - _0x0800_begin) >> 2
; 0x0800 - FP unavailable
_0x0800_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x800
	ba		__forth_quit
_0x0800_end:
	
	
	VECTOR 0x900, (_0x0900_end - _0x0900_begin) >> 2
; 0x0900 - decrementer
_0x0900_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	lwz		r7, INT_FORTH_UP(r2)
	andi.	r7, r7, 1
	beqa-	__restore_r2_r7_cr	; If Forth's not running, ignore.

	lwz		r7, INT_VEC_BITS(r2)
	andi.	r7, r7, 6
	bnea-	__restore_r2_r7_cr	; If the client is running, ignore.

	lwz		r7, INT_DINIT(r2)
	cmplwi	r7, 0
	beq		_0x0900_no_handler
	
	mtdec	r7					; Reload decrementer
	
	lwz		r7, INT_STK_BASE(r2)
	addi	r7, r7, 8			; dsp for empty stack + one word lenience
	sub		r7, r7, r31			; Check whether the data stack pointer is OK
	cmplwi	r7, STACK_LEN - STACK_BUF

	bgta-	__restore_r2_r7_cr	; If stack not OK, don't call the handler,
								;  just return.
	lwz		r7, INT_RSTK_BASE(r2)
	sub		r7, r7, r30			; Check whether the return stack pointer is OK
	cmplwi	r7, RSTACK_LEN - STACK_BUF
	bgea-	__restore_r2_r7_cr	; Return if not

	mfsrr0	r7
	stw		r7, (INT_FORTH_CTX + CTX_PC)(r2)
	
	lwz		r7, INT_DHANDLER(r2)
	mtsrr0	r7

	mfsrr1	r7
	rlwinm	r7, r7, 0, 0xFFFF7FFF		; Handler must set EE when it is ready
	mtsrr1	r7							;  to take another exception

	ba		__save_forth_ctx

_0x0900_no_handler:
	li		r7, -1
	mtdec	r7
	ba		__restore_r2_r7_cr

_0x0900_end:


	VECTOR 0xA00, (_0x0A00_end - _0x0A00_begin) >> 2
; 0x0A00 - reserved / 601: IO controller exception / G2_LE: critical interrupt
_0x0A00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0xA00
	ba		__forth_quit	
_0x0A00_end:	


	VECTOR 0xB00, (_0x0B00_end - _0x0B00_begin) >> 2
; 0x0B00 - reserved
_0x0B00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0xB00
	ba		__forth_quit
	nop
	
save_forth_ctx:
	lwz		r7, INT_R7(r2)
	
	stw		r0, (INT_FORTH_CTX + CTX_GPRS + 0x00)(r2)
	stw		r1, (INT_FORTH_CTX + CTX_GPRS + 0x04)(r2)

	stw		r3, (INT_FORTH_CTX + CTX_GPRS + 0x0C)(r2)
	stw		r4, (INT_FORTH_CTX + CTX_GPRS + 0x10)(r2)
	stw		r5, (INT_FORTH_CTX + CTX_GPRS + 0x14)(r2)
	stw		r6, (INT_FORTH_CTX + CTX_GPRS + 0x18)(r2)
	stw		r7, (INT_FORTH_CTX + CTX_GPRS + 0x1C)(r2)
	stw		r8, (INT_FORTH_CTX + CTX_GPRS + 0x20)(r2)
	stw		r9, (INT_FORTH_CTX + CTX_GPRS + 0x24)(r2)
	stw		r10, (INT_FORTH_CTX + CTX_GPRS + 0x28)(r2)
	stw		r11, (INT_FORTH_CTX + CTX_GPRS + 0x2C)(r2)
	stw		r12, (INT_FORTH_CTX + CTX_GPRS + 0x30)(r2)
	stw		r13, (INT_FORTH_CTX + CTX_GPRS + 0x34)(r2)
	stw		r14, (INT_FORTH_CTX + CTX_GPRS + 0x38)(r2)
	stw		r15, (INT_FORTH_CTX + CTX_GPRS + 0x3C)(r2)
	stw		r16, (INT_FORTH_CTX + CTX_GPRS + 0x40)(r2)
	stw		r17, (INT_FORTH_CTX + CTX_GPRS + 0x44)(r2)
	stw		r18, (INT_FORTH_CTX + CTX_GPRS + 0x48)(r2)
	stw		r19, (INT_FORTH_CTX + CTX_GPRS + 0x4C)(r2)
	stw		r20, (INT_FORTH_CTX + CTX_GPRS + 0x50)(r2)
	stw		r21, (INT_FORTH_CTX + CTX_GPRS + 0x54)(r2)
	stw		r22, (INT_FORTH_CTX + CTX_GPRS + 0x58)(r2)
	stw		r23, (INT_FORTH_CTX + CTX_GPRS + 0x5C)(r2)
	stw		r24, (INT_FORTH_CTX + CTX_GPRS + 0x60)(r2)
	stw		r25, (INT_FORTH_CTX + CTX_GPRS + 0x64)(r2)
	stw		r26, (INT_FORTH_CTX + CTX_GPRS + 0x68)(r2)
	stw		r27, (INT_FORTH_CTX + CTX_GPRS + 0x6C)(r2)
	stw		r28, (INT_FORTH_CTX + CTX_GPRS + 0x70)(r2)
	stw		r29, (INT_FORTH_CTX + CTX_GPRS + 0x74)(r2)
	stw		r30, (INT_FORTH_CTX + CTX_GPRS + 0x78)(r2)
	stw		r31, (INT_FORTH_CTX + CTX_GPRS + 0x7C)(r2)	
	
	mfsprg	r7, 3						; Saved R2
	stw		r7, (INT_FORTH_CTX + CTX_GPRS + 0x8)(r2)
	mflr	r7
	stw		r7, (INT_FORTH_CTX + CTX_LR)(r2)
	mfctr	r7
	stw		r7, (INT_FORTH_CTX + CTX_CTR)(r2)
	lwz		r7, INT_CR(r2)
	stw		r7, (INT_FORTH_CTX + CTX_CR)(r2)
	mfxer	r7
	stw		r7, (INT_FORTH_CTX + CTX_XER)(r2)
	
	subi	r30, r30, 0x20		; Put some space on the stacks for
	subi	r31, r31, 0x20		;  faulty handler code, primitives

	ba		__restore_r2_r7_cr

_0x0B00_end:
	if HIGH_VECTORS
__save_forth_ctx	set (save_forth_ctx - _0x0B00_begin) + 0xFFF00B00
	else
__save_forth_ctx	set (save_forth_ctx - _0x0B00_begin) + 0xB00
	endif



	VECTOR 0xC00, (_0x0C00_end - _0x0C00_begin) >> 2
; 0x0C00 - system call
_0x0C00_begin:
	ifdef _PPC_SQUARES
	
_HANDLER_0xC00 set 1
	include 'ppc-squares.S'
_HANDLER_0xC00 set 0

	else

	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)

	lwz		r7, INT_FORTH_UP(r2)
	andi.	r7, r7, 1
	beqa-	__restore_r2_r7_cr	; If Forth's not running, ignore.
	
	mfsrr0	r7					; Remember who did the sc
	stw		r7, INT_HANDLER_RA(r2)
	
	lwz		r7, INT_SYSCALL(r2)	; Return to the system call handler
	mtsrr0	r7
	
	ba		__restore_r2_r7_cr
	
	endif
_0x0C00_end:
	

	VECTOR 0xD00, (_0x0D00_end - _0x0D00_begin) >> 2
; 0x0D00 - trace
_0x0D00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0xD00			; Perhaps will use for the debug group later.
	ba		__forth_quit
_0x0D00_end:


	VECTOR 0xE00, (_0x0E00_end - _0x0E00_begin) >> 2
; 0x0E00 - FP assist
_0x0E00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0xE00			; Sorry, we can't be of assistance.
	ba		__forth_quit
_0x0E00_end:


	VECTOR 0xF00, (_0x0F00_end - _0x0F00_begin) >> 2
; 0x0F00 - performance monitor
_0x0F00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0xF00
	ba		__forth_quit
	nop

; 0x0F20 - AltiVec unavailable
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0xF20
	ba		__forth_quit
_0x0F00_end:


; These specialized SWT handlers are for 603[e][v]-types only!
;  They rely on the 603's temporary GPRs and are therefore
;  incompatible with 745/755/74xx processors, which do not have them.
;  However, they should work with G2[_LE].

; Format of translations for SWT/DSI/ISI handlers:
;  virt1 virt2 virt3 ... virtn size1 size2 ... sizen phys-mode1 phys-mode2 ... phys-moden

	VECTOR 0x1000, (_0x1000_end - _0x1000_begin) >> 2
; 0x1000 - SWT ITLB fault
_0x1000_begin:
	mfsprg	r2, 1
	mfsdr1	r3					; test if client has taken over mapping (see 0x0300)
	lwz		r2, INT_MY_SDR1(r2)
	mfsprg	r0, 0
	cmplw	r2, r3
	mfsprg	r1, 2
	bnea-	__itlb_fault_pt		; if so, branch to the "standard" SWT handlers

	mr.		r0, r0
; cache line
	mfctr	r3
	blt		_0x1000_notfound_no_ctr
	mtsprg	3, r3
	mfspr	r2, imiss
	mtctr	r0
	lwz		r0, 0(r1)
	beq		_0x1000_pretest
_0x1000_loop:
	lwzu	r3, 4(r1)
; cache line
	cmplw	r2, r3
	blt		_0x1000_test
	mr		r0, r3
	bdnz	_0x1000_loop
_0x1000_pretest:
	addi	r1, r1, 4
_0x1000_test:
	mfsprg	r3, 0
	subf	r0, r0, r2
	slwi	r3, r3, 2
; cache line
	lwzux	r2, r1, r3				; everyone's favorite instruction
	cmplw	r0, r2
	addi	r1, r1, 4
	bge		_0x1000_notfound
	lwzx	r2, r3, r1
	mfsprg	r1, 3
	clrrwi	r0, r0, 12
	mtctr	r1
; cache line
	add		r0, r0, r2
	mfspr	r1, imiss
	mfsrr1	r3
	mtspr	rpa, r0
	tlbli	r1
	mtcrf	0x80, r3
	rfi
_0x1000_notfound:
	mfsprg	r2, 3
; cache line
	mtctr	r2
_0x1000_notfound_no_ctr:
	mfmsr	r0
	mfsrr1	r1
	xoris	r0, r0, 0x2
	mtcrf	0x80, r1
	mtmsr	r0
itlb_fault_error:
	mtsprg	3, r2
	mfsprg	r2, 1
; cache line
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	mfspr	r7, imiss
	mtdar	r7
	li		r7, 0x1000
	ba		__forth_quit

	if HIGH_VECTORS
__itlb_fault_error	set (itlb_fault_error - _0x1000_begin) + 0xFFF01000
	else
__itlb_fault_error	set (itlb_fault_error - _0x1000_begin) + 0x1000
	endif
_0x1000_end:


	VECTOR 0x1100, (_0x1100_end - _0x1100_begin) >> 2
; 0x1100 - SWT DTLB read fault
_0x1100_begin:
	mfsprg	r2, 1
	mfsdr1	r3					; test whether client has taken over mapping (see 0x0300)
	lwz		r2, INT_MY_SDR1(r2)
	mfsprg	r0, 0
	cmplw	r2, r3
	mfsprg	r1, 2
	bnea-	__dtlb_read_fault_pt
dtlb_write_fault_entry:
	mr.		r0, r0
; cache line
	mfctr	r3
	blt		_0x1100_notfound_no_ctr
	mtsprg	3, r3
	mfspr	r2, dmiss
	mtctr	r0
	lwz		r0, 0(r1)
	beq		_0x1100_pretest
_0x1100_loop:
	lwzu	r3, 4(r1)
; cache line
	cmplw	r2, r3
	blt		_0x1100_test
	mr		r0, r3
	bdnz	_0x1100_loop
_0x1100_pretest:
	addi	r1, r1, 4
_0x1100_test:
	mfsprg	r3, 0
	subf	r0, r0, r2
	slwi	r3, r3, 2
; cache line
	lwzux	r2, r1, r3
	cmplw	r0, r2
	addi	r1, r1, 4
	bge		_0x1100_notfound
	lwzx	r2, r3, r1
	mfsprg	r1, 3
	clrrwi	r0, r0, 12
	mtctr	r1
; cache line
	add		r0, r0, r2
	mfspr	r1, dmiss
	ori		r0, r0, 0x80		; set C bit so we aren't unnecessarily bothered by 0x1200
	mfsrr1	r3
	mtspr	rpa, r0
	tlbld	r1
	mtcrf	0x80, r3
	rfi
; cache line
_0x1100_notfound:
	mfsprg	r2, 3
	mtctr	r2
_0x1100_notfound_no_ctr:
	mfmsr	r0
	mfsrr1	r1
	xoris	r0, r0, 0x2
	mtcrf	0x80, r1
	mtmsr	r0
dtlb_fault_error:
	mtsprg	3, r2
; cache line
	mfmsr	r2
	rlwinm	r2, r2, 0, 0x1
	mfspr	r7, dmiss
	neg		r2, r2
	rlwinm	r2, r2, 0, 0x7
	xor		r7, r7, r2
	mtdar	r7
	mfsprg	r2, 1
; cache line
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	li		r7, 0x1100
	ba		__forth_quit
	
	if HIGH_VECTORS
__dtlb_write_fault_entry	set (dtlb_write_fault_entry - _0x1100_begin) + 0xFFF01100
__dtlb_fault_error			set (dtlb_fault_error - _0x1100_begin) + 0xFFF01100
	else
__dtlb_write_fault_entry	set (dtlb_write_fault_entry - _0x1100_begin) + 0x1100
__dtlb_fault_error			set (dtlb_fault_error - _0x1100_begin) + 0x1100
	endif
_0x1100_end:


	VECTOR 0x1200, (_0x1200_end - _0x1200_begin) >> 2
; 0x1200 - SWT DTLB write fault
_0x1200_begin:
; with our normal specialized handlers, since we set C
;  in 0x1100, only the DTLB miss on store case is possible
	mfsprg	r2, 1
	mfsdr1	r3					; test if client has taken over mapping (see 0x0300)
	lwz		r2, INT_MY_SDR1(r2)
	mfsprg	r0, 0
	cmplw	r2, r3
	mfsprg	r1, 2
	beqa+	__dtlb_write_fault_entry
	ba		__dtlb_write_fault_pt
_0x1200_end:


	VECTOR 0x1300, (_0x1300_end - _0x1300_begin) >> 2
; 0x1300 - instruction breakpoint
_0x1300_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1300
	ba		__forth_quit
_0x1300_end:


	VECTOR 0x1400, (_0x1400_end - _0x1400_begin) >> 2
; 0x1400 - system management
_0x1400_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1400
	ba		__forth_quit
_0x1400_end:


	VECTOR 0x1500, (_0x1500_end - _0x1500_begin) >> 2
; 0x1500 - reserved
_0x1500_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1500
	ba		__forth_quit
_0x1500_end:


	VECTOR 0x1600, (_0x1600_end - _0x1600_begin) >> 2
; 0x1600 - AltiVec assist
_0x1600_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1600
	ba		__forth_quit
_0x1600_end:


	VECTOR 0x1700, (_0x1700_end - _0x1700_begin) >> 2
; 0x1700 - thermal
_0x1700_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1700
	ba		__forth_quit
_0x1700_end:


	VECTOR 0x1800, (_0x1800_end - _0x1800_begin) >> 2
; 0x1800 - reserved
_0x1800_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1800
	ba		__forth_quit
_0x1800_end:


	VECTOR 0x1900, (_0x1900_end - _0x1900_begin) >> 2
; 0x1900 - reserved
_0x1900_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1900
	ba		__forth_quit
_0x1900_end:


	VECTOR 0x1A00, (_0x1A00_end - _0x1A00_begin) >> 2
; 0x1A00 - reserved
_0x1A00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1A00
	ba		__forth_quit
_0x1A00_end:


	VECTOR 0x1B00, (_0x1B00_end - _0x1B00_begin) >> 2
; 0x1B00 - reserved
_0x1B00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1B00
	ba		__forth_quit
	nop
; cache line
got_client_exception2:
	lwz		r7, INT_TEMP_DBATS + 0x00(r2)
	mtspr	dbat0u, r7
	isync
	lwz		r7, INT_TEMP_DBATS + 0x04(r2)
	mtspr	dbat0l, r7
	isync
	lwz		r7, INT_TEMP_DBATS + 0x08(r2)
	mtspr	dbat1u, r7
; cache line
	isync
	lwz		r7, INT_TEMP_DBATS + 0x0C(r2)
	mtspr	dbat1l, r7
	isync
	lwz		r7, INT_TEMP_DBATS + 0x10(r2)
	mtspr	dbat2u, r7
	isync
	lwz		r7, INT_TEMP_DBATS + 0x14(r2)
; cache line
	mtspr	dbat2l, r7
	isync
	lwz		r7, INT_TEMP_DBATS + 0x18(r2)
	mtspr	dbat3u, r7
	isync
	lwz		r7, INT_TEMP_DBATS + 0x1C(r2)
	mtspr	dbat3l, r7
	isync
; cache line
	
	mfsrr1	r7
	rlwinm	r7, r7, 0, 0xFFFF7FFF		; Turn EE off
	ba		__restore_r2_r7_cr_msr		; Restore all regs, setup our MSR
										;  and jump to handler
	if HIGH_VECTORS
__got_client_exception2	set (got_client_exception2 - _0x1B00_begin) + 0xFFF01B00
	else
__got_client_exception2	set (got_client_exception2 - _0x1B00_begin) + 0x1B00
	endif

_0x1B00_end:


	VECTOR 0x1C00, (_0x1C00_end - _0x1C00_begin) >> 2
; 0x1C00 - reserved
_0x1C00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1C00
	ba		__forth_quit
	nop
; cache line
itlb_fault_pt:

;; "Standard" page-table-based SWT handlers, from the PowerPC 603E
;;   User's Manual, by Freescale.

; Instruction TB miss flow
; Entry:
; Vec = 1000
; srr0 -> address of instruction that missed
; srr1 -> 0:3=cr0 4=lru way bit 16:31 = saved MSR
; msr<tgpr> -> 1
; imiss -> ea that missed
; icmp -> the compare value for the va that missed
; hash1 -> pointer to first hash pteg
; hash2 -> pointer to second hash pteg
;
; Register usage:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
tlbInstrMiss:
	mfspr	r2, hash1 ; get first pointer
	addi	r1, 0, 8 ; load 8 for counter
	mfctr	r0 ; save counter
	mfspr	r3, icmp ; get first compare value
	addi	r2, r2, -8 ; pre dec the pointer
im0:
	mtctr	r1 ; load counter
im1:
	lwzu	r1, 8(r2) ; get next pte
	cmpw	r1, r3 ; see if found pte
; cache line
	bdnzf	0, im1 ; dec count br if cmp ne and if count not zero
	bne		instrSecHash ; if not found set up second hash or exit
	lwz		r1, +4(r2) ; load tlb entry lower-word
	andi.	r3, r1, 8 ; check G bit
	bne		itlb_fault_pt_err_prot ; if guarded, error (** MODIFIED)
	mtctr	r0 ; restore counter
	mfspr	r0, imiss ; get the miss address for the tlbli
	mfspr	r3, srr1 ; get the saved cr0 bits
; cache line
	mtcrf 	0x80, r3 ; restore CR0
	mtspr 	rpa, r1 ; set the pte
	ori 	r1, r1, 0x100 ; set reference bit
	srw 	r1, r1, 8 ; get byte 7 of pte
	tlbli 	r0 ; load the itlb
	stb 	r1, +6(r2) ; update page table
	rfi 	; return to executing program
;+
; Register usage:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;-
instrSecHash:
	andi. r1, r3, 0x0040 ; see if we have done second hash
; cache line
	bne itlb_fault_pt_err ; if so, error (** MODIFIED)
	mfspr r2, hash2 ; get the second pointer
	ori r3, r3, 0x0040 ; change the compare value
	addi r1, 0, 8 ; load 8 for counter
	addi r2, r2, -8 ; pre dec for update on load
	b im0 ; try second hash

; (** MODIFIED) renamed doISI to itlb_fault_pt_err
;+
; entry Not Found: synthesize an ISI exception
; guarded memory protection violation: synthesize an ISI exception
; Entry:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;
itlb_fault_pt_err_prot:
	mfspr r3, srr1 ; get srr1
	andi. r2,r3,0xffff ; clean upper srr1
; cache line
	addis r2, r2, 0x0800 ; or in srr<4> = 1 to flag prot violation
	b isi1
itlb_fault_pt_err:
	mfspr r3, srr1 ; get srr1
	andi. r2, r3, 0xffff ; clean srr1
	addis r2, r2, 0x4000 ; or in srr1<1> = 1 to flag pte not found
isi1:
	mtctr r0 ; restore counter
	mtspr srr1, r2 ; set srr1
	mfmsr r0 ; get msr
; cache line
	xoris r0, r0, 0x2 ; flip the msr<tgpr> bit (** MODIFIED: had xoris r0, r0, 0x8000)
	mtcrf 0x80, r3 ; restore CR0
	mtmsr r0 ; flip back to the native gprs

	ba			__itlb_fault_error	; (** MODIFIED) send an exception to Forth
	

	if HIGH_VECTORS
__itlb_fault_pt		set (itlb_fault_pt - _0x1C00_begin) + 0xFFF01C00
	else
__itlb_fault_pt		set (itlb_fault_pt - _0x1C00_begin) + 0x1C00
	endif
_0x1C00_end:



	VECTOR 0x1D00, (_0x1D00_end - _0x1D00_begin) >> 2
; 0x1D00 - reserved
_0x1D00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1D00
	ba		__forth_quit
	nop
; cache line

dtlb_read_fault_pt:
;+
; Data TLB miss flow
; Entry:
; Vec = 1100
; srr0 -> address of instruction that caused data tlb miss
; srr1 -> 0:3=cr0 4=lru way bit 5=1 if store 16:31 = saved MSR
; msr<tgpr> -> 1
; dmiss -> ea that missed
; dcmp -> the compare value for the va that missed
; hash1 -> pointer to first hash pteg
; hash2 -> pointer to second hash pteg
;
; Register usage:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;-
tlbDataMiss:
	mfspr r2, hash1 ; get first pointer
	addi r1, 0, 8 ; load 8 for counter
	mfctr r0 ; save counter
	mfspr r3, dcmp ; get first compare value
	addi r2, r2, -8 ; pre dec the pointer
dm0:
	mtctr r1 ; load counter
dm1:
	lwzu r1, 8(r2) ; get next pte
	cmp 0, r1, r3 ; see if found pte
; cache line
	bdnzf 0, dm1 ; dec count br if cmp ne and if count not zero
	bne dataSecHash ; if not found set up second hash or exit
	lwz r1, +4(r2) ; load tlb entry lower-word
	mtctr r0 ; restore counter
	mfspr r0, dmiss ; get the miss address for the tlbld
	mfspr r3, srr1 ; get the saved cr0 bits
	mtcrf 0x80, r3 ; restore CR0
	mtspr rpa, r1 ; set the pte
; cache line
	ori r1, r1, 0x100 ; set reference bit
	srw r1, r1, 8 ; get byte 7 of pte
	tlbld r0 ; load the dtlb
	stb r1, +6(r2) ; update page table
	rfi ; return to executing program
;+
; Register usage:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;-
dataSecHash:
	andi. r1, r3, 0x0040 ; see if we have done second hash
	bne dtlb_fault_pt_err ; if so, go to DSI exception
	mfspr r2, hash2 ; get the second pointer
; cache line
	ori r3, r3, 0x0040 ; change the compare value
	addi r1, 0, 8 ; load 8 for counter
	addi r2, r2, -8 ; pre dec for update on load
	b dm0 ; try second hash
;

; (** MODIFIED) moved doDSI here for space reasons & renamed
;+
; entry Not Found: synthesize a DSI exception
; Entry:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;
dtlb_fault_pt_err:
	mfspr r3, srr1 ; get srr1
	rlwinm r1, r3, 9,6,6 ; get srr1<flag> to bit 6 for load/store, zero rest
	addis r1, r1, 0x4000 ; or in dsisr<1> = 1 to flag pte not found
	b dsi1
; cache line
dtlb_fault_pt_err_prot:
	mfspr r3, srr1 ; get srr1
	rlwinm r1, r3, 9,6,6 ; get srr1<flag> to bit 6 for load/store, zero rest
	addis r1, r1, 0x0800 ; or in dsisr<4> = 1 to flag prot violation
dsi1:
	mtctr r0 ; restore counter
	andi. r2, r3, 0xffff ; clear upper bits of srr1
	mtspr srr1, r2 ; set srr1
	mtspr dsisr, r1 ; load the dsisr
	;
	; (** MODIFIED): excerpted code which moved DMISS to DAR (0x1100 does this)
	;
	mfmsr r0 ; get msr
; cache line
	xoris r0, r0, 0x2 ; flip the msr<tgpr> bit
	mtcrf 0x80, r3 ; restore CR0
	mtmsr r0 ; flip back to the native gprs
	
	ba		__dtlb_fault_error

	if HIGH_VECTORS
__dtlb_read_fault_pt		set (dtlb_read_fault_pt - _0x1D00_begin) + 0xFFF01D00
__dtlb_fault_pt_err			set (dtlb_fault_pt_err - _0x1D00_begin) + 0xFFF01D00
__dtlb_fault_pt_err_prot	set (dtlb_fault_pt_err_prot - _0x1D00_begin) + 0xFFF01D00
	else
__dtlb_read_fault_pt		set (dtlb_read_fault_pt - _0x1D00_begin) + 0x1D00
__dtlb_fault_pt_err			set (dtlb_fault_pt_err - _0x1D00_begin) + 0x1D00
__dtlb_fault_pt_err_prot	set (dtlb_fault_pt_err_prot - _0x1D00_begin) + 0x1D00
	endif
_0x1D00_end:


	VECTOR 0x1E00, (_0x1E00_end - _0x1E00_begin) >> 2
; 0x1E00 - reserved
_0x1E00_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1E00
	ba		__forth_quit
	nop

dtlb_write_fault_pt:
;+
; C=0 in dtlb and dtlb miss on store flow
; Entry:
; Vec = 1200
; srr0 -> address of store that caused the exception
; srr1 -> 0:3=cr0 4=lru way bit 5=1 16:31 = saved MSR
; msr<tgpr> -> 1
; dmiss -> ea that missed
; dcmp -> the compare value for the va that missed
; hash1 -> pointer to first hash pteg
; hash2 -> pointer to second hash pteg
;
; Register usage:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;-
tlbCeq0:
	mfspr r2, hash1 ; get first pointer
	addi r1, 0, 8 ; load 8 for counter
	mfctr r0 ; save counter
	mfspr r3, dcmp ; get first compare value
	addi r2, r2, -8 ; pre dec the pointer
ceq0:
	mtctr r1 ; load counter
ceq1:
	lwzu r1, 8(r2) ; get next pte
	cmp 0, r1, r3 ; see if found pte
; cache line
	bdnzf 0, ceq1 ; dec count br if cmp ne and if count not zero
	bne cEq0SecHash ; if not found set up second hash or exit
	lwz r1, +4(r2) ; load tlb entry lower-word
	andi. r3,r1,0x80 ; check the C-bit
	beq cEq0ChkProt ; if (C==0) go check protection modes
ceq2:
	mtctr r0 ; restore counter
	mfspr r0, dmiss ; get the miss address for the tlbld
	mfspr r3, srr1 ; get the saved cr0 bits
; cache line
	mtcrf 0x80, r3 ; restore CR0
	mtspr rpa, r1 ; set the pte
	tlbld r0 ; load the dtlb
	rfi ; return to executing program
;+
; Register usage:
; r0 is saved counter
; r1 is junk
; r2 is pointer to pteg
; r3 is current compare value
;-
cEq0SecHash:
	andi. r1, r3, 0x0040 ; see if we have done second hash
	bnea __dtlb_fault_pt_err ; if so, error (** MODIFIED)
	mfspr r2, hash2 ; get the second pointer
	ori r3, r3, 0x0040 ; change the compare value
; cache line
	addi r1, 0, 8 ; load 8 for counter
	addi r2, r2, -8 ; pre dec for update on load
	b ceq0 ; try second hash
;+
; entry found and PTE(c-bit==0):
; (check protection before setting PTE(c-bit)
; Register usage:
; r0 is saved counter
; r1 is PTE entry
; r2 is pointer to pteg
; r3 is trashed
;-
cEq0ChkProt:
	rlwinm. r3,r1,30,0,1 ; test PP
	bge- chk0 ; if (PP==00 or PP==01) goto chk0:
	andi. r3,r1,1 ; test PP[0]
	beq+ chk2 ; return if PP[0]==0
	ba		__dtlb_fault_pt_err_prot ; else error (** MODIFIED)
; cache line
chk0:
	mfspr r3,srr1 ; get old msr
	andis. r3,r3,0x0008 ; test the KEY bit (SRR1-bit 12)
	beq chk2 ; if (KEY==0) goto chk2:
	ba		__dtlb_fault_pt_err_prot ; else error (** MODIFIED)
chk2:
	ori r1, r1, 0x180 ; set reference and change bit
	sth r1, 6(r2) ; update page table
	b ceq2 ; and back we go
;


	if HIGH_VECTORS
__dtlb_write_fault_pt	set (dtlb_write_fault_pt - _0x1E00_begin) + 0xFFF01E00
	else
__dtlb_write_fault_pt	set (dtlb_write_fault_pt - _0x1E00_begin) + 0x1E00
	endif
_0x1E00_end:

	VECTOR 0x1F00, (_0x1F00_end - _0x1F00_begin) >> 2
; 0x1F00 - reserved
_0x1F00_begin:
	ifdef _PPC_SQUARES
	
_HANDLER_0x1F00 set 1
	include 'ppc-squares.S'
_HANDLER_0x1F00 set 0

	else

	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1F00
	ba		__forth_quit
	
	endif
_0x1F00_end:


	VECTOR 0x2000, (_0x2000_end - _0x2000_begin) >> 2
; 0x2000 - 601 runmode/trace
_0x2000_begin:
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x2000
	ba		__forth_quit
_0x2000_end:	

	NO_MORE_VECTORS


; PPCAsm :TOF:ppc-vectors.S

; DumpXCOFF :TOF:ppc-vectors.S.o -a -do t -dialect powerPC32 -ntb