;
;	ppc-boot: pre-Forth initialization
;
;		0. (Secondary) passed address of text, NVRAM, (device tree), (memory configuration)
;		1. (Primary, PS) Initialize memory controller - record memory configuration
;		2. Initialize processor - clear registers
;		3. (Secondary) Move interrupt handlers to 0
;		4. Read and validate NVRAM
;		5. Get real OF memory, (Secondary) Move code, text, NVRAM together into/out of OF memory, if necessary
;		6. (Primary) Move core into OF memory
;		7. Map OF memory WiMg with 1 or 2 BATs, map NVRAM into non-RAM if not in OF memory, (Primary) map text, etc.
;		8. Setup initvec@, Forth registers
;		9. Setup the SPRGs & page table
;		A. Setup for LE, turn on translation, FP and Vec off, LE as appropriate
;		B. Setup bootstrap dictionary & start Forth
;

	include 'ppc-boot.i'
	include 'ppc-vectors.i'
	include	'ppc-core-flat.i'
	
	include 'ppc-boot-intro.S'
	
commencement:

;;;;;;;;;;;;;;; step-0
	
	if SECONDARY_FW

;	r3: text
;	r4: NVRAM
;	r5: device tree addr
;	r6: text length
;	r7: device tree length
;	r8: physical memory config ptr - formatted like "existing" - must be big-endian
;	r9: #entries in r8 table
;	r10: NVRAM physical length
;	r11: (DEBUG) ptr to video params: INT_V_BASE, INT_V_LINE, INT_V_WIDTH, (reset-some) previous little-endian? (LSB)

;	¥ r3-r8 need to be cache block aligned.
;	¥ all addresses are real (physical) addresses
;	¥ for secondary firmware, r5, and r8 *must* point into the text. Otherwise, they may be overwritten.
;   	- r4 must point into the text if and only if NVRAM_IN_TEXT = 1.
;	¥ memory regions in r8 need to be sorted, and can't wrap around 0x00000000.
;   ¥ if STATIC_ROM_ADDR = 0, the ROM address should immediately follow the memory banks in r8^


reset_some_entrance:

	else

	li		r3, TEXT_LOW
	li		r5, 0
	li		r6, -1
	li		r7, 0
	ori		r3, r3, TEXT_HIGH

	endif
	
	mfmsr	r1
	stw		r1, 0x3000(0)
	mfspr	r1, hid0
	stw		r1, 0x3004(0)
	lwz		r1, 0x0(0)
	stw		r1, 0x3008(0)
	li		r1, 0x3000
	dcbf	0, r1

;;;;;;;;;;;;;;; step-1

	if SECONDARY_FW = 0
						; Initialize the memory controller here.
						;  Record physical memory ranges in memory, and set r8 to the baseaddr and r9 to #entries

	endif				; This is also the time to fetch the NVRAM.

;;;;;;;;;;;;;;; step-2


; General initialization.

	if HIGH_VECTORS
	li		r1, 0x2042	; FP, RI, IP
	else
	li		r1, 0x2002	; FP, RI
	endif
	
	isync
	mtmsr	r1
	isync
	sync
	
	li		r0, 0		; We don't clear out GPRs because it's never necessary, and
						;  we use 'em all here.
	
	mtcr	r0			; clear out user SPRs

	if SECONDARY_FW
	andi.	r1, r11, 1	; Move previous little-endian? into cr3_lt
	crnot	cr3_lt, cr0_eq
	
	if DEBUG_OUTPUT
	clrrwi	r11, r11, 2	;  ...and clean up r11 for debug_output
	endif
	
	else
;	crclr	cr3_lt		; Nothing to do... (unnecessary)
	endif
	
