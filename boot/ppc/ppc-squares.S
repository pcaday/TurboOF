	if DEBUG_OUTPUT
	
_PPC_SQUARES set 1

	ifdef _HANDLER_0xC00
	if _HANDLER_0xC00

H_ADV set 0x90				; X advance per output
	
; SC handler for implementing debug markers

	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	stw		r1, INT_R1(r2)
	mfctr	r1
	stw		r0, INT_R0(r2)
; cache line
	stw		r3, INT_R3(r2)
	stw		r1, INT_CTR(r2)

; registers:
;  r0  linebytes
;  r1  base address
;  r2  color word
;  r3  link save
;  r7  data
; cr3  so: 2bytes?, gt: more byte?

; Get and advance the line position

	lwz		r7, INT_V_H(r2)
	addi	r3, r7, H_ADV
	lwz		r1, INT_V_WIDTH(r2)
	lwz		r0, INT_V_LINE(r2)
	cmplw	r3, r1
	lwz		r1, INT_V_BASE(r2)
; cache line
	ble		dm_size_ok
	slwi	r3, r0, 5
	add		r1, r1, r3
	stw		r1, INT_V_BASE(r2)
	li		r3, H_ADV
	li		r7, 0
dm_size_ok:
	stw		r3, INT_V_H(r2)
	add		r1, r1, r7

; Find the input register among r0, r1, r10, r31
; input format:
;  0xBABA00nn	mark point nn
;  0xBABBnnnn	16 bit datum

; cache line
	lwz		r7, INT_R1(r2)
	srwi	r3, r7, 0x11
	cmplwi	r3, 0x5D5D
	beq		dm_reg_ok
	lwz		r7, INT_R0(r2)
	srwi	r3, r7, 0x11
	cmplwi	r3, 0x5D5D
	beq		dm_reg_ok
; cache line
	srwi	r3, r10, 0x11
	mr		r7, r10
	cmplwi	r3, 0x5D5D
	beq		dm_reg_ok
	mr		r7, r31
dm_reg_ok:
	mtcr	r7
	crclr	cr3_eq
	mflr	r3
; cache line
	bso		cr3, dm_line
	rotlwi	r7, r7, 8

; Draw the squares.
dm_line:
	bla		__dm_square
	bla		__dm_square
	bla		__dm_square
	bla		__dm_square
	bns		cr3, dm_l2
	bla		__dm_square
; cache line
	bla		__dm_square
	bla		__dm_square
	bla		__dm_square
	subi	r1, r1, 0x40
dm_l2:
	slwi	r2, r0, 4
	subi	r1, r1, 0x40
	crnot	cr3_eq, cr3_eq
	add		r1, r1, r2
; cache line
	beq		cr3, dm_line
	mtlr	r3
	mfsprg	r2, 1
	lwz		r1, INT_R1(r2)
	lwz		r0, INT_R0(r2)
	lwz		r3, INT_R3(r2)
	sync						; Make sure all the video data is written
	ba		__restore_r2_r7_cr_ctr	; We don't have room to do it here.
	
	endif
	endif
	
	ifdef _HANDLER_0x1F00
	if _HANDLER_0x1F00
	
	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	
	li		r7, 0x1F00
	ba		__forth_quit
	nop
; cache line

dm_square:
; Colors: markers: red dark (4) and light (C), data: blue dark(1) and light(9).
	li		r2, 0xC
	mtctr	r2
	rlwinm	r2, r7, 20, 0x8
	ori		r2, r2, 1
	bso		cr3, dm_sq_m1
	xori	r2, r2, 5
dm_sq_m1:
	rlwimi	r2, r2, 8, 16, 23
	rlwimi	r2, r2, 16, 0, 15
; cache line
dm_sq_l:
	stw		r2, 0(r1)
	stw		r2, 4(r1)
	stw		r2, 8(r1)
	dcbf	0, r1			; Make sure it's stored - must not be left in cache
	add		r1, r1, r0
	bdnz	dm_sq_l
	mulli	r2, r0, 0xC
	addi	r1, r1, 0x10
; cache line
	subf	r1, r2, r1
	rotlwi	r7, r7, 1
	blr


	if HIGH_VECTORS
__dm_square set (dm_square - _0x1F00_begin) + 0xFFF01F00
	else
__dm_square set (dm_square - _0x1F00_begin) + 0x00001F00
	endif
	
	endif
	endif
	
	endif