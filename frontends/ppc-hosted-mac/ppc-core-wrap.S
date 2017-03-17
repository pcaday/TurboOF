	include 'ppc-func.i'
	include 'ppc-core-wrap.i'

	import alarm_iv[RW]
	import alarm_rsp[RW]
	import alarm_dsp[RW}
	
	impd alarm_iv
	impd alarm_rsp
	impd alarm_dsp
	
	func trunc
	
	clrrwi	r3, r3, 12
	blr
	
	; Memory Layout of *fmem
	;
	;  +0		Bootstrap dictionary			(room for 0x100 definitions)
	;  +0x1800	Bootstrap compiled code storage	(room for 0x400 tokens)
	;  +0x2800-0x37FF Data stack
	;  +0x37C0	Data stack base					(top of data stack area - 0x40 underflow buffer)
	;  +0x3800-0x47FF Return stack
	;  +0x47C0  Return stack base				(top of return stack area - 0x40 underflow buffer)
	;  +0x4800	Init vector
	;  +0x4900  Forth data area
	;   .
	;   .
	;   .
	;  end		Alloc-mem base (grows backwards)
	
	; void fentry(void *fmem, unsigned int fmem_len, void *ftext)
	func_align fentry, 5
	
	import .Debugger
	
	; Set up stacks, text pointers, empty bootstrap dictionary
	mr		r23, r3
	mr		r24, r3
	addi	r21, r3, 0x1800
	addi	r22, r3, 0x4800
	mr		r25, r5
	mr		r26, r5
	lis		r29, 0xBEEF
	ori		r29, r29, 0xCAFE
	addi	r30, r3, 0x47C0
	addi	r31, r3, 0x37C4
	
	; Set up initvec
	addi	r7, r3, 0x4900
	stw		r7, 0(r22)
	stw		r23, 4(r22)
	subi	r7, r31, 4
	stw		r7, 8(r22)
	stw		r30, 12(r22)
	stw		r25, 16(r22)
	add		r7, r3, r4
	stw		r7, 20(r22)
	stw		r3, 24(r22)
	stw		r4, 28(r22)
	stw		r3, 32(r22)
	stw		r4, 36(r22)

	; Copy primitives into bootstrap dictionary
	bl		__fe_here
__fe_here:
	mflr	r9
	addi	r9, r9, __bcat_start - __fe_here	; Offset to add to bd>code fields

	subi	r8, r9, 4			; Source
	subi	r24, r24, 4			; Destination
	
	li		r0, (__bcat_end - __bcat_start) / BCAT_NSIZE
	mtctr	r0

bcc_l:
	lwz		r10, 4(r8)
	lwz		r11, 8(r8)
	stw		r10, 4(r24)
	add		r11, r11, r9					; Convert code pointer to absolute address
	stw		r11, 8(r24)
	lwz		r10, 12(r8)
	lwz		r11, 16(r8)
	stw		r10, 12(r24)
	stw		r11, 16(r24)
	lwz		r10, 20(r8)
	lwzu	r11, 24(r8)
	stw		r10, 20(r24)
	stwu	r11, 24(r24)
	bdnz	bcc_l

	addi	r24, r24, 4
	li		r0, 0
	stb		r0, 0(r24)		; term

	bl		.Debugger
	tocreload

	lwz		r11, alarm_iv[TC](rtoc)			; Save off init-vec, rsp, dsp for alarm handlers
	stw		r22, 0(r11)

	lwz		r11, alarm_dsp[TC](rtoc)
	subi	r10, r31, 0xC00
	stw		r10, 0(r11)
	
	lwz		r11, alarm_rsp[TC](rtoc)
	subi	r10, r30, 0xC00
	stw		r10, 0(r11)

	b		lop
	
bat_set:
	blr					; Dummy
	
__HOSTED	set 1
DEBUG_OUTPUT set 0

	include 'ppc-core-flat.S'


; PPCAsm -o :TOF:object:ppc-core-wrap.S.o :TOF:ppc-core-wrap.S








