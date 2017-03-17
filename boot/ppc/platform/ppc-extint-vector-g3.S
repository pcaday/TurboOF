; External interrupt vector code for Gossamer -- checks for NMI

	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, _R7(r2)
	mfcr	r7
	stw		r7, _CR(r2)
	stw		r0, _R0(r2)
			
	lis		r7, 0xF300

	lwz		r0, 0x20(r7)
	andi.	r0, r0, 0x1000		; check for NMI

	li		r0, -1
	stw		r0, 0x18(r7)		; clear out interrupts (set 2)
	stw		r0, 0x28(r7)		; clear out interrupts (set 1)
	dcbf	0, r7				; make sure it gets done
	addi	r7, r7, 0x20
	dcbf	0, r7
	lwz		r0, _R0(r2)
	sync						; if we don't wait for the interrupt clearing to complete,
								;  it may interrupt a few more times
	li		r7, 0x500
	bnea	__forth_quit		; quit if NMI
	ba		__restore_r2_r7_cr
