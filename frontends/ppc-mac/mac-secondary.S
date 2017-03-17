	include 'ppc-func.i'
	include 'ppc-boot.i'
	
	func denter
;		void denter(entry_struct *)
	
	lwz		r4, 0(r3)
	mtctr	r4
	
	lwz		r4, 8(r3)
	lwz		r5, 12(r3)
	lwz		r6, 16(r3)
	lwz		r7, 20(r3)
	lwz		r8, 24(r3)
	lwz		r9, 28(r3)
	lwz		r10, 32(r3)
	lwz		r11, 36(r3)
	
	lwz		r3, 4(r3)
	
	
;		void enter(void *code68k, entry_struct *es)
	func enter
	import .CallUniversalProc
	
	mflr	r0
	stw		r0, -4(SP)
	subi	SP, SP, 0x10
	
	mr		r6, SP
	clrrwi	SP, SP, 10			; Align to page
	stwu	r6, -0x480(SP)		; Make a 0x480 + pagealign byte frame
								;  Need extra space for linkage for CallUniversalProc
	addi	r6, SP, 0x80		; Frame ptr for NK call
	
	li		r8, 0x100			; #words
	subi	r7, r6, 4			; Predecrement for update
	mtctr	r8
	li		r8, 0
VPClear:
	stwu	r8, 4(r7)
	bdnz	VPClear

	bl		e_h
e_h:
	mflr	r5					; Get virtual address of preboot
	addi	r5, r5, preboot - e_h
	stw		r5, 0xFC(r6)		; PC to be
	
	lwz		r5, 12(r4)
	lwz		r7, 20(r4)
	lwz		r8, 24(r4)
	lwz		r9, 28(r4)
	lwz		r10, 32(r4)
	lwz		r11, 36(r4)
	lwz		r0, 0(r4)
	
	stw		r5, 0x12C(r6)
	stw		r7, 0x13C(r6)
	stw		r8, 0x144(r6)
	stw		r9, 0x14C(r6)
	stw		r10, 0x154(r6)
	stw		r11, 0x15C(r6)
	stw		r0, 0x164(r6)		; r12 - ppc-boot entrypoint for preboot

	lwz		r9, 4(r4)
	lwz		r10, 8(r4)
	lwz		r11, 16(r4)
	stw		r9, 0x11C(r6)
	stw		r10, 0x124(r6)
	stw		r11, 0x134(r6)

								; Code address in r3
	li		r4, 0xC0			; ProcInfo: Pascal stack-based, one four-byte argument, no result
	mr		r5, r6				; Frame for the NanoKernel
	bl		.CallUniversalProc	; Jump to Visor68K (LR update hopefully unneccessary, except possibly for the linker)
	lwz		RTOC, 0x14(SP)		; TOC reload

	lwz		SP, 0(SP)
	addi	SP, SP, 0x10
	lwz		r0, -4(SP)
	mtlr	r0
	blr
	
preboot:						; Turn off translation here before entering ppc-boot
	
; First flush the data cache while the EAs it contains are valid.
	lis		r1, 1				; Flush 2M. This should obliterate any cached data whatsoever.

;** Keep this in sync with ppc-boot, which we should not call in this state.
	if STATIC_ROM_ADDR
	lis		r2, ROM_FLUSH_HIGH
	else
	slwi	r2, r9, 3
	lwzx	r2, r2, r8
	endif
	
	mtctr	r1
	subi	r2, r2, 0x20
ldp_loop:
	lwzu	r1, 0x20(r2)		; Fill the caches with ROM, ha!
	bdnz	ldp_loop
	sync
;**
	
; Do we want to inval instruction cache here (if possible?)

	mfmsr	r1
	rlwinm	r1, r1, 0, 0xFFFFFFCF	; IR, DR off
	rlwinm	r1, r1, 0, 0xFFFFF0FF	;  and FE0, BE, SE, FE1 for good measure
	rlwinm	r1, r1, 0, 0xFFFE3FFF	;  and ILE, EE, PR, all of which should be off
	mtsrr0	r12					; ppc-boot entry was put here
	mtsrr1	r1
	rfi
	
	nop
	nop
	nop
	nop

; PPCAsm :TOF:mac-secondary.S -o :TOF:object:mac-secondary.S.o