;	crclr	cr4_lt		; initially assume no software table lookup (unnecessary)

	mtxer	r0
	mtlr	r0
	
	mtdec	r0			; clear out decrementer (which isn't ticking) - not really necessary

	; Need to case the following if we support processors without FP:
	mtfsfi	cr0, 0		; clear out FPSCR
	mtfsfi	cr1, 0
	mtfsfi	cr2, 0
	mtfsfi	cr3, 0
	mtfsfi	cr4, 0
	mtfsfi	cr5, 0
	mtfsfi	cr6, 0
	mtfsfi	cr7, 0
	
	lfs		fp0, 0(r8)	; get junk data (probably zero) to initialize FP regs.
	fmr		fp1, fp0	; some processors require them to be explicitly loaded.
	fmr		fp2, fp0
	fmr		fp3, fp0
	fmr		fp4, fp0
	fmr		fp5, fp0
	fmr		fp6, fp0
	fmr		fp7, fp0
	fmr		fp8, fp0
	fmr		fp9, fp0
	fmr		fp10, fp0
	fmr		fp11, fp0
	fmr		fp12, fp0
	fmr		fp13, fp0
	fmr		fp14, fp0
	fmr		fp15, fp0
	fmr		fp16, fp0
	fmr		fp17, fp0
	fmr		fp18, fp0
	fmr		fp19, fp0
	fmr		fp20, fp0
	fmr		fp21, fp0
	fmr		fp22, fp0
	fmr		fp23, fp0
	fmr		fp24, fp0
	fmr		fp25, fp0
	fmr		fp26, fp0
	fmr		fp27, fp0
	fmr		fp28, fp0
	fmr		fp29, fp0
	fmr		fp30, fp0
	fmr		fp31, fp0	
	
	mtspr	ibat0u, r0
	mtspr	ibat0l, r0	; invalidate & clear out IBATs/UBATs (on 601)
	mtspr	ibat1u, r0
	mtspr	ibat1l, r0	; We don't need to do this, really; we'll initialize them later...
	mtspr	ibat2u, r0
	mtspr	ibat2l, r0
	mtspr	ibat3u, r0
	mtspr	ibat3l, r0

	li		r2, 0x80	; number of TLB sets to invalidate
	mtctr	r2
	li		r1, 0
s1til:
	tlbie	r1			; clear this set
	addi	r1, r1, 0x1000
	bdnz	s1til

	sync
	mtsdr1	r0			; clear out SDR1

	li		r2, 0x10
	li		r1, 0
	mtctr	r2

s1srl:
	mtsrin	r0, r1		; clear out page table regs
	addi	r1, r1, 1
	bdnz	s1srl

	sync
	isync
	
	if FLUSH_CACHES
	lis		r1, 1		; If configured to flush caches, do it now.
	bl		data_push	; To avoid unnecessary complication, we just flush 2M, regardless
						;  of cache state.
	if FLUSH_DCBI
	lis		r1, 1		;  and dcbi out the flush data if configured to.
	bl		flushdata_dcbi
	endif
	
	isync
	endif	
						; Let everything settleÉ
						; still to do: clear DBATs, EAR, PIR, DABR, IABR...

	mfpvr	r1	
	srwi	r2, r1, 16	;  Processor version
	clrlwi	r1, r1, 16	;  Processor revision

	cmplwi	r2, 1		; 601, 601v
	beq		setup_601
	cmplwi	r2, 3		; 603
	beq		setup_603
	cmplwi	r2, 4		; 604
	beq		setup_604
	cmplwi	r2, 6		; 603e
	beq		setup_603
	cmplwi	r2, 7		; 603ev
	beq		setup_603
	cmplwi	r2, 8		; 740, 745, 750, 755
	beq		setup_750
	cmplwi	r2, 9		; 604e
	beq		setup_604e
	cmplwi	r2, 0xA		; 604ev
	beq		setup_604e
	cmplwi	r2, 0x7000	; 750fx
	beq		setup_750fx
	cmplwi	r2, 0x7002	; 750gx
	beq		setup_750gx
;	cmplwi	r2, 0x8081	; G2
;	beq		setup_g2
;	cmplwi	r2, 0x8082	; G2_LE
;	beq		setup_g2_le
	
; Unknown processor - just do the DBATs and TB
	bl		setup_std
	b		step2_out

setup_std_ear_iabr_pm1_ictc:
	mtspr	ictc, r0	; clear out ICTC
	mtspr	mmcr1, r0	; clear out MMCR1
setup_std_ear_iabr_pm0:
	mtspr	mmcr0, r0	; clear out MMCR0
	mtspr	dabr, r0	; clear out DABR
setup_std_ear_iabr:
	mtspr	ear, r0
	mtspr	iabr, r0	; clear out IABR, EAR
	
; Standard (what the 601 doesn't do but is in the PPC spec)
setup_std:
	mtspr	dbat0u, r0
	mtspr	dbat0l, r0	; invalidate & clear out DBATs
	mtspr	dbat1u, r0
	mtspr	dbat1l, r0
	mtspr	dbat2u, r0
	mtspr	dbat2l, r0
	mtspr	dbat3u, r0
	mtspr	dbat3l, r0
	
	crclr	cr3_so		; we're not a 601
	mttb	r0			; zero the timebase
	mttbu	r0
	blr

; 601
setup_601:
	mtspr	rtcl, r0			; Initialize RTC
	mtspr	rtcu, r0
	mtspr	rtcl, r0
	crset	cr3_so				; Let the world know we have a 601 (shiver)

	mfspr	r1, hid0			; Initialize HID0 - Need more information here.
	rlwinm	r1, r1, 0, 0x8001FFFF	; Checkstop source info off
	rlwinm	r1, r1, 0, 0xFFFFFFF7	; Big-endian memory access
	mtspr	hid0, r1

	mtspr	hid5, r0			; Initialize HID5 (DABR)
	isync						; Make sure it's done before we change what happens on matches
	
	li		r1, 0x4000			; Initialize HID1 - tlbie broadcast off - traces on 0x2000 - normal run mode
	oris	r1, r1, 0x80
	mtspr	hid1, r1
	mtspr	ear, r0				; Silence the ear.
	isync
		
	b		step2_out

; 603
setup_603:
	bl		setup_std_ear_iabr	; DBATs and TB, EAR, IABR
	bl		_603_l1_flush_en	; Flush & enable the L1 caches
	lis		r1, 0xC010			;  DPM, machine checks on; CLK_OUT settings may need to be `personalized'
	ori		r1, r1, 0xC008		;  ABE on, L1 caches on, unlocked, DCBTs active
	sync
	mtspr	hid0, r1
	isync
	crset	cr4_lt				; We have software table lookup (freedom from page tables!)
	b		step2_out

; 604e
setup_604e:
	mtspr	mmcr1, r0			; Disable counting on PMCs 3 & 4

; 604
setup_604:
	bl		setup_std_ear_iabr_pm0
	bl		_603_l1_flush_en
	lis		r1, 0x8000			; Machine checks on
	ori		r1, r1, 0xC086		; L1 caches on, unlocked, BHT enabled, BTAC disabled (will flush)
	ori		r2, r1, 0xC084		; BTAC enabled
	mtspr	hid0, r1
	isync
	mtspr	hid0, r2			; Flush the BTAC
	isync
	b		step2_out

; 750
setup_750:
	if SECONDARY_FW = 0
		; L2CR setting, if any, should occur here.
	endif
	
	crclr	cr7_so				; No built-in L2
	cmplwi	r1, 0x3000			;  Test for 745/755
	blt		setup_750_common	; Not 7x5
	
	mtspr	hid2_755, r0		; Clear out the 755's hid2
	isync
	mtspr	l2pm, r0			; Disable the 755's private memory
	isync
	
setup_750_common:
	bl		setup_std_ear_iabr_pm1_ictc
	bl		_603_l1_flush_en	; Flush & enable L1 caches, ˆ la 603
	
	lis		r1, 0x8000			;  DPM off, MC on, CLK_OUT high-Z
	ori		r1, r1, 0xC084		;  L1 on, store-gathering, BHT
	ori		r2, r1, 0xC0A4		;  BTIC on, too.
	mtspr	hid0, r1			; Flush the BTIC
	isync
	mtspr	hid0, r2
	isync
	bl		l2cr_l2_flush_en	;  Flush it if extant
	bl		thermal_setup		; Let the CPU fry.
	
	mfspr	r1, hid0
	oris	r1, r1, 0x0010		; Now turn DPM on. It must be off for L2 inval.
	mtspr	hid0, r1
	isync
	
	b		step2_out

; 750fx _and_ 750gx
setup_750gx:
setup_750fx:
	if SECONDARY_FW = 0
		; HID1 setting, if any, should happen here.
	endif
	
	crset	cr7_so				; We have built-in L2
	mtspr	hid2_750fx, r0		; Clear out HID2
	isync
	sync
	b		setup_750_common	; The rest is like the normal 750.
	

; Thermal etc.
thermal_setup:
	mtspr	thrm2, r0
	isync						; Order this correctly
	mtspr	thrm0, r0
	mtspr	thrm1, r0
	blr

; 603-type L1 flush/inval/enable
_603_l1_flush_en:
	mfspr	r30, hid0
	mflr	r31
	
	rlwinm	r29, r30, 0, 0xFFFF03FF	; Clear out the L1-related bits
	ori		r2, r29, 0xC000		; L1 enabled
	ori		r1, r29, 0xCC00		; L1 invalidate bits
	bl		lfe_here
lfe_here:
	mflr	r30
	addi	r30, r30, lfe_after_l1 - lfe_here
	icbi	0, r30				; Make sure no weird instructions get loaded
								; while we flush the cache
	addi	r30, r30, 0x20		; Invalidate all around it
	icbi	0, r30
	mtspr	hid0, r29			; L1 off
	sync						; Must sync after disabling L1d
	isync						; and isync.
lfe_after_l1:
	sync						; Must sync before enabling L1d
	isync						; and isync
	mtspr	hid0, r1			; inval on
	mtspr	hid0, r2			; inval off (not necc. for 604 and later)
	sync
	
	mtlr	r31					; Done!
	blr

; L2CR-based L2 flush/inval/enable
l2cr_l2_flush_en:
	mfspr	r30, l2cr			; We may want to sanity check this value.
	mflr	r31

	mr.		r30, r30			; L2 enabled?
	cror	cr0_so, cr0_lt, cr7_so	; Or does the processor come with L2?
	bnslr						;  if not, assume it's nonexistant.
	
	rlwinm	r1, r30, 0, 0x7FFFFFFF	; turn off L2
	sync							;
	mtspr	l2cr, r1				;
	sync							;	
	
	oris	r2, r1, 0x20			; set invalidate bit
	mtspr	l2cr, r2
	isync
	b		l2fe_wait_flush

	align 5
l2fe_wait_flush:
	mfspr	r2, l2cr				; Wait for invalidate to complete
	rlwinm.	r2, r2, 0, 1
	bne		l2fe_wait_flush
	
	rlwinm	r1, r1, 0, 0xFF9FFFFF	; Turn off L2 data-only, if it was on,
	mtspr	l2cr, r1				; and stop invalidating.
	oris	r1, r1, 0x8000
	isync
	mtspr	l2cr, r1				; Now enable L2.
	isync
	
	mtlr	r31
	blr

; Generic data push - r1 contains #blocks
	align	5					; We fit cozily in a cache block

data_push:	
	if STATIC_ROM_ADDR
	lis		r2, ROM_FLUSH_HIGH	; Static: load ROM address directly
	else
	slwi	r2, r9, 3			; Non-static: load ROM address from after memory banks
	lwzx	r2, r2, r8
	endif
	
	mtctr	r1
	subi	r2, r2, 0x20
ldp_loop:
	lwzu	r1, 0x20(r2)		; Fill the caches with ROM, ha!
	bdnz	ldp_loop
	sync						; Make sure it's doneÉ
	blr

; Flush data dcbi routine -- if configured
	if FLUSH_DCBI
	align	5

flushdata_dcbi:						; r1 contains #blocks
	if STATIC_ROM_ADDR
	lis		r2, ROM_FLUSH_HIGH
	else
	slwi	r2, r9, 3
	lwzx	r2, r2, r8
	endif
								; This routine should only be called just after a data_push that used
	mtctr	r1					;  the same number of blocks. Otherwise, we may invalidate good information.
fdd_loop:
	dcbi	0, r2				; dcbi out the blocks
	addi	r2, r2, 0x20
	bdnz	fdd_loop
	sync						; and synchronize
	blr
	
	endif

step2_out:
	sync						; Just for good measure. We're about to move some memory (possibly)

;;;;;;;;;;;;;; step-3: copy vectors in

; (Secondary) First make sure that nothing is in the way of the vectors. If this is the case, my_vectors_in
;              must wait until after step 5, when everything's out of the way. cr4_gt remembers if this is necessary.

	if SECONDARY_FW && COPY_VECTORS
	
	crset	cr4_gt				; Initially assume something's in the way
	
	neg		r1, r3				; Text there?
	cmplwi	cr1, r3, 0x4000
	cmplw	r1, r6
	blt		cr1, step3_part2
	blt		step3_part2

	if NVRAM_IN_TEXT = 0
	neg		r1, r4				; NVRAM there?
	cmplwi	cr1, r4, 0x4000
	cmplw	r1, r10
	blt		cr1, step3_part2
	blt		step3_part2
	endif

	bl		s3s_here			; Are we there?
s3s_here:
	mflr	r2
	neg		r1, r2
	cmplwi	cr1, r2, 0x4000
	cmplwi	r1, last_code - commencement
	blt		cr1, step3_part2
	blt		step3_part2

	crclr	cr4_gt
	
	endif

	bl		my_vectors_in		; This code is common to initialization,
	b		step3_part2			;	 various client-OF switches
	
step3_part2:
	bl		s3_2_here			; Initialize SPRG1 after the vectors are in.

temp_sprg1:
	dc.l	0					; 48 bytes to initialize SPRG1 for the vectors,
	dc.l	0					;  so that they will try to quit instead of calling random code.
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
s3_2_here:
	mflr	r1					; Get the address
	mtsprg	1, r1				;  and stuff in SPRG1. We'll set aside memory for the real thing later.
	
	if DEBUG_OUTPUT

	lwz		r2, 0(r11)			; Initialize the debug output from settings in r11
	stw		r2, INT_V_BASE(r1)
	lwz		r2, 4(r11)
	stw		r2, INT_V_LINE(r1)
	lwz		r2, 8(r11)
	stw		r2, INT_V_WIDTH(r1)
	li		r2, INT_V_BASE
	dcbst	r2, r1
	
;	lis		r0, 0xBABA			; Careful! vectors may not be in
;	ori		r0, r0, 1
;	sc

	li		r0, 0
	
	endif
	
	isync
	
	mfmsr	r1					; Now that vectors are definitely in, enable ME.
	ori		r1, r1, 0x1000		; Set ME
	mtmsr	r1					;
	isync						;

;;;;;;;;;;;;;; step-4

	crset	cr3_eq				; Assume we have NVRAM outside of the text/ppc-boot...
	crclr	cr4_eq				;  and that it is valid	
	
	cmplwi	r10, 0				;  unless r10 is zero
	beq		no_nvram	

	lhz		r13, 4(r4)			; Get NVRAM length (in words) --> r13
	mr		r31, r4				; Initialize NVRAM pointer
	
	if NVRAM_MIN_LEN > 0
	cmplwi	r13, NVRAM_MIN_LEN	; If a minimum NVRAM word length has been set,
	blt		no_nvram			;  make sure that it is obeyed.
	endif
	
	subi	r1, r13, 1			; #words to checksum
	slwi	r13, r13, 2			; Get NVRAM in words
	cmplw	r13, r10			; Compare claimed NVRAM length against physical NVRAM length (for safety -- NVRAM could be in I/O mem)
	bgt		no_nvram			;  The claimed length is too long, use the default.
	
	mr		r2, r0				; Zero out checksum
	mtctr	r1
	
nxs_loop:
	lwzu	r1, 4(r31)			; Checksum the NVRAM, employing a very simple method.
	rotlwi	r2, r2, 15
	xor		r2, r2, r1
	bdnz	nxs_loop
	
	lwz		r1, 0(r4)
	cmplw	cr2, r1, r2
	beq		cr2, step4_out
	
no_nvram:
	crclr	cr3_eq				; We have as much valid NVRAM as a slug on a rainy day...
	crset	cr4_eq				; We're using the default stuff.
	bl		nn_here
nn_here:
	mflr	r4					; Point r4, r13 to the default stuff.
	li		r13, nv_default_end - nv_default
	addi	r4, r4, nv_default - nn_here

step4_out:
	addi	r13, r13, 0x1F		; Cache-block-align r13 for step 5
	clrrwi	r13, r13, 5

	if NVRAM_IN_TEXT
	crclr	cr3_eq				; NVRAM-in-text behaves much like no-NVRAM-at-all
	endif

	if DEBUG_OUTPUT
								; Careful! vectors may not be in
;	lis		r0, 0xBABA
;	ori		r0, r0, 4
;	sc
;	lis		r0, 0xBABB
;	bne		cr3, d_s4nn
;	ori		r0, r0, 0xAA55
;d_s4nn:
;	sc
	li		r0, 0
	
	endif

;;;;;;;;;;;;;; step-5 - bum bum bummmmm

	lwz		r14, NVRAM_REAL_BASE(r4)
	crclr	cr1_eq				; We don't care about text or NVRAM yet.
	lwz		r15, NVRAM_REAL_SIZE(r4)
	cmpwi	r15, -1				; real-size is -1?
	bne		rs_spec
	lis		r15, DEFT_REAL_SIZE_HI		; If so, substitute the default value
	b		size_ok
	
rs_spec:
	bso		cr3, sc_prep_601	; 601?
	lis		r2, 0x1000			; Normal max real-size is 256M
	b		size_chk
sc_prep_601:
	lis		r2, 0x0080			; 601 max real-size is 8M
size_chk:
	cmplw	r15, r2				; If real-size is > max, 1) someone's crazy; 2) clip it to max
	ble		size_chk_2
	mr		r15, r2
	b		size_ok
size_chk_2:
	lis		r1, MIN_OF_SIZE_HI
	sub.	r1, r15, r1			; Check that we have enough OF memory in real-size.
	bge		size_ok
	lis		r15, MIN_OF_SIZE_HI	; No, someone's shorting us.
	
size_ok:
	cmpwi	r14, -1				; real-base is -1?
	bne		rb_spec
	
	if DEFT_REAL_BASE_MEM_END
	
	slwi	r1, r9, 3
	add		r1, r1, r8			; Pointer after end of memory bank list
	lwz		r2, -8(r1)			; Get the base of the last memory segment
	lwz		r1, -4(r1)			;  and the size...
	
	cmplw	r1, r15				; Do we have enough space here?
	bge		rb_unspec_ok
	mr		r15, r1				; No, trim to what's available

rb_unspec_ok:
	add		r1, r1, r2			; Get the last address
	sub		r14, r1, r15		;  and subtract real-size
		
	else
	
	lis		r14, DEFT_REAL_BASE_HI
	
	endif
	
rb_spec:
	clrrwi	r14, r14, 0xC		; Page align real-base
	clrrwi	r15, r15, 0xC		;  and real-size

	if DEBUG_OUTPUT
	
;	lis		r0, 0xBABA			; Careful! vectors may not be in
;	ori		r0, r0, 5
;	sc
	li		r0, 0
	
	endif


	mr		r30, r14
	mr		r31, r15
	bl		is_out_of_the_way	; Check that real-base, real-size are within actual RAM and not overlapping vectors.
	beq		cr7, chk_loc_good	; Goody, they are.
	
	lwz		r14, 0(r8)			; If they're not, shove real-base into the first available memory.
	lwz		r1, 4(r8)			;	This should be $00000000, to be 68k-ish.

								; Make sure we leave space for the vectors if IP = 0
	if HIGH_VECTORS = 0
	
	cmplwi	r14, 0x4000			; Does this overlap low vector space?
	bge		not_in_vectors		; No...
	
	subfic	r2, r14, 0x4000		; Yes, give space for the vectors.
	li		r14, 0x4000
	sub		r1, r1, r2
	
not_in_vectors:
	endif 
	
	cmplw	r1, r15				; We don't use move_out_of_the_way because this is the big, important
	bge		realsize_ok			;  memory region that doesn't share.

	mr		r15, r1				; Clamp real-size to the length of the first memory bank
realsize_ok:					; Unless real-size is something crazy, we should be fine.
chk_loc_good:
retry_moveabout:
	crset	cr1_eq				; We now care about others.
	mtcrf	0x20, r0			; Zero out the "what's moving" bits

	if DEBUG_OUTPUT
	
;	lis		r0, 0xBABA			; Careful! Vectors may not be in
;	ori		r0, r0, 0x35
;	sc
	li		r0, 0
	
	endif
	
	if		SECONDARY_FW
								; We'll now need to move ourselves into the beginning of OF memory.
								; Unfortunately, we may already be there. If that's the case, we'll
								;  have to move ourselves out, then back in. This could be difficult.

	crset	cr2_lt
	bl		move_us_1
move_us_1:
	mflr	r30
	li		r31, last_code - commencement		; euh-- hope this stays under 32k...
	subi	r30, r30, move_us_1 - commencement
move_us:
	mr		r18, r30			; For secondary FW, we'll move the core and friends in this step, too.
	bl		move_out_of_the_way
	cmplw	r18, r30			; Are we out of the way yet?
	beq		move_us_done		; Yes, good.
	addi	r1, r30, temp_sprg1 - commencement
	mtsprg	1, r1				; Update the temporary SPRG1
	addi	r1, r30, move_us - commencement
	mtctr	r1					; We've been moved. Repeat the process again, this time
	bctr						;  running from our new location. This should not happen more than once.
move_us_done:
	crclr	cr2_lt				; We're fixed.
	mr		r17, r31			; Remember our real size for the next movings.
	sub		r16, r14, r30		; Remember how much we should move for later, but don't move yet.
								;  NVRAM and text may be floating around there still.

								; Now move the text and NVRAM about.
	crset	cr2_eq
	mr		r30, r3
	mr		r31, r6				; If the text is being obstructionist,
	bl		move_out_of_the_way	;  move it out of the way temporarily.
	mr		r1, r3				; We were here
	mr		r3, r30
	bl		adjust_text_innards	; Update r5, r8 if they point inside text.
	crclr	cr2_eq

	if DEBUG_OUTPUT
	
;	lis		r0, 0xBABA			; Careful! Vectors may not be in.
;	ori		r0, r0, 0x65
;	sc
	li		r0, 0
	
	endif
	
	bne		cr3, no_move_nvram	; If we don't have NVRAM, don't try to move it.

	crset	cr2_gt
	mr		r30, r4				; Find a good home for the NVRAM.
	mr		r31, r13			; Do this later because it might fail and NVRAM is less essential
	bl		move_out_of_the_way
	mr		r4, r30
	crclr	cr2_gt
	
	b		move_stuff_in

no_move_nvram:					; Recompute the default NVRAM address
	if NVRAM_IN_TEXT
	bne		cr4, move_stuff_in
	endif
	addi	r4, r14, nv_default - commencement
	
move_stuff_in:
	if DEBUG_OUTPUT
	
;	lis		r0, 0xBABA			; Careful! Vectors may not be in.
;	ori		r0, r0, 0xC5
;	sc
	li		r0, 0
	
	endif

	mr		r26, r18			; We are currently here.
	mr		r30, r14			; Move ourselves to the beginning of OF space
	mr		r31, r17
	bl		msi_here
msi_here:
	mflr	r1
	add		r1, r1, r16			; Modify LR so that when we branch to gen_move,
	addi	r1, r1, msi_after - msi_here	; it returns to the newly-copied code,
	mtlr	r1					; little knowing (ha-ha!) that we've taken the return address from under it.
	b		gen_move			; Reuse to save the environment.
msi_after:
	addi	r1, r18, temp_sprg1 - commencement
	mtsprg	1, r1				; Update the temporary SPRG1

	mr		r1, r3
	mr		r26, r3				; Now move the text into OF memory after us.
	add		r3, r14, r17		; Also save our new base
	bl		adjust_text_innards	; Move r5, r8 before r1 gets clobbered.
	mr		r31, r6
	mr		r30, r3
	bl		gen_move
	
								; The NVRAM is left where it was moved.
								
	add		r16, r3, r6			; Remember where we left off in OF memory.

	b		step5_part2


adjust_text_innards:			; r1 contains old text address; r3 contains new address.

	if NVRAM_IN_TEXT
	
	sub		r2, r4, r1			; Update the NVRAM address if it was in the text.
	cmplw	r2, r6				;  (which it ought to be)
	bge		nv_nit
	add		r4, r2, r3
nv_nit:
	
	endif
	
	sub		r2, r5, r1			; Update the device tree address if it was in the text
	cmplw	r2, r6
	bge		devt_nit
	add		r5, r2, r3
devt_nit:

	sub		r2, r8, r1			; Update the mem-existing address if it was in the text
	cmplw	r2, r6				;  This is still a real address.
	bgelr
	add		r8, r2, r3
	blr

	else
	
	
				; The only things which may need moving for primary is
				;  the memory bank record in r8:r9 and NVRAM. Do those now, and we'll move r8:r9
				;  into OF memory in step 6.
	
	crset	cr2_so
	mr		r30, r8
	addi	r31, r9, 3			; Invent a fake cache-aligned size for gen_move...
	
	if STATIC_ROM_ADDR = 0
	addi	r31, r31, 4			; Make sure we don't lose the ROM address at the end
	endif
	
	clrrwi	r31, r31, 2			;  (this means there's a tiny possibility of unnecessarily
	slwi	r31, r31, 2			;   moving, but that's not a problem.)
	bl		move_out_of_the_way
	mr		r8, r30
	mr		r10, r31			; save this for step 6...
	crclr	cr2_so
	
	bne		cr3, pm_nn			; If there's NVRAM...

	crset	cr2_gt
	mr		r30, r4				;  move it (possibly)
	mr		r31, r13
	bl		move_out_of_the_way
	mr		r4, r30
	crclr	cr2_gt
pm_nn:

	b		step5_part2	
	
	endif
	
move_out_of_the_way:
								; The idea here is to try putting the region at the beginning
								;  of each memory bank and after each other region.
								; If the thing can be moved, it can be moved to one of these places.

								; Input:  r30:base, r31:length.
								; Output: r30:newbase, r31:length (preserved).

	mflr	r25
	
	bl		is_out_of_the_way	; First see if it even needs to move.
	beq		cr7, moow_out		; No, just return with it.
	
	mr		r26, r30			; Save initial base
	
								; First try moving the thing to the beginning of a memory bank.
	subi	r27, r8, 8			; Offset r8 (which should be valid, as always)
	mtctr	r9
moow_loop:
	lwzu	r30, 8(r27)
	bl		is_out_of_the_way
	beq		cr7, moow_move
	bdnz	moow_loop

	li		r30, 0x4000			; Try putting it after low vectors	
	if HIGH_VECTORS
	addis	r30, r30, 0xFFF0	; I mean, high vectors (probably not viable, but...)
	endif
	bl		is_out_of_the_way
	beq		cr7, moow_move		; That was OKÉ
	
	add		r30, r14, r15		; Try putting it after OF memory
	bl		is_out_of_the_way
	beq		cr7, moow_move		; That was OKÉ

	beq		cr2, mn_text		; Are we trying to move the text? If so, don't do this step.
	add		r30, r3, r6			; Try putting it after text
	bl		is_out_of_the_way
	beq		cr7, moow_move		; That was OKÉ
mn_text:

	bgt		cr2, mn_nv
	add		r30, r4, r13		; Try putting it after NVRAM
	bl		is_out_of_the_way
	beq		cr7, moow_move		; That was OKÉ
mn_nv:

	if SECONDARY_FW

	blt		cr2, mn_code
	add		r30, r18, r17		; Try putting it after code
	bl		is_out_of_the_way
	beq		cr7, moow_move		; That was OKÉ
mn_code:

	else
	
	bso		cr2, mn_mbr
	slwi	r30, r9, 3
	add		r30, r8, r9			; Try putting it after memory banks

	if STATIC_ROM_ADDR = 0
	addi	r31, r31, 4			;  (possibly including the ROM address at the end)
	endif

	addi	r30, r30, 0x1F		;  (aligning the ending address)
	clrrwi	r30, r30, 5
	bl		is_out_of_the_way
	beq		cr7, moow_move		; That was OKÉ
mn_mbr:	

	endif

	if DEBUG_OUTPUT
	
;	lis		r0, 0xBABA			; Careful, vectors may not be in!
;	ori		r0, r0, 0xCF
;	sc
	li		r0, 0
	
	endif
	
	mr		r30, r26			; No good, leave it there and hold on...
	lis		r15, MIN_OF_SIZE_HI	; Squeeze r15 down and retry it
								;  The new OF memory chunk is certainly valid. (r15 was >= MIN_OF_SIZE_HI)
	b		retry_moveabout

	
gen_move:						; r26: source	r30: dest	r31: length
	mflr	r25

moow_move:
	if DEBUG_OUTPUT
	
	bgt		cr4, moow_no_debug	; Skip if our vectors aren't in
	lis		r0, 0xBABA			
	ori		r0, r0, 0xFF
	sc
	lis		r0, 0xBABB
	rlwimi	r0, r26, 16, 16, 31
	sc
	lis		r0, 0xBABB
	rlwimi	r0, r30, 16, 16, 31
	sc
	lis		r0, 0xBABB
	rlwimi	r0, r31, 16, 16, 31
	sc
moow_no_debug:
	li		r0, 0
	
	endif

	sub.	r2, r26, r30
	addi	r1, r31, 0x1F
	srwi	r2, r1, 5			;  We're moving 32 bytes at a time.
	beq		moow_out			; This shouldn't happen, but...
	mtctr	r2					; We also assume that length > 0. If not, bad things will happen.
	blt		moow_move_f			; Move it backwards if dest > source. Yep, this might be necessary.

	clrrwi	r29, r1, 5
	add		r1, r26, r29		; No bias needed when moving backwards
	add		r2, r30, r29

moow_move_bl:
	lwz		r21, -4(r1)			; Move the data to its brand new location
	lwz		r22, -8(r1)			; This is probably not needed presently.
	lwz		r23, -12(r1)		; Keep it, though, in case we have recourse to it later.
	lwz		r24, -16(r1)
	stw		r21, -4(r2)
	stw		r22, -8(r2)
	stw		r23, -12(r2)
	stw		r24, -16(r2)
	lwz		r21, -20(r1)
	lwz		r22, -24(r1)
	lwz		r23, -28(r1)
	lwzu	r24, -32(r1)
	stw		r21, -20(r2)
	stw		r22, -24(r2)
	stw		r23, -28(r2)
	stwu	r24, -32(r2)
	dcbf	0, r2				; Flush it out - it may be code
	icbi	0, r2
	bdnz	moow_move_bl
	b		moow_out
	
moow_move_f:
	subi	r1, r26, 4			; Source, biased
	subi	r2, r30, 4			; Destination, biased

moow_move_l:
	lwz		r21, 4(r1)			; Move the data to its brand new location
	lwz		r22, 8(r1)
	lwz		r23, 12(r1)
	lwz		r24, 16(r1)
	stw		r21, 4(r2)
	stw		r22, 8(r2)
	stw		r23, 12(r2)
	stw		r24, 16(r2)
	icbi	0, r2				; Kill that cached stuff!
	lwz		r21, 20(r1)
	lwz		r22, 24(r1)
	lwz		r23, 28(r1)
	lwzu	r24, 32(r1)
	stw		r21, 20(r2)
	stw		r22, 24(r2)
	stw		r23, 28(r2)
	stw		r24, 32(r2)
	dcbf	0, r2				; Again, it may be code, and in any case we don't really
	addi	r2, r2, 32			;  want it sitting around stale in the cache - it could DSI later once translation's on
	bdnz	moow_move_l
								; r30 now contains this new location, and we can leave.
moow_out:
	mtlr	r25
	blr

is_out_of_the_way:				; Input: r30:r31 memory region, cr1_eq: check against text, NVRAM also?
								; Output: cr7_eq: successful, r31 preserved

	crclr	cr7_eq				; Set the success flag to false
	
	if HIGH_VECTORS
	addis	r30, r30, 0x10		; Shift & test like low vectors
	endif
	
	cmplwi	r30, 0x4000			; Is it in the low vector area?
	neg		r29, r30			; If so, it's no good.
	
	if HIGH_VECTORS
	subis	r30, r30, 0x10		; Undo change
	endif
	
	bltlr
	cmplw	r29, r31
	bltlr
		
	subi	r2, r8, 4
	mtctr	r9
	
chk_loc:
	lwz		r1, 4(r2)
	sub		r29, r30, r1		; Is the beginning of the memregion in RAM?
	lwzu	r28, 8(r2)
	cmplw	r29, r28
	ble		chk_loc_succ_1
	bdnz	chk_loc
								; This is not in RAM.
	blr

chk_loc_succ_1:
	add		r29, r30, r31		; Get the end of the memory region
	sub		r29, r29, r1
	cmplw	r29, r28			; Is the end of the memregion in RAM?
	bgtlr						; No, exit.

chk_loc_succ:
	bne		cr1, ioow_succ		; Are we done?
	
	sub		r1, r30, r14		; Overlapping OF memory?
	sub		r2, r14, r30
	cmplw	r1, r15
	cmplw	cr6, r2, r31
	cror	cr6_lt, cr0_lt, cr6_lt
	
	bltlr	cr6					; Yes, exit

	beq		cr2, no_test_text
	
	sub		r1, r30, r3			; Overlapping text?
	sub		r2, r3, r30
	cmplw	r1, r6				; If so, one (or both?) of these conditions must be true.
	cmplw	cr6, r2, r31
	cror	cr6_lt, cr0_lt, cr6_lt
	
	bltlr	cr6					; Yes, exit

no_test_text:
	bgt		cr2, no_test_nvram
	bne		cr3, no_test_nvram
	
	sub		r1, r30, r4			; Overlapping NVRAM?
	sub		r2, r4, r30
	cmplw	r1, r13
	cmplw	cr6, r2, r31
	cror	cr6_lt, cr0_lt, cr6_lt

	bltlr	cr6					; Yes, exit
	
no_test_nvram:
	if SECONDARY_FW
								; Only pertinent to secondary FW

	blt		cr2, no_test_code
	
	sub		r1, r30, r18		; Overlapping code?
	sub		r2, r18, r30
	cmplw	r1, r17
	cmplw	cr6, r2, r31
	cror	cr6_lt, cr0_lt, cr6_lt

	bltlr	cr6					; Yes, exit

no_test_code:

	else
	
	bso		cr2, no_test_mbr	; Only pertinent to primary
	
	sub		r1, r30, r8			; Overlapping memory bank array?
	sub		r2, r8, r30
	srwi	r1, r1, 3			;  (all inputs are word aligned)
	cmplw	r1, r9
	cmplw	cr6, r2, r31
	cror	cr6_lt, cr0_lt, cr6_lt

	bltlr	cr6					; Yes, exit

no_test_mbr:	

	endif

ioow_succ:
	crset	cr7_eq				; This region is fine.
	blr

step5_part2:					; Ouch, that was painful.
	add		r1, r14, r15		; Before we leave,
	subi	r1, r1, 4			;  do a stwcx. on the last word of memory
	stwcx.	r0, 0, r1			;  to clear out reservations.
								; This is our first chance to do this.
	
	if SECONDARY_FW && COPY_VECTORS	
	bgtl	cr4, my_vectors_in	; Also, if we deferred installing the vectors because something was in
								;  their way, do that now as well.
	crclr	cr4_gt
	endif

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0xF5
	sc
	li		r0, 0
	
	endif

;;;;;;;;;;;;; step-6

	if SECONDARY_FW
	
	addi	r16, r16, 0x1F
	clrrwi	r16, r16, 5			; Cache block-align r16 (though it should already be there)
	
	else
	
	bl		s6_here
s6_here:
	mflr	r26
	mr		r30, r14					; Move core to the beginning of OF memory.
	li		r31, core_end - core_begin	 ; under 32K?
	addi	r26, r26, core_begin - s6_here
	bl		gen_move
	add		r16, r14, r31

	mr		r26, r8
	mr		r30, r16
	mr		r31, r10					; 32-byte-aligned version of r9<<2 we calculated in step 5.
	bl		gen_move
	mr		r8, r16						; Remember the new address
	add		r16, r16, r31				; Add this region in...

										; If the text is not in RAM and we are set for LE,
										;  it should be copied in here now, so we can swap it in step A
	endif
	
	; At this point, r16 contains the next available physical address in OF memory.
	; The whole memory space is at r14 with length r15.

;;;;;;;;;;;;; step-7

	; It's mapping time! Give BAT0/BAT1 to OF memory, BAT2/BAT3 to NVRAM. Later the page table will get BAT3.
	
	; First we figure out how to map BATs 0 and 1
	; If OF memory fits perfectly in a BAT already (likely), just give it BAT0
	; Otherwise, find the biggest boundary that OF memory crosses; put the left half in BAT0
	;  and the right half in BAT1. We can't improve on that, I think.
	;
	; Unfortunately, virt-base may be something horribly bad (specifically, such that it cannot be
	;  BAT-mapped) Let's ignore that. Also, virt-size might be something
	;  other than real-size. That sounds pretty silly; I'm not sure why it's there at all. We'll
	;  conveniently ignore that, too.
	

	lhz		r2, NVRAM_BITS(r4)	; Get real-mode?
	andi.	r2, r2, NVRAM_RM_MASK
	lwz		r17, NVRAM_VIRT_BASE(r4)		; Get virt-base
	crnot	cr3_gt, cr0_eq		; Save real-mode? in CR3[GT] with other useful bits...
	beq		virt_mode
	mr		r17, r14			; If in real-mode, set virt-base to real-base
	b		vr_sw_done
virt_mode:
	cmpwi	r17, -1				; If virt-base is -1, use the default.
	bne		vr_sw_done
	lis		r17, DEFT_VIRT_BASE_HI
vr_sw_done:
	clrrwi	r17, r17, 0xC		; Page-align it

	andis.	r1, r15, 0xFFFE		; Make sure real-size >= 128k (we wouldn't survive anyway, but...)
	mr		r21, r15			; If it isn't, pretend it's 128k for the purposes of mapping
	bne		rs_over_128k		;  and set it back later.
	lis		r15, 2
rs_over_128k:
	
	subi	r31, r15, 1
	and.	r1, r31, r15		; Is real-size a power of 2?
	bne		two_bats			; No, double-BAT it.
	
	and.	r1, r14, r31		; Is real-base aligned to real-size?
	bne		two_bats			; No, double-BAT it.
	
	andc	r17, r17, r31		; Align virt-base and remember it. Will do nothing if in real-mode

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x06
	sc
	lis		r0, 0xBABB
	rlwimi	r0, r17, 16, 16, 31
	sc
	li		r0, 0
	
	endif

	mr		r18, r14
	mr		r19, r17
	li		r27, 0
	mr		r28, r31
	bl		bat_set
	
	add		r30, r17, r15		; The end of virtual OF memory, where'll we map the NVRAM later.
	b		step7_part2

two_bats:	
	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x26
	sc
	lis		r0, 0xBABB
	rlwimi	r0, r17, 16, 16, 31
	sc
	li		r0, 0
	
	endif

	add		r1, r14, r31		; Get the last address in OF memory
	xor		r2, r1, r14			; XOR it with the first...
	cntlzw	r2, r2				; This is the highest boundary that the range crosses.
	
	lis		r31, 0x8000			; Load this multiply-used constant

	srw		r2, r31, r2			; Get the size mask...
	neg		r2, r2
	and		r29, r1, r2			; r29 is the address at which we split the range
	sub		r22, r29, r14
	sub		r1, r1, r29			; r1 is the formal length of the second part minus one
	subi	r30, r22, 1			; r30 is the formal length of the first part minus one

	cntlzw	r2, r30				; Round up to nearest power of two, min. 128k
	subi	r2, r2, 1
	cmplwi	r2, 14
	ble		tb1_size_ok
	li		r2, 14
tb1_size_ok:
	srw		r2, r31, r2
	sub		r18, r29, r2		; Base address for BAT0 in r18
	subi	r28, r2, 1			; Mask for BAT0 in r28
	
	cntlzw	r23, r1				; We'll round up part 1 now, too.
	subi	r23, r23, 1			; We need it to determine the boundary to which
	cmplwi	r23, 14				;  we must align virt-base.
	ble		tb2_size_ok
	li		r23, 14
tb2_size_ok:
	srw		r23, r31, r23
	subi	r20, r23, 1

	or		r24, r20, r28		; Get the largest mask needed for alignment...
	add		r30, r22, r17		; Find where r29 corresponds in virt-base
	andc	r30, r30, r24		; and align it here. This will be the starting virt for BAT1
	sub		r17, r30, r22		; virt-base is now ready to go

	sub		r19, r30, r2		; BAT0's starting virt
	li		r27, 0				; Set BAT0
	bl		bat_set
	
								; Now for part 1...
								; Base address for BAT1 is in r29
	mr		r28, r20			; Mask for BAT1 is in r20

	li		r27, 1				; Set BAT1
	mr		r18, r29
	mr		r19, r30
	add		r30, r30, r23		; Save end of virtual OF memory for later...
	
	bl		bat_set	

step7_part2:
								; Part 2 -- the saga continues...
	bne		cr3, s72_nnv		; ...or doesn't. If NVRAM in ppc-boot (default stuff) or text, it
								;  is already mapped.

								; NVRAM could be anywhere... maybe even crossing a segment (shudder)
								; So we may need two BATs for it, too. These will always be 128k.
								; Here, we will try to map the least amount of memory possible.
								; We assume, by the way, that nvram-size <= 128k.
								
	add		r1, r4, r13			; Where's the end?
	subi	r12, r1, 1
	xor		r12, r12, r4		; Does it cross...
	andis.	r12, r12, 0x2		; (r12 will survive bat_set)
	
	lis		r1, 2				; Form the 128k mask
	subi	r1, r1, 1			; (this is where we need maskg)
	
	andc	r18, r4, r1
	mr		r19, r30			; This is where we're mapping it. It's guaranteed to be aligned already,
	li		r27, 2				;  and won't overlap any other mappings while it's around.
	mr		r28, r1
	bl		bat_set				; Map it with BAT2

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABB
	ori		r0, r0, 0xC4C4
	sc
	li		r0, 0
	
	endif	

	cmplwi	r12, 0				; unnecessary? (cr0 should survive bat_set?)
	
	and		r12, r4, r28		; Compute the new virtual address
	add		r12, r12, r19
	
	beq		step7_out			; ...the 128K-ZONE? Hopefully not, in which case we're done.
	
	addis	r18, r18, 2
	addis	r19, r19, 2
	li		r27, 3
	bl		bat_set				; Map the second half with BAT3
		
	b		step7_out

s72_nnv:
	sub		r12, r4, r14		; The default NVRAM is inside of OF memory.
	add		r12, r12, r17		; Get its virtual address.
	b		step7_out

; ********
;	For primary, we need to map ourselves, the text, compressed device tree, etc., where they are as well.
;	We could insist in this case that NVRAM (which can be put wherever) be entirely in one BAT,
;    so that these memory regions could get BAT3.
; ********

bat_set:

	; BAT-map (WiMg) some memory: r18 phys, r19 virt, r27 BAT#, r28 mask
	
	mtcrf	0x01, r27			; Get that BAT#
	bso		cr3, bat_set_601	; If we're on a 601, life is harder..

	andc	r2, r18, r28		; Form lower BAT
	
	if WRITE_BACK
	ori		r2, r2, 0x12		; wiMg0Pp
	else
	ori		r2, r2, 0x52		; WiMg0Pp
	endif
	
	andc	r1, r19, r28
	rlwimi	r1, r28, 0x11, 19, 29		; Form upper BAT
	ori		r1, r1, 3			; VsVp
		
	beq		cr7, bds_2
	bso		cr7, bds_1
	isync
	mtspr	dbat0l, r2
	isync
	mtspr	dbat0u, r1
	isync
	b		bds_done
bds_1:
	isync
	mtspr	dbat1l, r2
	isync
	mtspr	dbat1u, r1
	isync
	b		bds_done
bds_2:
	bso		cr7, bds_3
	isync
	mtspr	dbat2l, r2
	isync
	mtspr	dbat2u, r1
	isync
	b		bds_done
bds_3:
	isync
	mtspr	dbat3l, r2
	isync
	mtspr	dbat3u, r1
	isync
	
bds_done:
	rlwinm	r2, r2, 0, 0xFFFFFFBF		; IBATs must have W, G cleared...
	b		bat_set_2			; Do the IBATs
	
bat_set_601:
	andc	r1, r19, r28

	if WRITE_BACK
	ori		r1, r1, 0x02		;                  wimsuPp
	else
	ori		r1, r1, 0x42		; Form upper BAT - WimsuPp
	endif
	
	andc	r2, r18, r28		; Form lower BAT
	rlwinm	r2, r28, 15, 26, 31	; Insert BSM
	ori		r2, r2, 0x40		; Valid

bat_set_2:
	beq		cr7, bts_2
	bso		cr7, bts_1
	isync						; Might be required for 601?
	mtspr	ibat0l, r2
	isync
	mtspr	ibat0u, r1			; These are all the BATs the 601's got.
	isync
	blr
bts_1:
	isync
	mtspr	ibat1l, r2
	isync
	mtspr	ibat1u, r1
	isync
	blr
bts_2:
	bso		cr7, bts_3
	isync
	mtspr	ibat2l, r2
	isync
	mtspr	ibat2u, r1
	isync
	blr
bts_3:
	isync
	mtspr	ibat3l, r2
	isync
	mtspr	ibat3u, r1
	isync
	blr
	
step7_out:
	isync						; Make sure all the BATs get through.
	mr		r15, r21			; Restore real_size if we changed it.
	
	; We now have a virt_base in r17, and a virt_nvram in r12.
	; We also have end of virtual OF memory in r30, and the next available
	;  real address in OF memory in r16.

;;;;;;;;;;;;; step-8

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x88
	sc

	li		r0, 0

	endif
	
	; We now begin to set up Forth...
	
	addi	r16, r16, 0x1F
	clrrwi	r16, r16, 5			; Cache-block-align r16

	; We will first zero out everything from r16 the end of OF memory.

	add		r10, r14, r15
	sub		r10, r10, r16
	srwi	r10, r10, 5			; Guaranteed to be aligned
	mtctr	r10

	mr		r10, r16	
	li		r0, 0				;  (unnecessary?)
mem_clear_l:
	stw		r0, 0(r10)			; If we were sure that this memory were cached,
	stw		r0, 4(r10)			;  we could just use dcbz. But apparently not
	stw		r0, 8(r10)			;  all processors allow caching when DR = 0.
	stw		r0, 12(r10)
	stw		r0, 16(r10)
	stw		r0, 20(r10)
	stw		r0, 24(r10)
	stw		r0, 28(r10)
	dcbf	0, r10				; Make sure the stores are stored
	addi	r10, r10, 32
	
	bdnz	mem_clear_l

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x48
	sc
	
	li		r0, 0
	
	endif
	
	; Now carve up the memory...
	
	mr		r19, r16			; initvec@
	mr		r1, r16				; ... in real memory, which we want now
	bl		rv_addr
	mr		r22, r19			; ... in virtual memory, which we want later?

	addi	r16, r19, INITVEC_LEN + 0xFFF
	clrrwi	r16, r16, 12		; Now page-align and set apart some memory segs.

	mr		r2, r16				; Low-level areas for the handlers (save for step 9)
	addi	r16, r16, TSTORE_LEN + SAVEAREA_LEN

	mr		r23, r16			; Bootstrap dictionary (catalog) space
	addi	r16, r16, BDICT_LEN
	stw		r23, IV_BD_BASE(r1)
	mr		r24, r23			; bd-ptr (changed in step B)
	
	mr		r21, r16			; Bootstrap data space -> comp-code-ptr
	addi	r16, r16, BDATA_LEN

	addi	r31, r16, STACK_LEN - STACK_BUF
	addi	r16, r16, STACK_LEN	; Data stack
	stw		r31, IV_STACK_BASE(r1)
	addi	r31, r31, 4			; Pre-offset
	
	addi	r30, r16, RSTACK_LEN - STACK_BUF
	addi	r16, r16, RSTACK_LEN	; Return stack
	stw		r30, IV_RSTACK_BASE(r1)
	
	stw		r16, IV_DATA_BASE(r1)	; Main data
	
	mr		r19, r3				; Text
	bl		rv_addr
	stw		r19, IV_FTEXT_BASE(r1)		; ftext-base
	mr		r25, r19			; ftext-base
	mr		r26, r19			; ftext-ptr
	
; We don't set am-base here. Step 9 does this.

; Let's store off all these registers we've been saving for the last 1000 instructions...

	stw		r14, IV_REAL_BASE(r1)
	stw		r15, IV_REAL_SIZE(r1)
	stw		r17, IV_VIRT_BASE(r1)
	stw		r15, IV_VIRT_SIZE(r1)
	mr		r19, r8
	bl		rv_addr
	stw		r19, IV_EXISTING(r1)
	stw		r9, IV_NEXISTING(r1)
	stw		r12, IV_NVRAM(r1)
	stw		r13, IV_NVRAM_SIZE(r1)
	mr		r19, r5
	bl		rv_addr
	stw		r19, IV_DEVTREE(r1)
	stw		r7, IV_DT_LEN(r1)
	stw		r2, IV_TSTORE(r1)
	addi	r0, r2, TSTORE_LEN
	stw		r0, IV_INTERNALS(r1)
	
	lis		r29, 0xBEEF			; TOS, _1, _2
	li		r27, 0				;  (security, you know)
	ori		r29, r29, 0xCAFE
	li		r28, 0
								; Put the bootstrap interpreter's temporary stack deep in the data stack
	subi	r18, r31, (STACK_LEN / 2)

	b		step8_out

rv_addr:
	sub		r0, r19, r14		; Is the parameter (r19) in real OF mem?
	cmplw	r0, r15
	bgelr
	add		r19, r0, r17		; If so, move it to virtual OF mem.
	blr
	
step8_out:

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x08
	sc
		
	li		r0, 0
	
	endif

;;;;;;;;;;;;; step-9

	; r1 contains the initvec@ address in real memory.
	; r2 contains the _virtual_ memory region we'll use. We don't need this now.
	; r16 is now virtual
	
	;  SPRG0: translation count - 1
	;  SPRG1: register store - Forth state ("internals")
	;  SPRG2: compressed translations
	;  SPRG3: scratch

	addi	r10, r1, INITVEC_LEN + 0xFFF		; Get the real address for r2.
	clrrwi	r10, r10, 12

	li		r0, -1
	mtsprg	0, r0				; No translations, yet.
	mtsprg	2, r10				; Translation store area
	
	li		r0, 0
	addi	r10, r10, TSTORE_LEN
	stw		r0, INT_FORTH_UP(r10)	; Forth is not up; don't try to send it stuff.

	lwz		r0, IV_STACK_BASE(r1)	; Copy over the stack information
	stw		r0, INT_STK_BASE(r10)	;  for forth_quit
	lwz		r0, IV_RSTACK_BASE(r1)
	stw		r0, INT_RSTK_BASE(r10)

	lhz		r0, NVRAM_BITS(r4)		; Get NVRAM bits
	mtcrf	0x01, r0				;  and store them in cr7 -- cr7_eq is LE, cr7_so is real-mode?

	rlwinm	r0, r0, 3, 0x8
	bne		cr7, s9_vb_be
	ori		r0, r0, 0x1
s9_vb_be:
	
	stw		r0, INT_VEC_BITS(r10)
	
	mfspr	r0, ibat0u
	stw		r0, INT_OF_IBATS + 0x00(r10)
	mfspr	r0, ibat0l
	stw		r0, INT_OF_IBATS + 0x04(r10)
	mfspr	r0, ibat1u
	stw		r0, INT_OF_IBATS + 0x08(r10)
	mfspr	r0, ibat1l
	stw		r0, INT_OF_IBATS + 0x0C(r10)
	mfspr	r0, ibat2u
	stw		r0, INT_OF_IBATS + 0x10(r10)
	mfspr	r0, ibat2l
	stw		r0, INT_OF_IBATS + 0x14(r10)
	mfspr	r0, ibat3u
	stw		r0, INT_OF_IBATS + 0x18(r10)
	mfspr	r0, ibat3l
	stw		r0, INT_OF_IBATS + 0x1C(r10)

	bso		cr3, save_of_bats_601

	mfspr	r0, dbat0u
	stw		r0, INT_OF_DBATS + 0x00(r10)
	mfspr	r0, dbat0l
	stw		r0, INT_OF_DBATS + 0x04(r10)
	mfspr	r0, dbat1u
	stw		r0, INT_OF_DBATS + 0x08(r10)
	mfspr	r0, dbat1l
	stw		r0, INT_OF_DBATS + 0x0C(r10)
	mfspr	r0, dbat2u
	stw		r0, INT_OF_DBATS + 0x10(r10)
	mfspr	r0, dbat2l
	stw		r0, INT_OF_DBATS + 0x14(r10)
	mfspr	r0, dbat3u
	stw		r0, INT_OF_DBATS + 0x18(r10)
	mfspr	r0, dbat3l
	stw		r0, INT_OF_DBATS + 0x1C(r10)

save_of_bats_601:


	if DEBUG_OUTPUT
	mfsprg	r11, 1
	lwz		r0, INT_V_BASE(r11)		; Copy from old SPRG1
	stw		r0, INT_V_BASE(r10)
	lwz		r0, INT_V_LINE(r11)
	stw		r0, INT_V_LINE(r10)
	lwz		r0, INT_V_WIDTH(r11)
	stw		r0, INT_V_WIDTH(r10)
	lwz		r0, INT_V_H(r11)
	stw		r0, INT_V_H(r10)
	endif
	
	mtsprg	1, r10				; Save area
	
	; Now we need to set up the page table...

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x09
	sc
	li		r0, 0
	
	endif
	
	blt		cr4, have_swt		; ... except if we have software table lookup. 
	
	; We'll need to offset end of mem backward by the page table len and align it.
	; There may not be enough memory for the page table, in which case shrink it to 64k,
	;  and watch it quickly fill up!
	
	li		r11, PT_SIZE		; Get default page table size.

pt_retry:
	lis		r2, 1
	slw		r2, r2, r11			; Get pt length
	
	add		r10, r17, r15		; Virtual address
	subi	r0, r2, 1
	sub		r10, r10, r2
	andc	r10, r10, r0		; Offset and align...
	
	cmplw	r10, r16			; Compare against data-base
	bgt		pt_ok				; Practically, we need some amount of memory, but
								; this should be dealt with via MIN_OF_SIZE_HI.

	li		r11, 0				; Try 64k.
	b		pt_retry			; If this doesn't work, we'll just hang. We could never boot anyway.
	
pt_ok:
	; Remember what we did in the initvec.
	
	stw		r11, IV_PT_SIZE(r1)

	mr		r11, r10
	
	stw		r11, IV_AM_BASE(r1)	; alloc-mem memory begins just below the page table.
	stw		r11, IV_PT(r1)

	; Set SDR1 as appropriate.

	sub		r10, r10, r17		; Get the real address for r10 (yum!)
	add		r10, r10, r14
	rlwimi	r10, r0, 0x10, 23, 31	; Form SDR1 (r0 already contains mask)
	sync						; This appears to be necessary.
	mtsdr1	r10
	isync						; Just for good measure.

	mfsprg	r11, 1				; Remember what we set (NEW)
	stw		r10, INT_MY_SDR1(r11)

	; The new page table has already been wiped.
	
	; Set segment registers.
	
	li		r11, 0x10
	mtctr	r11

	lis		r2, 0x2012			; T = 0, Ks = 0, Kp = 1, N = 0
	ori		r2, r2, 0x7500		; Segment register x is $201275xx.

	li		r10, 0
	
sg_set_l:
	mtsrin	r2, r10
	addis	r10, r10, 0x1000	; mtsrin looks at the high 4 bits of rB
	addi	r2, r2, 0x11
	bdnz	sg_set_l
	
	isync						; Synchronize 'em

	b		step9_out


have_swt:						; This case is much easier.
	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0xC9
	sc
	li		r0, 0
	
	endif

	add		r0, r17, r15		; must be virtual...
	stw		r0, IV_AM_BASE(r1)	; Set am-base to end of OF memory.
	
	li		r2, -1				; Also set pt-base, pt-size to -1
	stw		r2, IV_PT(r1)
	stw		r2, IV_PT_SIZE(r1)
	
	lis		r2, 0xABCD			; Initialize SDR1 to a bogus value that is NOT the vector area
	sync
	mtsdr1	r2

	stw		r2, INT_MY_SDR1(r10)	; Remember the bogusness
								; SRs were previously cleared, so we're done.
	
step9_out:
	; r1 remains unmodified.

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0xF9
	sc
	li		r0, 0
	
	endif

;;;;;;;;;;;; step-A

	; If we want little-endian, we need to do some work.
	; 
	; If we reset-some'd here, reset-some is responsible to have
	;  reset physmem existing, text, etc. to BE if it was LE.
	; However, we need to word-swap the core; it can't easily do that; we can.
	
	; What needs swapping:
	;  initvec@				word
	;  phys available		byte - OF expects 'big-endian' property ordering - this is the net result
	;  text					byte
	;  core					word
	;  vectors				word
	;  vector structs		variable
	
	; What is not swapped:
	;  bootstrap catalog	variable - step B does this
	;  device tree			variable
	;  NVRAM				variable
	;  ppc-boot (us)		word
	;  translations			word - are currently null, but if not need to be swapped
	;  anything else
	

								; little-endian? is in cr7_eq
	beq		cr7, le_man			; Twiddle some bits if LE
	
	if SECONDARY_FW
	blt		cr3, le_rs			; If reset-some'ing from LE to BE, swap core.
	endif
	
	b		stepA_part2			; Otherwise, nothing's necessary.

le_man:
	li		r2, INITVEC_LEN		; Word-reverse the initialization vector.
	bl		le_rev_words		; Its real address is already in r1.

	if SECONDARY_FW
	sub		r1, r8, r14			; For secondary FW only, the physical memory available list
	cmplw	r1, r15				;  should be inside the text, and should not be reversed again.
	blt		le_pmr_done
	endif
	
	mr		r1, r8				; Byte-reverse the physical memory available list
	slwi	r2, r9, 3
	bl		le_rev_bytes
le_pmr_done:

	lva		r1					; Word-reverse the vectors: WARNING! incompatible with having vectors in ROM!
	li		r2, 0x4000			;  (lva is a macro, see ppc-boot.i)
	bl		le_rev_words

	lva		r1					; ...and flush them out
	li		r2, 0x4000
	bl		make_exec

	mfsprg	r1, 1				; Word-reverse the savearea/internals
	li		r2, SAVEAREA_LEN
	bl		le_rev_words

	mfmsr	r1					; Now that vectors are reversed, turn on ILE (for debug output, if nothing else)
	oris	r1, r1, 1			; ILE
	mtmsr	r1
	
	mr		r1, r3				; Byte-reverse the text.
	mr		r2, r6
	bl		le_rev_bytes

le_rs:							; xxx We shouldn't word-reverse the core if reset-some'ing from LE to LE?

	bl		le_rs_here
le_rs_here:
	mflr	r1					; Word-reverse the core.
	addi	r1, r1, core_begin - le_rs_here

	li		r2, core_end - core_begin
	addi	r2, r2, 0x1F
	clrrwi	r2, r2, 5

	mr		r16, r1				; Save 'em....
	mr		r20, r2	
	
	bl		le_rev_words

	mr		r1, r16
	mr		r2, r20
	
	bl		make_exec			; Flush out the core...
	
	b		stepA_part2			; Go on to part 2.

le_rev_bytes:	
	; Byte-swap some memory.
	;  r1: base r2: len. Neither are preserved. Both had better be doubleword-aligned, and length nonzero

	srwi	r0, r2, 3
	subi	r1, r1, 4
	mtctr	r0
	li		r2, 4			; Indices for lwbrx
	li		r0, 8
lrb_loop:
	lwbrx	r10, r1, r2		; Byte-reverse the doublewords.
	lwbrx	r11, r1, r0
	stw		r11, 4(r1)		; Happify the munger!
	stwu	r10, 8(r1)
	bdnz	lrb_loop
	
	blr

le_rev_words:
	; Word-swap some memory.
	;  r1: base r2: len. Neither are preserved. Both had better be doubleword-aligned.

	srwi	r0, r2, 3
	subi	r1, r1, 4
	mtctr	r0
lrw_loop:
	lwz		r10, 4(r1)		; Word-reverse the doublewords
	lwz		r11, 8(r1)
	stw		r11, 4(r1)
	stwu	r10, 8(r1)
	bdnz	lrw_loop

	blr

make_exec:
	; ICBI out a range of memory. The impending data_push will DCBF it handily.
	;  r1: base  r2: len
	
	add		r2, r1, r2
	addi	r0, r2, 0x1F
	clrrwi	r0, r0, 5		; This is just beyond the cache blocks we need to flush.
	clrrwi	r1, r1, 5		; This is the first cache block to flush
	sub		r0, r0, r1
	srwi	r0, r0, 5
	mtctr	r0
mex_l:
	icbi	0, r1
	addi	r1, r1, 0x20
	bdnz	mex_l
	
	blr


stepA_part2:	
	crmove	cr3_lt, cr7_eq		; Save little-endian? for later, with friends.

	bge		cr3, sa2_nl
							; If we are going to LE,
	lis		r1, 1			; flush 2M of junk through the caches
	bl		data_push		;  to sweep away all hints of big-endianness before translation's on,
							;  except these few cache blocks of code.
							; But they won't cause trouble.
							; We will need to flush out all data loaded and stored from here on.

	if FLUSH_DCBI
	lis		r1, 1			; If configured, dcbi out the flush data too.
	bl		flushdata_dcbi
	endif

sa2_nl:
	mfmsr	r1
	ori		r1, r1, 0x30		; Turn on translation!
	
	bl		sa_here
sa_here:
	mflr	r19
	bl		rv_addr
	addi	r2, r19, stepA_out - sa_here
	
	mtsrr0	r2
	mtsrr1	r1
	rfi							; Jump nowhere with an MMU
	
	nop
	
stepA_out:

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0xCA
	sc
	li		r0, 0
	
	endif

;;;;;;;;;;;; step-B

	; The bootstrap catalog is almost ready to go.
	; All that is necessary is to convert offsets to code addresses in the bd>code field.
	; And if we are LE, some swapping is in order.
	
	addi	r1, r19, __bcat_start - sa_here	; Offset to add to bd>code fields

	subi	r2, r1, 4			; Source
	subi	r24, r24, 4			; Destination
	
	li		r0, (__bcat_end - __bcat_start) / BCAT_NSIZE
	mtctr	r0

	blt		cr3, bccl_m			; LE?
	
bcc_l:
	lwz		r10, 4(r2)
	lwz		r11, 8(r2)
	stw		r10, 4(r24)
	add		r11, r11, r1
	stw		r11, 8(r24)
	lwz		r10, 12(r2)
	lwz		r11, 16(r2)
	stw		r10, 12(r24)
	stw		r11, 16(r24)
	lwz		r10, 20(r2)
	lwzu	r11, 24(r2)
	stw		r10, 20(r24)
	stwu	r11, 24(r24)
	bdnz	bcc_l

	b		stepB_part2

bccl_m:

	; We will word-swap word2 and byte-swap the rest.
	; Let's load up some indices for lwbrx.
	
	li		r3, 4
	li		r4, 12
	li		r5, 16
	li		r6, 20
	li		r7, 24
	
bccl_l:
	lwbrx	r10, r2, r3
	lwz		r11, 8(r2)
	stw		r10, 8(r24)
	add		r11, r11, r1
	stw		r11, 4(r24)
	lwbrx	r10, r2, r4
	lwbrx	r11, r2, r5
	stw		r10, 16(r24)
	stw		r11, 12(r24)
	lwbrx	r10, r2, r6
	lwbrx	r11, r2, r7
	stw		r11, 20(r24)
	addi	r2, r2, BCAT_NSIZE
	stwu	r10, 24(r24)
	bdnz	bccl_l
	
stepB_part2:

	if DEBUG_OUTPUT
	
	lis		r0, 0xBABA
	ori		r0, r0, 0x0B
	sc
	li		r0, 0
	
	endif

	li		r0, 0
	addi	r24, r24, 4		; r24 is now in the right place for the bootstrap interpreter.
	stb		r0, 0(r24)
	
	; Hmmm...
	;   looks like we're about ready.
	;
	; If we're LE and not 601, rfi into Forth, otherwise just branch.
	;  For primary, the core is at r17 (beginning of virtual OF memory)
	; Translation is on; we're running in virtual address space.

	sync
	isync
	
	if SECONDARY_FW
	
	bge		cr3, core_entry	; BE? Jump in...				
	
	else
	
	addi	r1, r17, core_entry - core_begin
	mtctr	r1
	bctr
	
	endif
	
	mr		r1, r23			; Get the bootstrap catalog memory
	sub		r2, r24, r23
	bl		make_exec		; and flush
	
	bso		cr3, le_601		; 601 does LE differently, ugh.

	mfmsr	r1
	ori		r1, r1, 1		; LE - ILE is already on.
	mtsrr1	r1				; Apparently, the processor might modify SRR0 and SRR1
							;  on all instructions if IR is on, etc. If so, we might have
							;  to do a preliminary exception to real mode, then back.
							; If this ever needs to happen, we can test for it easily--
							;  load something into SRR0/1 and see if it stays.
	
	if SECONDARY_FW
	addi	r2, r19, core_entry - sa_here	; Get the address
	else
	addi	r2, r17, core_entry - core_begin
	endif
	
	mtsrr0	r2
	
	rfi						; Go on in.
	
le_601:
	mfspr	r1, hid0
	ori		r1, r1, 8		; 601's LE bit is in hid0, and determines the
							;  processor's endianness in both normal code and interrupts.
	sync
	sync
	sync
	mtspr	hid0, r1
	sync
	sync
	sync
	sync					; This is the way it's done.
	b		core_entry
	b		core_entry		; One of these must be hit.

fin_de_la_commencement:

;;;;;;;;;;;;;;;; end of ppc-boot ;;;;;;;;;;;;;;;


PPC_BOOT_PRESENT	set 1

	align	5
	include 'ppc-default-nvram.S'

	align	5
	include 'ppc-vectors.S'
	
	align	5
	include 'ppc-core-flat.S'

	align	5
last_code:

	if (last_code - commencement >= 0x8000)
***Error*** ppc-boot is too long!
	endif
	
; DumpXCOFF :TOF:object:ppc-boot.S.o -a -do t


; PPCAsm :TOF:ppc-boot.S -o :TOF:object:ppc-boot.S.o
