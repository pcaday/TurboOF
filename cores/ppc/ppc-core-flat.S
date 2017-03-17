; r1	stackptr for bootstrap interpreter
; r18	stackptr on input
; r20	interp-code-ptr
; r21	comp-code-ptr
; r22	init-vector
; r23	bd-base
; r24	bd-ptr
; r25	ftext-base
; r26	ftext-ptr
; r27	_1
; r28	_2
; r29	TOS
; r30	rsp
; r31	dsp


__DEBUG_OUT set 1
__MAPIO	set 1

	include	'ppc-core-flat.i'

	BCAT_START

; Base set
	BCAT_ENTRY	colon, ':', 1, 1
	BCAT_ENTRY	immediate, 'immediate', 9, 1
	BCAT_ENTRY	semi, 0x3B, 1, 1
	BCAT_ENTRY	in, 'in', 2, 0
	BCAT_ENTRY	_n, '_n', 2, 0
	BCAT_ENTRY	to_n, '>_n', 3, 0
	BCAT_ENTRY	_add, '+', 1, 0
	BCAT_ENTRY	_sub, '-', 1, 0
	BCAT_ENTRY	_mul, '*', 1, 0
	BCAT_ENTRY	_div, '/', 1, 0
	BCAT_ENTRY	tor, '>r', 2, 0
	BCAT_ENTRY	fromr, 'r>', 2, 0
	BCAT_ENTRY	rfetch, 'r@', 2, 0
	BCAT_ENTRY	rpick, 'rpick', 5, 0
	BCAT_ENTRY	cstore, 'c!', 2, 0
	BCAT_ENTRY	cfetch, 'c@', 2, 0
	BCAT_ENTRY	wstore, 'w!', 2, 0
	BCAT_ENTRY	wfetch, 'w@', 2, 0
	BCAT_ENTRY	store, '!', 1, 0
	BCAT_ENTRY	fetch, '@', 1, 0
	BCAT_ENTRY	_1store, '_1!', 3, 0
	BCAT_ENTRY	_1fetch, '_1@', 3, 0
	BCAT_ENTRY	_2store, '_2!', 3, 0
	BCAT_ENTRY	_2fetch, '_2@', 3, 0
	BCAT_ENTRY	lessthan, '<', 1, 0
	BCAT_ENTRY	ulessthan, 'u<', 2, 0
	BCAT_ENTRY	equals, 0x3D, 1, 0
	BCAT_ENTRY	lshift, '<<', 2, 0
	BCAT_ENTRY	rshift, '>>', 2, 0
	BCAT_ENTRY	rshifta, '>>a', 3, 0
	BCAT_ENTRY	rrot, '>>r', 3, 0
	BCAT_ENTRY	_and, 'and', 3, 0
	BCAT_ENTRY	_or, 'or', 2, 0
	BCAT_ENTRY	_xor, 'xor', 3, 0
	BCAT_ENTRY	slashmod, '/mod', 4, 0
	BCAT_ENTRY	uslashmod, 'u/mod', 5, 0
	BCAT_ENTRY	umslashmod, 'um/mod', 6, 0
	BCAT_ENTRY	umstar, 'um*', 3, 0
	BCAT_ENTRY	mstar, 'm*', 2, 0
	BCAT_ENTRY	execute, 'execute', 7, 0
	BCAT_ENTRY	dspstore, 'dsp!', 4, 0
	BCAT_ENTRY	dspfetch, 'dsp@', 4, 0
	BCAT_ENTRY	rspstore, 'rsp!', 4, 0
	BCAT_ENTRY	rspfetch, 'rsp@', 4, 0
	BCAT_ENTRY	move, 'move', 4, 0
	BCAT_ENTRY	fill, 'fill', 4, 0
	BCAT_ENTRY	comp, 'comp', 4, 0
	BCAT_ENTRY	flush, 'flush', 5, 0
	BCAT_ENTRY	bracketcore, '<core>', 6, 0

; Compilation
	BCAT_ENTRY	pparen_literal, '((literal))', 11, 0
	BCAT_ENTRY	paren_compile, '(compile)', 9, 0
	BCAT_ENTRY	paren_prologue, '(prologue)', 10, 0
	BCAT_ENTRY	paren_epilogue, '(epilogue)', 10, 0
	BCAT_ENTRY	paren_branch, '(branch)', 8, 0
	BCAT_ENTRY	paren_f_branch, '(f-branch)', 10, 0
	BCAT_ENTRY	paren_t_branch, '(t-branch)', 10, 0
	BCAT_ENTRY	paren_return, '(return)', 8, 0
	BCAT_ENTRY	paren_resolve, '(>resolve)', 10, 0
	BCAT_ENTRY	slash_code, '/code', 5, 0
	BCAT_ENTRY	slash_prologue, '/prologue', 9, 0
	BCAT_ENTRY	slash_epilogue, '/epilogue', 9, 0
	BCAT_ENTRY	slash_literal, '/literal', 8, 0
	BCAT_ENTRY	slash_branch, '/branch', 7, 0
	BCAT_ENTRY	slash_compile, '/compile', 8, 0
	BCAT_ENTRY	body_offset, 'body-offset', 11, 0	
	BCAT_ENTRY	decompile, 'decompile', 9, 0
	BCAT_ENTRY	decompile_to, 'decompile>', 10, 0
	BCAT_ENTRY	rs_to_compile, 'rs>compile', 10, 0
	
	BCAT_ENTRY	exec_able, 'exec''able', 9, 0
	BCAT_ENTRY	paren_colon_exec_able, '(:-exec''able)', 13, 0

; PPC specific	
	BCAT_ENTRY	le_question, 'le?', 3, 0
	BCAT_ENTRY	initvecat, 'initvec@', 8, 0
	BCAT_ENTRY	sprstore, 'spr!', 4, 0
	BCAT_ENTRY	sprfetch, 'spr@', 4, 0
	BCAT_ENTRY	pvrat, 'pvr@', 4, 0
	BCAT_ENTRY	tbat, 'tb@', 3, 0
	BCAT_ENTRY	msrstore, 'msr!', 4, 0
	BCAT_ENTRY	msrfetch, 'msr@', 4, 0
	BCAT_ENTRY	xbstore, 'xb!', 3, 0
	BCAT_ENTRY	xbfetch, 'xb@', 3, 0
	BCAT_ENTRY	xwstore, 'xw!', 3, 0
	BCAT_ENTRY	xwfetch, 'xw@', 3, 0
	BCAT_ENTRY	xstore, 'xl!', 3, 0
	BCAT_ENTRY	xfetch, 'xl@', 3, 0
	BCAT_ENTRY	fregsfetch, 'fregs@', 6, 0
	BCAT_ENTRY	fregsstore, 'fregs!', 6, 0
	BCAT_ENTRY	cycles, 'cycles', 6, 0
	BCAT_ENTRY	map_page, 'map-page', 8, 0
	BCAT_ENTRY	unmap_page, 'unmap-page', 10, 0
	BCAT_ENTRY	paren_xlat_to, '(xlat>)', 7, 0
	BCAT_ENTRY	to_interrupted, '>interrupted', 12, 0
	

	ifndef __HOSTED
	
	BCAT_ENTRY	pparen_go, '((go))', 6, 0
	BCAT_ENTRY	pparen_init_prgm, '((init-prgm))', 13, 0
	BCAT_ENTRY	ppparen_scallback, '((($callback)))', 15, 0
	BCAT_ENTRY	paren_ci_return, '(ci-return)', 11, 0
	BCAT_ENTRY	paren_install_ints, '(install-ints)', 14, 0
	BCAT_ENTRY	paren_restore_ints, '(restore-ints)', 14, 0
	BCAT_ENTRY	paren_restore_ath, '(restore-ath)', 13, 0
	BCAT_ENTRY	paren_install_ath, '(install-ath)', 13, 0
	BCAT_ENTRY	paren_client_maps, '(client-maps)', 13, 0
	BCAT_ENTRY	paren_cx_return, '(cx-return)', 11, 0
	
	BCAT_ENTRY	set_603_power, 'set-603-power', 13, 0
	
	endif
	
	ifdef __HOSTED
	
	BCAT_ENTRY	bracketdebug, '<debug>', 7, 0
	BCAT_ENTRY	host_bye, '(host-bye)', 10, 0
	BCAT_ENTRY	host_key_question, '(host-key?)', 11, 0
	BCAT_ENTRY	host_key, '(host-key)', 10, 0
	BCAT_ENTRY	host_emit, '(host-emit)', 11, 0
	BCAT_ENTRY	host_read, '(host-read)', 11, 0
	BCAT_ENTRY	host_alarms_store, '(host-alarms!)', 14, 0
	BCAT_ENTRY	host_ahandler_store, '(host-ahdlr!)', 13, 0
	BCAT_ENTRY	host_user_abort, '(host-u-a)', 10, 0
	
	endif
	
	ifdef __MAPIO
	
	BCAT_ENTRY	bracket_map_io, '<map-io>', 8, 0
	
	endif

	ifdef __DEBUG_OUT

	BCAT_ENTRY	bracket_square, '<square>', 8, 0

	endif

	BCAT_END

	align 5
;
core_begin:
;

;;;;;;;;; bootstrap interpreter particulars

find:					; (input)  r3: name-addr r4: name-len 
						; (output) r3: bde
	mflr	r16
	mr		r13, r3
	mr		r14, r4
	subi	r15, r24, 24
floop:
	lbz		r6, 0(r15)

	cmplw	r6, r14
	bne		fnx

memequal_replace:
	mr		r3, r13
	addi	r4, r15, 8
	cmpwi	r14, 0
	lbz		r6, 0(r3)
	mtctr	r14
	beq-	mer_out_yes
	lbz		r7, 0(r4)
mer_l:
	cmplw	r6, r7
	lbzu	r6, 1(r3)
	bne		mer_out_no
	lbzu	r7, 1(r4)
	bdnz	mer_l
mer_out_yes:
	mr		r3, r15
	mtlr	r16
	blr
mer_out_no:
fnx:
	subi	r15, r15, 24
	b		floop

do:					; (input)  r4: word type  r5: code pointer
	mflr	r0
	stwu	r0, -4(r1)
	andi.	r0, r4, 2
	beq		run
	
	mtctr	r5
	bctrl
	lwz		r0, 0(r1)
	addi	r1, r1, 4
	mtlr	r0
	blr
	
run:				; (input)  r5: compiled word pointer
					;  pushes and pops interpreter code pointer (r20) on/from the return stack
	stwu	r20, -4(r30)
	mr		r20, r5	
runl:
	lwz		r5, 0(r20)
	cmpwi	r5, -1
	beq		rund
	mulli	r3, r5, 24
	add		r3, r3, r23
	lbz		r4, 1(r3)
	lwz		r5, 4(r3)
	addi	r20, r20, 4
	bl		do
	b		runl
rund:
	lwz		r20, 0(r30)
	addi	r30, r30, 4
	lwz		r0, 0(r1)
	addi	r1, r1, 4
	mtlr	r0
	blr

;
core_entry:
;
	if DEBUG_OUTPUT
	
	li		r0, 0
	lis		r10, 0xBABA
	ori		r10, r10, 0x10
	sc

	endif

	ifndef __HOSTED

setup_ci:
	bl		sci_here

sci_here:

	mflr	r2
	lwz		r3, IV_INTERNALS(r22)

	addi	r16, r2, swapstore - sci_here
	addi	r17, r16, SS_CLI_CTX			; r17: clictx
	addi	r16, r16, SS_OF_CTX				; r16: ofctx
	stw		r17, INT_CLI_CTX(r3)
	stw		r16, INT_OF_CTX(r3)
	stw		r17, CTX_OTHER(r16)
	stw		r16, CTX_OTHER(r17)
	
	lwz		r1, IV_VIRT_BASE(r22)			; Get the real address of the client context
	sub		r0, r17, r1
	lwz		r1, IV_REAL_BASE(r22)
	add		r0, r0, r1
	stw		r0, INT_CLI_CTX_REAL(r3)

	addi	r1, r2, ci_swapdesc - sci_here	; Client->OF: CI service invoked
	addi	r0, r2, ppc_ci_handler - sci_here
	stw		r0, SWD_DEST(r1)
	stw		r17, SWD_CALLING_CTX(r1)
	stw		r16, SWD_CALLED_CTX(r1)

	addi	r1, r2, cx_swapdesc - sci_here	; Client->OF: client exception caught
	addi	r0, r2, cli_exc_after_swap - sci_here
	stw		r0, SWD_DEST(r1)
	stw		r17, SWD_CALLING_CTX(r1)
	stw		r16, SWD_CALLED_CTX(r1)

	addi	r1, r2, go_swapdesc - sci_here	; OF->Client: OF launching client
	stw		r1, INT_GO_SWD(r3)
	stw		r16, SWD_CALLING_CTX(r1)
	stw		r17, SWD_CALLED_CTX(r1)

	addi	r1, r2, callback_swapdesc - sci_here	; OF->Client: client callback invoked
	stw		r1, INT_CALLBACK_SWD(r3)
	stw		r16, SWD_CALLING_CTX(r1)
	stw		r17, SWD_CALLED_CTX(r1)

	addi	r1, r2, client_exception_ll - sci_here
	stw		r1, INT_LL_CX_HANDLER(r3)
	addi	r1, r2, client_exception_in_cb_ll - sci_here
	stw		r1, INT_LL_CX_CB_HDLR(r3)
	

	endif

	if DEBUG_OUTPUT
	
	li		r0, 0
	lis		r10, 0xBABA
	ori		r10, r10, 0x11
	sc

	endif
	
	mr		r1, r18			; load our temp stack ptr
lop:
; The main bootstrap compiler loop
lopl:
	bl		parse			; parse and look up next word
	bl		find
	
	lbz		r4, 1(r3)
	lwz		r5, 4(r3)	
	andi.	r0, r4, 1		; check if it's an immediate word
		
	bne		lopi
	li		r0, 24			; not immediate, so compile it.
	subf	r3, r23, r3
	divwu	r3, r3, r0
	stw		r3, 0(r21)
	addi	r21, r21, 4
	b		lopl
lopi:						; immediate word: execute it.
	bl		do
	b		lopl


;;;;;;;;;;; bootstrap primitives
	
_in:	
	lbz		r3, 0(r26)
	addi	r26, r26, 1
	blr

; Parse a string
parse:					; (output) r3: string-addr  r4: string-len
	mflr	r0	
skip:
	bl		_in
	cmplwi	r3, 20
	ble		skip
	mr		r13, r26
scan:
	bl		_in
	cmplwi	r3, 32
	bgt		scan
	subf	r4, r13, r26
	subi	r3, r13, 1
	mtlr	r0
	blr
	
	
colon:
	mflr	r16
	bl		parse
	li		r0, 0
	stb		r4, 0(r24)
	stb		r0, 1(r24)
	stw		r21, 4(r24)
	lwz		r5, 0(r3)
	lwz		r6, 4(r3)
	lwz		r7, 8(r3)
	lwz		r8, 12(r3)
	stw		r5, 8(r24)
	stw		r6, 12(r24)
	stw		r7, 16(r24)
	stw		r8, 20(r24)
	addi	r24, r24, 24
	mtlr	r16
	blr

immediate:
	li		r0, 1
	stb		r0, -23(r24)
	blr

semi:
	li		r0, -1
	stw		r0, 0(r21)
	addi	r21, r21, 4
	blr

in:
	lbz		r3, 0(r26)
	addi	r26, r26, 1
	stwu	r29, -4(r31)
	mr		r29, r3
	blr

_n:	
	li		r0, 5
	stw		r0, 0(r21)
	stw		r29, 4(r21)
	addi	r21, r21, 8
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr
	
to_n:
	stwu	r29, -4(r31)
	lwz		r29, 0(r20)
	addi	r20, r20, 4
	blr

;;;;;;;;;;; primitives
	
_add:
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	add		r29, r29, r3
	blr
	
_sub:	
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	subf	r29, r29, r3
	blr
	
_mul:
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	mullw	r29, r29, r3
	blr
	
_div:	
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	divw	r29, r3, r29
	blr
	
tor:
	stwu	r29, -4(r30)
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr
	
fromr:
	stwu	r29, -4(r31)
	lwz		r29, 0(r30)
	addi	r30, r30, 4
	blr

rfetch:
	stwu	r29, -4(r31)
	lwz		r29, 0(r30)
	blr

rpick:
	slwi	r29, r29, 2
	lwzx	r29, r29, r30
	blr

cstore:	
	lwz		r3, 0(r31)
	stb		r3, 0(r29)
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
	
cfetch:
	lbz		r29, 0(r29)
	blr
	
wstore:
	lwz		r3, 0(r31)
	sth		r3, 0(r29)
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
	
wfetch:	
	lhz		r29, 0(r29)
	blr
	
store:	
	lwz		r3, 0(r31)
	stw		r3, 0(r29)
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
	
fetch:	
	lwz		r29, 0(r29)
	blr
	
_1store:	
	mr		r27, r29
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

_1fetch:	
	stwu	r29, -4(r31)
	mr		r29, r27
	blr
	
_2store:
	mr		r28, r29
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr
	
_2fetch:
	stwu	r29, -4(r31)
	mr		r29, r28
	blr
	
lessthan:
	lwz		r3, 0(r31)
	subfc	r4, r29, r3
	srwi	r3, r3, 31
	addi	r31, r31, 4
	srwi	r29, r29, 31
	subfe	r29, r3, r29
	blr

ulessthan:
	lwz		r3, 0(r31)
	subfc	r3, r29, r3
	addi	r31, r31, 4
	subfe	r29, r29, r29
	blr
	
equals:	
	lwz		r3, 0(r31)
	subf	r3, r3, 29
	subic	r3, r3, 1
	addi	r31, r31, 4
	subfe	r29, r29, r29
	blr
	
lshift:
	lwz		r3, 0(r31)
	slw		r29, r3, r29
	addi	r31, r31, 4
	blr
	
rshift:	
	lwz		r3, 0(r31)
	srw		r29, r3, r29
	addi	r31, r31, 4
	blr
	
rshifta:	
	lwz		r3, 0(r31)
	sraw	r29, r3, r29
	addi	r31, r31, 4
	blr
	
rrot:	
	lwz		r3, 0(r31)
	subfic	r29, r29, 32
	addi	r31, r31, 4
	rotlw	r29, r3, r29
	blr
	
_and:
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	and		r29, r29, r3
	blr
	
_or:	
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	or		r29, r29, r3
	blr
	
_xor:	
	lwz		r3, 0(r31)
	addi	r31, r31, 4
	xor		r29, r29, r3
	blr

slashmod:	
	lwz		r3, 0(r31)
	divw	r4, r3, r29
	mullw	r5, r4, r29
	mr		r29, r4
	subf	r3, r5, r3
	stw		r3, 0(r31)
	blr
	
uslashmod:
	lwz		r3, 0(r31)
ue:	divwu	r4, r3, r29
	mullw	r5, r4, r29
	mr		r29, r4
	subf	r3, r5, r3
	stw		r3, 0(r31)
	blr
	
umslashmod:
	lwz		r4, 0(r31)
	li		r7, -1
	lwz		r3, 4(r31)
	mr.		r4, r4
	cntlzw	r6, r29
	cntlzw	r5, r4
	subf	r5, r5, r6
	beq+	umsm32
	neg		r0, r5
	addi	r6, r5, 32
	slw		r13, r29, r5
	srw		r0, r29, r0
	addi	r9, r5, 33
	slw		r29, r29, r6
	or		r13, r13, r0
	mtctr	r9
umsmlp:
	subfc	r11, r29, r3
	rotlwi	r7, r7, 1
	subfe.	r12, r13, r4
	srwi	r29, r29, 1
	rlwimi	r7, r12, 1, 31, 31
	bdz		umsmdn
	rlwimi	r29, r13, 31, 0, 0
	srwi	r13, r13, 1
	blt		umsmlp
	mr		r4, r12
	mr		r3, r11
	b		umsmlp
umsmdn:
	blt		umsmd1
	mr		r3, r11
umsmd1:
	not		r29, r7
	stwu	r3, 4(r31)
	blr
umsm32:
	addi	r31, r31, 4
	b		ue
	
umstar:
	lwz		r3, 0(r31)
	mullw	r4, r29, r3
	mulhwu	r29, r29, r3
	stw		r4, 0(r31)
	blr
	
mstar:	
	lwz		r3, 0(r31)
	mullw	r4, r29, r3
	mulhw	r29, r29, r3
	stw		r4, 0(r31)
	blr
	
execute:
	mtctr	r29
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	bctr
	
dspstore:
	mr		r31, r29
	blr

dspfetch:
	mr		r3, r31
	stwu	r29, -4(r31)
	mr		r29, r3
	blr
		
rspstore:
	mr		r30, r29
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

rspfetch:	
	stwu	r29, -4(r31)
	mr		r29, r30
	blr
		
move:
	lwz		r3, 4(r31)
	lwz		r4, 0(r31)
	mr		r5, r29

memcopy:
	; r3: source  -  r4: dest  -  r5: length
	cmplwi	cr1, r5, 0			; Zero move?
	sub.	r0, r3, r4			; Move backwards?
	beq-	cr1, move_out		;  zero move, just return
	xor		r9, r3, r4			; Alignment
	cmplwi	cr1, r5, 0x10		; Short move?
	ble		mc_back				;  r3 before r4, move backwards

	rlwinm.	r9, r9, 0, 3		; Word-aligned?
	subi	r3, r3, 1			; Offset source
	subi	r4, r4, 1			; Offset dest	
	blt		cr1, mc_bytes		;  short move, move by bytes
	xori	r8, r3, 3
	bne		mc_bytes			;  not word-aligned, move by bytes
	rlwinm.	r8, r8, 0, 3		; Get #bytes for beginning alignment
	mtctr	r8
	beq		mc_alreadya			;  already, aligned, skip this part
	
mc_beginal:
	lbzu	r6, 1(r3)
	stbu	r6, 1(r4)
	bdnz	mc_beginal
	
	sub		r5, r5, r8			; Adjust length
mc_alreadya:
	subi	r3, r3, 3			; Adjust source
	srwi	r9, r5, 3			; Get #doublewords
	subi	r4, r4, 3			; Adjust dest
	mtctr	r9
	rlwinm.	r5, r5, 0, 7		; Get remaining bytes for later

mc_wmovel:
	lwz		r6, 4(r3)			; Copy words
	lwzu	r7, 8(r3)
	stw		r6, 4(r4)
	stwu	r7, 8(r4)
	bdnz	mc_wmovel

mc_enda:
	addi	r3, r3, 3			; Adjust source
	addi	r4, r4, 3			; Adjust dest
	beq		move_out			; Leave if no remaining bytes
mc_bytes:
	mtctr	r5
mc_bytel:
	lbzu	r6, 1(r3)			; Copy bytes
	stbu	r6, 1(r4)
	bdnz	mc_bytel
	
move_out:
	lwz		r29, 8(r31)
	addi	r31, r31, 12
	blr

mc_back:
	add		r3, r3, r5			; Move r3 just after end of source
	beq-	move_out			; source=dest, return
	rlwinm.	r9, r9, 0, 3		; Word-aligned?
	add		r4, r4, r5			; Move r4 just after end of dest
	blt		cr1, mc_bbytes		;  short move, move by bytes
	crmove	cr1_so, cr0_eq		; Move this out of the way
	rlwinm.	r8, r3, 0, 3		; Get #bytes for beginning alignment
	mtctr	r8
	bns		cr1, mc_bbytes		;  not word-aligned, move by bytes
	sub		r5, r5, r8			; Adjust length
	beq		mc_balreadya
mc_bbeginal:
	lbzu	r6, -1(r3)
	stbu	r6, -1(r4)
	bdnz	mc_bbeginal
	
mc_balreadya:
	srwi	r9, r5, 3			; Get #doublewords
	rlwinm.	r5, r5, 0, 7		; Get remaining bytes for later
	mtctr	r9

mc_bwmovel:
	lwz		r6, -4(r3)			; Copy words
	lwzu	r7, -8(r3)
	stw		r6, -4(r4)
	stwu	r7, -8(r4)
	bdnz	mc_bwmovel

	beq		move_out			; Return if no remaining bytes
mc_bbytes:
	mtctr	r5					; Move in byte count
mc_bbytel:
	lbzu	r6, -1(r3)
	stbu	r6, -1(r4)
	bdnz	mc_bbytel
	b		move_out

fill:
	lwz		r3, 4(r31)
	lwz		r4, 0(r31)
	subi	r3, r3, 1
	cmplwi	r4, 0
	mtctr	r4
	beq		fill0
filllp:
	stbu	r29, 1(r3)
	bdnz	filllp
fill0:
	lwz		r29, 8(r31)
	addi	r31, r31, 12
	blr

comp:
	mr.		r29, r29
	lwz		r3, 4(r31)
	mtctr	r29
	lwz		r4, 0(r31)
	subi	r3, r3, 1
	addi	r31, r31, 8
	beq-	compeq
	subi	r4, r4, 1
complp:
	lbzu	r6, 1(r3)
	lbzu	r7, 1(r4)
	cmplw	r6, r7
	bne		compne
	bdnz	complp
compeq:
	li		r29, 0
	blr
compne:
	bgt		compgt
	li		r29, -1
	blr
compgt:
	li		r29, 1
	blr	

flush:
	if WRITE_BACK
	lwz		r3, 0(r31)
	
	add		r4, r3, r29
	clrrwi	r3, r3, 5
	subi	r4, r4, 0x20
	sub		r4, r4, r3
fl_l:
	cmpwi	r4, 0
	dcbst	0, r3
	subi	r4, r4, 0x20
	addi	r3, r3, 0x20
	bgt		fl_l
	endif
	
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr

bracketcore:
	mflr	r16
	bl		bch
bch:
	mflr	r3
	stwu	r29, -4(r31)
	addi	r3, r3, cnbegin - bch
	li		r29, cnend - cnbegin
	stwu	r3, -4(r31)
	mtlr	r16
	blr
cnbegin:
	dc.b	'PPC32core 1.0 (devel, minimal, standalone)'
cnend:
	align	4

pparen_literal:
	lwz		r3, 0(r31)
	
	addis	r7, r3, 1
	lis		r5, 0x97BF
	subi	r7, r7, 0x8000
	ori		r5, r5, 0xFFFC
	cmplwi	cr1, r7, 0xFFFF
	clrlwi.	r6, r3, 0x10
	addi	r31, r31, 4
	
	ble		cr1, lit_low
	srwi	r4, r3, 0x10
	beq		lit_high
	
	oris	r4, r4, 0x3C60
	stw		r5, 4(r29)
	oris	r6, r6, 0x607D
	stw		r4, 0(r29)
	stw		r6, 8(r29)
	
	addi	r29, r29, 12
	blr

lit_low:
	stw		r5, 0(r29)
	oris	r6, r6, 0x3BA0
	stw		r6, 4(r29)
	addi	r29, r29, 8
	blr

lit_high:
	stw		r5, 0(r29)
	oris	r4, r4, 0x3FA0
	stw		r4, 4(r29)
	addi	r29, r29, 8
	blr

paren_compile:
	lis		r4, 0x4800
	lwz		r3, 0(r31)
	ori		r4, r4, 1
	sub		r3, r3, r29
	rlwimi	r4, r3, 0, 0x03FFFFFC
	addi	r31, r31, 4
	stw		r4, 0(r29)
	addi	r29, r29, 4
	blr

paren_prologue:
	lis		r3, 0x7C08
	lis		r4, 0x941E
	ori		r3, r3, 0x02A6
	ori		r4, r4, 0xFFFC
	stw		r3, 0(r29)
	stw		r4, 4(r29)
	addi	r29, r29, 8
	blr

paren_epilogue:
	lis		r3, 0x801E
	lis		r4, 0x3BDE
	stw		r3, 0(r29)
	ori		r4, r4, 0x0004
	stw		r4, 4(r29)
	
	lis		r5, 0x7C08
	lis		r6, 0x4E80
	ori		r5, r5, 0x03A6
	ori		r6, r6, 0x0020
	
	stw		r5, 8(r29)
	stw		r6, 12(r29)
	
	addi	r29, r29, 16
	blr

paren_branch:
	lis		r3, 0x4800
	addi	r29, r29, 4
	stw		r3, -4(r29)
	blr

paren_f_branch:
	lis		r7, 0x4182
	b		c_branch
	
paren_t_branch:
	lis		r7, 0x4082

c_branch:
	lis		r4, 0x281D
	stw		r7, 12(r29)
	lis		r5, 0x83BF
	lis		r6, 0x3BFF
	stw		r4, 0(r29)
	ori		r6, r6, 0x0004
	stw		r5, 4(r29)
	stw		r6, 8(r29)
	addi	r29, r29, 16
	blr

paren_return:
	lis		r3, 0x4E80
	addi	r29, r29, 4
	ori		r3, r3, 0x0020
	stw		r3, -4(r29)
	blr

paren_resolve:
	lwz		r3, 0(r31)
	subi	r3, r3, 4
	sub		r4, r29, r3
	lwz		r5, 0(r3)

	andis.	r0, r5, 0x0800
	lwz		r29, 4(r31)
	rlwimi	r5, r4, 0, 0xFFFC
	beq		res_cond
	rlwimi	r5, r4, 0, 0x03FF0000
res_cond:
	stw		r5, 0(r3)
	addi	r31, r31, 8
	if WRITE_BACK
	dcbst	0, r3
	endif
	icbi	0, r3

	blr

slash_code:
	stwu	r29, -4(r31)
	li		r29, instr_len
	blr
	
slash_prologue:
	stwu	r29, -4(r31)
	li		r29, prologue_len
	blr

slash_epilogue:
	stwu	r29, -4(r31)
	li		r29, epilogue_len
	blr

slash_literal:
	stwu	r29, -4(r31)
	li		r29, literal_len
	blr

slash_branch:
	stwu	r29, -4(r31)
	li		r29, branch_len
	blr

slash_compile:
	stwu	r29, -4(r31)
	li		r29, compile_len
	blr

body_offset:
	stwu	r29, -4(r31)
	li		r29, 16
	blr
	
decompile_to:
	crset	cr1_so
	b		decomp_common

decompile:
	crclr	cr1_so
decomp_common:

;   ( addr -- addr' dest dec.call
;			| addr' n dec.lit
;			| addr' dec.pro
;			| addr' dec.epi
;			| addr' dest dec.br
;			| addr' dest dec.f-br
;			| addr' dest dec.t-br
;			| addr' dec.other )


	lwz		r3, 0(r29)
	
	rlwinm	r0, r3, 6, 0x3F
	srwi	r4, r3, 0x10
	cmplwi	r0, 0x12
	clrlwi	r7, r3, 0x10
	
	bne		decomp_not_long_br
	
	mr		r9, r29
	addi	r29, r29, 4
	andi.	r0, r3, 1
	bsolr	cr1
	
	rlwinm	r8, r3, 6, 0xFFFFFF00
	stw		r29, -4(r31)
	srawi	r8, r8, 6
	li		r29, dec_call
	add		r8, r8, r9
	bne		decomp_call
	li		r29, dec_br
decomp_call:
	stwu	r8, -8(r31)
	blr
	
decomp_not_long_br:
	cmplwi	r4, 0x3C60
	beq		decomp_lit
	cmplwi	r4, 0x97BF
	beq		decomp_simple_lit
	cmplwi	r4, 0x7C08
	beq		decomp_pro
	cmplwi	r4, 0x801E
	beq		decomp_epi
	cmplwi	r4, 0x281D
	beq		decomp_cond_br

decomp_other:	
	addi	r29, r29, 4
	bsolr	cr1
	stwu	r29, -4(r31)
	li		r29, dec_other
	blr	

decomp_lit:
	addi	r29, r29, 12
	bsolr	cr1
	
	lwz		r4, -4(r29)
	slwi	r8, r3, 0x10
	stw		r29, -4(r31)
	rlwimi	r8, r4, 0, 16, 31

decomp_lit_out:
	li		r29, dec_lit
	stwu	r8, -8(r31)
	blr

decomp_simple_lit:
	addi	r29, r29, 8
	bsolr	cr1
	
	lwz		r4, -4(r29)
	stw		r29, -4(r31)
	andis.	r0, r4, 0x0400

	bne		decomp_lit_high

	extsh	r8, r4
	b		decomp_lit_out

decomp_lit_high:
	slwi	r8, r4, 0x10
	b		decomp_lit_out

decomp_pro:
	cmplwi	r7, 0x02A6
	bne		decomp_other

	addi	r29, r29, prologue_len
	bsolr	cr1
	
	stwu	r29, -4(r31)
	li		r29, dec_pro
	blr

decomp_epi:
	cmplwi	r7, 0
	bne		decomp_other

	addi	r29, r29, epilogue_len
	bsolr	cr1
	
	stwu	r29, -4(r31)
	li		r29, dec_epi
	blr

decomp_cond_br:
	addi	r29, r29, cbranch_len
	bsolr	cr1
	
	lwz		r3, -4(r29)
	subi	r9, r29, 4
	rlwinm	r7, r3, 8, 0x0001
	slwi	r8, r3, 0x10
	stw		r29, -4(r31)
	srawi	r8, r8, 0x10
	ori		r29, r7, dec_t_br
	add		r8, r8, r9
	stwu	r8, -8(r31)
	blr

rs_to_compile:
	subi	r29, r29, compile_len
	blr

exec_able:
	lwz		r3, 0(r31)
	
	add		r4, r3, r29
	clrrwi	r3, r3, 5
	subi	r4, r4, 0x20
	sub		r4, r4, r3
ea_l:
	cmpwi	r4, 0
	if WRITE_BACK
	dcbst	0, r3
	endif
	subi	r4, r4, 0x20
	icbi	0, r3
	addi	r3, r3, 0x20
	bgt		ea_l

	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr

paren_colon_exec_able:
	if WRITE_BACK
	lwz		r3, 0(r31)

	add		r4, r3, r29
	clrrwi	r3, r3, 5
	subi	r4, r4, 0x20
	sub		r4, r4, r3
cea_l:
	cmpwi	r4, 0
	dcbst	0, r3
	subi	r4, r4, 0x20
;	icbi	0, r3
	addi	r3, r3, 0x20
	bgt		cea_l
	endif

	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr


le_question:
	stwu	r29, -4(r31)
	li		r29, 0
	bgelr	cr3
	li		r29, -1
	blr

initvecat:
	slwi	r29, r29, 2
	lwzx	r29, r22, r29
	blr

sprstore:
	lwz		r0, 0(r31)
	
	lis		r8, 0x7C00
	rlwimi	r29, r29, 22, 0, 4			; rearrange the five-bit halves of the SPR#
	ori		r8, r8, 0x03A6
	rlwimi	r8, r29, 16, 11, 20			; and insert into instruction

	lwz		r29, 4(r31)
	addi	r31, r31, 8
	
	b		spr_common

sprfetch:
	lis		r8, 0x7FA0
	rlwimi	r29, r29, 22, 0, 4
	ori		r8, r8, 0x02A6
	rlwimi	r8, r29, 16, 11, 20	

spr_common:
	mflr	r4
	bl		spr_com_here
spr_com_here:
	mflr	r5
	li		r6, code_playpen - spr_com_here
	stwx	r8, r6, r5
	eieio
	
	ifdef __HOSTED
	dcbf	r5, r6
	else
	if WRITE_BACK
	dcbf	r5, r6
	endif
	endif

	sync
	icbi	r5, r6	
	isync
	
	nop
	nop
	nop
	nop						; Not in this cache block!
	nop
	nop
	nop
	nop
code_playpen:
	nop						; <-- will be modified
	mtlr	r4
	blr
	
pvrat:
	stwu	r29, -4(31)
	mfpvr	r29
	blr
		
tbat:
	stw		r29, -4(r31)
tbat_again:
	mftbu	r29
	mftb	r3
	mftbu	r0
	cmplw	r29, r0
	bne-	tbat_again
	stwu	r3, -8(r31)
	blr
		
msrstore:
	addi	r31, r31, 4
	isync
	mtmsr	r29
	isync
	sync
	lwz		r29, -4(r31)
	blr

msrfetch:
	stwu	r29, -4(r31)
	mfmsr	r29
	blr

xbstore:
	lwz		r3, 0(r31)
	stb		r3, 0(r29)
	sync
	isync
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
	
xbfetch:
	lbz		r29, 0(r29)
	sync
	isync
	blr
	
xwstore:
	lwz		r3, 0(r31)
	sth		r3, 0(r29)
	sync
	isync
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
	
xwfetch:
	lhz		r29, 0(r29)
	sync
	isync
	blr
	
xstore:
	lwz		r3, 0(r31)
	stw		r3, 0(r29)
	sync
	isync
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
	
xfetch:	
	lwz		r29, 0(r29)
	sync
	isync
	blr

; fregs@	( fregstruct -- )
fregsfetch:
	stfd	fp0, 0x00(r29)
	stfd	fp1, 0x08(r29)
	stfd	fp2, 0x10(r29)
	stfd	fp3, 0x18(r29)
	stfd	fp4, 0x20(r29)
	stfd	fp5, 0x28(r29)
	stfd	fp6, 0x30(r29)
	stfd	fp7, 0x38(r29)
	stfd	fp8, 0x40(r29)
	stfd	fp9, 0x48(r29)
	stfd	fp10, 0x50(r29)
	stfd	fp11, 0x58(r29)
	stfd	fp12, 0x60(r29)
	stfd	fp13, 0x68(r29)
	stfd	fp14, 0x70(r29)
	stfd	fp15, 0x78(r29)
	stfd	fp16, 0x80(r29)
	stfd	fp17, 0x88(r29)
	stfd	fp18, 0x90(r29)
	stfd	fp19, 0x98(r29)
	stfd	fp20, 0xA0(r29)
	stfd	fp21, 0xA8(r29)
	stfd	fp22, 0xB0(r29)
	stfd	fp23, 0xB8(r29)
	stfd	fp24, 0xC0(r29)
	stfd	fp25, 0xC8(r29)
	stfd	fp26, 0xD0(r29)
	stfd	fp27, 0xD8(r29)
	stfd	fp28, 0xE0(r29)
	stfd	fp29, 0xE8(r29)
	stfd	fp30, 0xF0(r29)
	stfd	fp31, 0xF8(r29)

	mffs	fp0
	stfd	fp0, 0x100(r29)
	lfd		fp0, 0x00(r29)
	
	blt		cr3, frf_le
	lwz		r4, 0x104(r29)		; make FPSCR always at offset 0x100
	stw		r4, 0x100(r29)
frf_le:

	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

; fregs!	( fregstruct -- )
fregsstore:
	blt		cr3, frs_le
	lwz		r4, 0x100(r29)		; make FPSCR always at offset 0x100
	stw		r4, 0x104(r29)
frs_le:

	lfd		fp0, 0x100(r29)
	mtfsf	0xFF, fp0

	lfd		fp0, 0x00(r29)
	lfd		fp1, 0x08(r29)
	lfd		fp2, 0x10(r29)
	lfd		fp3, 0x18(r29)
	lfd		fp4, 0x20(r29)
	lfd		fp5, 0x28(r29)
	lfd		fp6, 0x30(r29)
	lfd		fp7, 0x38(r29)
	lfd		fp8, 0x40(r29)
	lfd		fp9, 0x48(r29)
	lfd		fp10, 0x50(r29)
	lfd		fp11, 0x58(r29)
	lfd		fp12, 0x60(r29)
	lfd		fp13, 0x68(r29)
	lfd		fp14, 0x70(r29)
	lfd		fp15, 0x78(r29)
	lfd		fp16, 0x80(r29)
	lfd		fp17, 0x88(r29)
	lfd		fp18, 0x90(r29)
	lfd		fp19, 0x98(r29)
	lfd		fp20, 0xA0(r29)
	lfd		fp21, 0xA8(r29)
	lfd		fp22, 0xB0(r29)
	lfd		fp23, 0xB8(r29)
	lfd		fp24, 0xC0(r29)
	lfd		fp25, 0xC8(r29)
	lfd		fp26, 0xD0(r29)
	lfd		fp27, 0xD8(r29)
	lfd		fp28, 0xE0(r29)
	lfd		fp29, 0xE8(r29)
	lfd		fp30, 0xF0(r29)
	lfd		fp31, 0xF8(r29)

	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

cycles:
	addi	r3, r29, 7
	srwi.	r3, r3, 3
	mtctr	r3
	beq		cyc_done
	sync
cyl:
	addi	r3, r3, 1
	addi	r3, r3, 1
	addi	r3, r3, 1
	addi	r3, r3, 1
	addi	r3, r3, 1
	addi	r3, r3, 1
	addi	r3, r3, 1
	addi	r3, r3, 1
	bdnz+	cyl

cyc_done:
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

	
	ifndef __HOSTED

;	: map-page		( pt-mask pt virt phys mode -- pt-mask pt virt phys mode )

map_page:
	bltlr	cr4					; nothing to do for SWT

	mflr	r1
	
	lwz		r4, 0(r31)
	lwz		r3, 4(r31)
	clrrwi	r7, r4, 12
	lwz		r10, 12(r31)
	rlwimi	r7, r29, 0, 0x7F
	lwz		r11, 8(r31)	
	rlwinm	r7, r7, 0, 0xFFFFFFFB
	
	bl		map_unmap_common
	
	xori	r3, r4, 4	
mp1:
	lwzx	r9, r4, r11
	mr.		r9, r9
	bge		mpsto
	addi	r11, r11, 8
	bdnz	mp1
	
	subi	r11, r11, 0x40
	ori		r6, r6, 0x40
	xori	r11, r11, 0xFFC0
	xor		r11, r11, r10

	mtctr	r5
mp2:
	lwzx	r9, r4, r11
	mr.		r9, r9
	bge		mpsto
	addi	r11, r11, 8
	bdnz	mp2

	b		mpout
	
mpsto:
	stwx	r7, r3, r11
	eieio
	stwx	r6, r4, r11
	sync

mpout:
	mtlr	r1
	blr

;	: unmap-page		( pt-mask pt virt -- pt-mask pt virt )

unmap_page:
	blt		cr4, upswt					; just tlbie for SWT

	mflr	r1

	lwz		r10, 4(r31)
	mr		r3, r29
	lwz		r11, 0(r31)
	
	bl		map_unmap_common
up1:
	lwzx	r9, r4, r11
	cmplw	r9, r6
	beq		upsto
	addi	r11, r11, 8
	bdnz	up1
	
	subi	r11, r11, 0x40
	ori		r6, r6, 0x40
	xori	r11, r11, 0xFFC0
	xor		r11, r11, r10

	mtctr	r5
up2:
	lwzx	r9, r4, r11
	cmplw	r9, r6
	beq		upsto
	addi	r11, r11, 8
	bdnz	up2

	b		upout

upsto:
	stwx	r0, r4, r11
	sync
	tlbie	r29
	eieio

upout:
	mtlr	r1
	blr

upswt:
	tlbie	r29
	eieio
	blr

;
map_unmap_common:
; <=  r3: virt    r10: pt-mask    r11: pt
; =>  r4: offset of high word    r5: 8   r6: high word of PTE   r10: pt-mask << 16   CTR: 8 
	rlwinm	r9, r3, 12, 0xF00
	rlwimi	r9, r9, 4, 0xF000
	oris	r9, r9, 0x1275
	
	srwi	r6, r9, 1
	oris	r6, r6, 0x8000
	rlwimi	r6, r3, 10, 0x3F
		
	rlwinm	r8, r3, 20, 0xFFFF
	rlwinm	r0, r9, 24, 0x7FFFF
	xor		r8, r8, r0
	
	slwi	r0, r8, 6
	slwi	r10, r10, 16
	and		r0, r0, r10
	rlwimi	r0, r8, 6, 0xFFC0
	or		r11, r0, r11
	
	li		r5, 8
	mtctr	r5
	
	li		r4, 0				; munge offsets for LE
	bgelr	cr3
	li		r4, 4
	blr

;	: (xlat>)			( addr len -- )			\ Makes translation table active for page fault/TLB load

; This code must not cross a page boundary or should run with IR = 0; otherwise the translation table might
;  not be stable for SWT.

paren_xlat_to:
	
	cmplwi	r29, 0x400
	lwz		r3, 0(r31)
	
	mfmsr	r7
	ble		xlt_en
	li		r29, 0x400
xlt_en:
	srwi.	r29, r29, 4
	rlwinm	r0, r7, 0, 0xFFFF7FFF	; Turn off EE -- we can't take an alarm here
	beq		xlt_none				; If no translations, just set SPRG0 to -1
	
	mtctr	r29
	lwz		r4, IV_TSTORE(r22)		; Get translation store
	mtmsr	r0

	subi	r5, r3, 16
	subi	r4, r4, 4
	
xlt_vloop:
	lwzu	r7, 16(r5)		; Store the virts
	stwu	r7, 4(r4)
	bdnz	xlt_vloop

	subi	r5, r3, 12
	mtctr	r29
xlt_sloop:
	lwzu	r7, 16(r5)		; Store the sizes
	stwu	r7, 4(r4)
	bdnz	xlt_sloop

	subi	r5, r3, 8
	mtctr	r29
xlt_pmloop:
	lwz		r8, 20(r5)
	lwzu	r7, 16(r5)		; Store the phys+modes
	andi.	r8, r8, 0x007B	; Make sure these are valid -- they go into PTEs as is.
	rlwimi	r7, r8, 0, 20, 31
	stwu	r7, 4(r4)
	bdnz	xlt_pmloop

xlt_none:
	lwz		r3, IV_INTERNALS(r22)
	stw		r29, INT_NTRANS(r3)	; Update count in the internals (actual # of translations)
	
	subi	r29, r29, 1
	mtsprg	0, r29			; Update the count in SPRG0 (which is actual #translations - 1)
	
	mtmsr	r0
	
	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr
paren_xlat_to_end:

	CANNOT_CROSS_PAGE paren_xlat_to, paren_xlat_to_end

	else

paren_xlat_to:
	lwz		r29, 4(r31)
	addi	r31, r31, 8
map_page:
unmap_page:
	blr

	endif


; : >interrupted		( ... new-msr  R: ... -- ...  R: ... [original state] )
;
; Restores the Forth context saved in the vector internals.
;
to_interrupted:
	ifdef PPC_BOOT_PRESENT
	mfmsr	r3
	rlwinm	r3, r3, 0, 0xFFFF7FFF		; EE should already be off; we must ensure it
	mtmsr	r3							;  is off while we load SRRs, etc.

	mtsrr1	r29							; New MSR

	lwz		r1, IV_INTERNALS(r22)
	addi	r1, r1, INT_FORTH_CTX
	
	lwz		r3, CTX_LR(r1)
	mtlr	r3
	lwz		r3, CTX_CTR(r1)
	mtctr	r3
	lwz		r3, CTX_CR(r1)
	mtcr	r3
	lwz		r3, CTX_XER(r1)
	mtxer	r3
	
	lwz		r3, CTX_PC(r1)
	mtsrr0	r3
	
	lmw		r2, (CTX_GPRS + 8)(r1)
	lwz		r0, (CTX_GPRS + 0)(r1)
	lwz		r1, (CTX_GPRS + 4)(r1)
	
	rfi

ti_end:

	CANNOT_CROSS_PAGE to_interrupted, ti_end

	else
	
	blr
	
	endif
	
	ifndef __HOSTED

my_vectors_in:					; This code moved here from ppc-boot so that it can be called
	mfmsr	r17					;  from both here and ppc-boot.
	rlwinm	r17, r17, 0, 0xFFFF7FFF		; Turn off EE first
	rlwinm	r18, r17, 0, 0xFFFFE0FF		; And ME, FE0, FE1, BE, SE
	mtmsr	r18
	isync						; Make sure it's there...

	if COPY_VECTORS
	mflr	r18					; r18 as return pointer - safe for the whole family!
	bl		mvi_here
mvi_here:
	mflr	r21
	addi	r21, r21, (vectors - mvi_here) - 4	; Get address of vector code in r21 minus an offset
	mtlr	r18					; Return it where it belongs
	
	if HIGH_VECTORS
	lis		r20, 0xFFF0			; Get the destination address in r20
	subi	r20, r20, 4			; And offset it…
	else
	li		r20, -4				; possibly in one step.
	endif
	
mvi_loop:
	lwzu	r19, 4(r21)			; Get the word count for this vector
	cmpwi	cr7, r19, 0
	mtctr	r19
	ble		cr7, mvi_clend		; If <=0, skip.
mvi_cloop:
	lwzu	r19, 4(r21)			; Copy words…
	stwu	r19, 4(r20)
	bdnz	mvi_cloop
mvi_clend:
	addi	r20, r20, 0x100		; Align to the next vector...
	clrrwi	r20, r20, 8
	subi	r20, r20, 4			; Offset
	bge		cr7, mvi_loop		; Keep copying until we get a negative size
	
	if HIGH_VECTORS
	addis	r20, r20, 0x10		; Get addresses to flush
	endif

mvi_flush:
	cmpwi	r20, 0				; Flush out the vectors
	dcbf	0, r20
	icbi	0, r20				; (should not be necessary)
	subi	r20, r20, 0x20
	bgt		mvi_flush

	endif
	
	if HIGH_VECTORS
	ori		r20, r17, 0x40		; Set IP to what we want
	else
	rlwinm	r20, r17, 0, 0xFFFFFFBF
	endif
	
	mtmsr	r17
	isync
	
	blr
	
;;
;; Client Interface Support
;;

swap_return:			; in: r11: old LR, LR: swap descriptor + 0x18
	mflr	r12
	subi	r12, r12, 0x18
	mtlr	r11
	lwz		r11, SWD_CALLED_CTX(r12)	
	b		swap_common
	
swap_entry:				; in: r12: swap descriptor
	lwz		r11, SWD_DEST(r12)		; copy dest addr to return addr.
swap_entry_to:			; in: r11: destination addr, r12: swap descriptor
	stw		r11, SWD_RET(r12)
	lwz		r11, SWD_CALLING_CTX(r12)

swap_common:			; in: r11: old context, r12: descriptor, 4(r12): addr to branch to
	stw		r0, CTX_GPR + 0x00(r11)		; save off GPRs
	stw		r1, CTX_GPR + 0x04(r11)		; of course, r11 and r12 have been changed
	stw		r2, CTX_GPR + 0x08(r11)
	stw		r3, CTX_GPR + 0x0C(r11)
	stw		r4, CTX_GPR + 0x10(r11)
	stw		r5, CTX_GPR + 0x14(r11)
	stw		r6, CTX_GPR + 0x18(r11)
	stw		r7, CTX_GPR + 0x1C(r11)
	stw		r8, CTX_GPR + 0x20(r11)
	stw		r9, CTX_GPR + 0x24(r11)
	stw		r10, CTX_GPR + 0x28(r11)
;	
;	
	stw		r13, CTX_GPR + 0x34(r11)
	stw		r14, CTX_GPR + 0x38(r11)
	stw		r15, CTX_GPR + 0x3C(r11)
	stw		r16, CTX_GPR + 0x40(r11)
	stw		r17, CTX_GPR + 0x44(r11)
	stw		r18, CTX_GPR + 0x48(r11)
	stw		r19, CTX_GPR + 0x4C(r11)
	stw		r20, CTX_GPR + 0x50(r11)
	stw		r21, CTX_GPR + 0x54(r11)
	stw		r22, CTX_GPR + 0x58(r11)
	stw		r23, CTX_GPR + 0x5C(r11)
	stw		r24, CTX_GPR + 0x60(r11)
	stw		r25, CTX_GPR + 0x64(r11)
	stw		r26, CTX_GPR + 0x68(r11)
	stw		r27, CTX_GPR + 0x6C(r11)
	stw		r28, CTX_GPR + 0x70(r11)
	stw		r29, CTX_GPR + 0x74(r11)
	stw		r30, CTX_GPR + 0x78(r11)
	stw		r31, CTX_GPR + 0x7C(r11)

	mflr	r17							; save for later
	
	stw		r17, CTX_LR(r11)			; just recording (not loaded from contexts)
	mfctr	r31							;
	stw		r31, CTX_CTR(r11)			;
	mfcr	r31							;
	stw		r31, CTX_CR(r11)
	mfxer	r31
	stw		r31, CTX_XER(r11)
	mfsprg	r31, 0						; We are only recording these;
	stw		r31, CTX_SPRG0(r11)			;  they will not be swapped here.
	mfsprg	r31, 1						;
	stw		r31, CTX_SPRG1(r11)			;
	mfsprg	r31, 2						;
	stw		r31, CTX_SPRG2(r11)			;
	mfsprg	r31, 3						;
	stw		r31, CTX_SPRG3(r11)			;
	mfsrr0	r31							;
	stw		r31, CTX_SRR0(r11)			;
	mfsrr1	r31							;
	stw		r31, CTX_SRR1(r11)			;
	mfmsr	r31							;
	stw		r31, CTX_MSR(r11)			;

	lwz		r13, SWD_RET(r12)
	mtctr	r13
	
	stw		r17, SWD_RET(r12)			; save LR into return addr field
										;  only necessary for swap_entry,
										;  but always harmless
	addi	r13, r12, SWD_RET_CODE		; again, we should be able to
	mtlr	r13							;  set LR without causing troubles.

	lwz		r11, CTX_OTHER(r11)			; get the other context

load_context:							; in: r11: context to load, ctr: destination, lr: return addr
	lwz		r31, CTX_CR(r11)
	mtcr	r31
	lwz		r31, CTX_XER(r11)
	mtxer	r31

	lwz		r0, CTX_GPR + 0x00(r11)		; load new GPRs
	lwz		r1, CTX_GPR + 0x04(r11)
	lwz		r2, CTX_GPR + 0x08(r11)
	lwz		r3, CTX_GPR + 0x0C(r11)
	lwz		r4, CTX_GPR + 0x10(r11)
	lwz		r5, CTX_GPR + 0x14(r11)
	lwz		r6, CTX_GPR + 0x18(r11)
	lwz		r7, CTX_GPR + 0x1C(r11)
	lwz		r8, CTX_GPR + 0x20(r11)
	lwz		r9, CTX_GPR + 0x24(r11)
	lwz		r10, CTX_GPR + 0x28(r11)
	lwz		r12, CTX_GPR + 0x30(r11)
	lwz		r13, CTX_GPR + 0x34(r11)
	lwz		r14, CTX_GPR + 0x38(r11)
	lwz		r15, CTX_GPR + 0x3C(r11)
	lwz		r16, CTX_GPR + 0x40(r11)
	lwz		r17, CTX_GPR + 0x44(r11)
	lwz		r18, CTX_GPR + 0x48(r11)
	lwz		r19, CTX_GPR + 0x4C(r11)
	lwz		r20, CTX_GPR + 0x50(r11)
	lwz		r21, CTX_GPR + 0x54(r11)
	lwz		r22, CTX_GPR + 0x58(r11)
	lwz		r23, CTX_GPR + 0x5C(r11)
	lwz		r24, CTX_GPR + 0x60(r11)
	lwz		r25, CTX_GPR + 0x64(r11)
	lwz		r26, CTX_GPR + 0x68(r11)
	lwz		r27, CTX_GPR + 0x6C(r11)
	lwz		r28, CTX_GPR + 0x70(r11)
	lwz		r29, CTX_GPR + 0x74(r11)
	lwz		r30, CTX_GPR + 0x78(r11)
	lwz		r31, CTX_GPR + 0x7C(r11)

	lwz		r11, CTX_GPR + 0x04(r11)

	bctr								; CTR and LR already set up


; ((init-prgm))			( entrypoint -- successful? )
pparen_init_prgm:
	mflr	r0
	bl		inip_here
inip_here:
	mflr	r4
	mtlr	r0

	lwz		r5, IV_INTERNALS(r22)
	lwz		r3, INT_CLI_CTX(r5)
	addi	r4, r4, ppc_raw_ci_handler - inip_here
	stw		r4, CTX_GPR + 0x14(r3)		; store raw CI handler in client's r5

	lwz		r4, INT_GO_SWD(r5)		; put entrypoint as destination
	stw		r29, SWD_DEST(r4)		;  in the 'go' descriptor

	li		r29, 0				; no error
	blr

; ((go))			( ... real-mode? -- successful? )
pparen_go:
	mflr	r0

	cmplwi	r29, 0					; pop real-mode? off the stack
	lwz		r29, 4(r31)
	addi	r31, r31, 4
	
	lwz		r12, IV_INTERNALS(r22)
	stw		r0, INT_PPGO_RET_ADDR(r12)
	
	lwz		r12, INT_GO_SWD(r12)	; get our swap descriptor

	mfmsr	r4
	rlwinm	r4, r4, 0, 0xFFFF7FFF	; turn off EE
	ori		r4, r4, 0x3000			; turn on FP, ME
	beq		ppg_virt
	rlwinm	r4, r4, 0, 0xFFFFFFCF	; turn off IR, DR for real-mode only
ppg_virt
	mtmsr	r4
	isync							; make sure it happens
	bl		swap_entry				; call client

									; At this point, the only state we can be
									;  sure of is that our memory is mapped
									;  (with appropriate SWT handlers, if neccessary)
									;  and that most of our registers (excepting LR, CTR) are good.
	
	lis		r29, 0xBEEF				; clear the stack
	ori		r29, r29, 0xCAFE
	lwz		r31, IV_STACK_BASE(r22)

	stw		r29, 0(r31)				
	li		r29, 0					; no error

	lwz		r12, IV_INTERNALS(r22)
	lwz		r0, INT_PPGO_RET_ADDR(r12)
		
	mtlr	r0
	blr


; ((($callback)))		( cbrout -- successful? )
ppparen_scallback:
	mflr	r0
	stwu	r0, -4(r30)

	mr		r11, r29			; r11 contains the destination address for swap_entry_to

	bl		pppsc_here
pppsc_here:
	mflr	r12
	addi	r12, r12, callback_swapdesc - pppsc_here

	bl		swap_entry_to

	li		r29, 0				; no error
	lwz		r0, 0(r30)
	addi	r30, r30, 4
	mtlr	r0
	blr

;; CI handler

ppc_raw_ci_handler:				; this is the entrypoint given to the client for
	mflr	r11					;  our CI interface. It swaps to
	bl		prch_here			;  ppc_ci_handler.
prch_here:
	mflr	r12
	addi	r12, r12, ci_swapdesc - prch_here
	mtlr	r11
	b		swap_entry			; Will branch to client's LR after ppc_ci_handler returns

ppc_ci_handler:
	lwz		r4, IV_INTERNALS(r22)
	stw		r30, INT_SAVED_RSP(r4)	; remember our RSP so we can restore it at (ci-return).

	lwz		r3, INT_CI_HANDLER(r4)
	mtctr	r3
	bctrl

; fallthrough

;  (ci-return)		( -- )
paren_ci_return:
	lwz		r12, IV_INTERNALS(r22)
	lwz		r30, INT_SAVED_RSP(r12)	; reload saved RSP

	b		ci_swapdesc + SWD_RET_CODE

;; This primitive indicates to the vectors that the client has taken over mapping
;;  in virtual mode (i.e., has issued a set-callback which handles map, unmap,
;;  translate).

; (client-maps)			( -- )
paren_client_maps:
					; Set INT_MY_SDR1 to something no one should ever set SDR1 to:
					;  the area for the vectors. That way, it should never equal SDR1
					;  (see ppc-vectors).
	if HIGH_VECTORS
	lis		r3, 0xFFF0
	else
	li		r3, 0
	endif
	
	lwz		r4, IV_INTERNALS(r22)
	stw		r3, INT_MY_SDR1(r4)	
	blr

;; The client caused an exception with our handlers active.
;;  Do a complete swap of registers (including r11, r12), enter the
;;  user interface, and throw the exception.
;; MSR, SRRs have been modified; the original SRRs are in the internals.
;;  r11 and r12 have already been saved to the client context. The
;;  BATs have been overwritten (although they should be saved off
;;  when (cx-return) implemented)
client_exception_ll:
	mflr	r11
	bl		cx_here
cx_here:
	mflr	r12
	addi	r12, r12, cx_swapdesc - cx_here
	mtlr	r11
	b		swap_entry

;; The OF context has been loaded. We just need to store the SRR0 and SRR1
;;  from the exception into the client context so we know how to return
;;  before calling the Forth handler. We will use them to return to the client.
;;  We will keep the value of MSR there that the vectors chose for us, not
;;  changing back to the client's MSR until we rfi there.
	
cli_exc_after_swap:
	lwz		r3, IV_INTERNALS(r22)
	stw		r30, INT_SAVED_RSP(r3)					; remember our RSP
													;  so we can restore it at (cx-return)
	lwz		r5, INT_CLI_CTX(r3)
	
	lwz		r4, INT_EXC_SRR0(r3)
	stw		r4, CTX_SRR0(r5)

	lwz		r4, INT_EXC_SRR1(r3)
	stw		r4, CTX_SRR1(r5)
	
	lwz		r5, INT_CLI_EXC_HANDLER(r3)
	mtctr	r5
	bctrl
	; fallthrough

;	*** cx-return NOT IMPLEMENTED (YET)
	b		$+0
;   ***
	
; (cx-return)			( -- )
paren_cx_return:
;	*** cx-return NOT IMPLEMENTED (YET)
	blr
;   ***

	lwz		r30, IV_INTERNALS(r22)
	lwz		r30, INT_SAVED_RSP(r30)					; reload saved RSP
	
	bl		cxr_here
cxr_here:
	mflr	r11
	addi	r12, r11, cx_swapdesc - cxr_here
	bl		swap_entry

;; The user typed 'go' after we caught an exception from the client. The client
;;  context has been loaded, except for the CTR, LR, and MSR. EE is off,
;;  IR and DR on (for virtual mode)/off (real mode). Use an rfi to return.
;;
;; To avoid calling the SWT handlers, or in case an HTAB spill
;;  ejected this page from the page table, this code cannot cross
;;  a page boundary.
cli_exc_ret_after_swap:
	bl		ceras_here								; We will change LR later anyway.
ceras_here:
	mflr	r2										; Load _virtual_ address of the client context
	addi	r2, r2, (swapstore + SS_CLI_CTX) - ceras_here
	lwz		r7, CTX_CTR(r2)
	mtctr	r7
	lwz		r7, CTX_LR(r2)
	mtlr	r7
	lwz		r7, CTX_SRR0(r2)
	mtsrr0	r7
	lwz		r7, CTX_SRR1(r2)						; Load SRR1 from CTX_MSR?
	mtsrr1	r7	
	lwz		r7, CTX_GPR + 0x1C(r2)					; Restore r2, r7; they were from the client context.
	lwz		r2, CTX_GPR + 0x8(r2)
	rfi
ceras_end:

;; The client caused an exception in a callback with our handlers active.
;;  We will simply load the OF context, start the UI, and throw the exception;
;;  the client's most recent state is discarded. If 'go' is executed,
;;  control returns to the client, just as with any CI call. If the
;;  CI service previously invoked was not 'enter', 'go' also returns an error
;;  in r3 to the client.
client_exception_in_cb_ll:
	bl		cxcb_here
cxcb_here:
	mflr	r3
	addi	r11, r3, (swapstore + SS_OF_CTX) - cxcb_here
	addi	r3, r3, cxcb_after_load - cxcb_here
	mtctr	r3										; load return address for load_context into CTR
	b		load_context							; load the OF context
cxcb_after_load:
	lwz		r3, IV_INTERNALS(r22)
	lwz		r3, INT_CLI_EXC_HANDLER(r3)
	mtctr	r3
	bctr											; not intended to return

;	CANNOT_CROSS_PAGE cli_exc_ret_after_swap, ceras_end
	

;; Saves off client vectors and SPRGs, installs my vectors and SPRGs.
;;  Also configures the IP and ILE bits in the MSR
;;  Turns off translation to do all this, and for virtual-mode only,
;;  turns it back on.

; (install-ints)		( xclient-save real-mode? -- )
paren_install_ints:

	mfmsr	r11						; First turn EE off
	rlwinm	r10, r11, 0, 0xFFFF7FFF
	mtmsr	r10						; r10 will hold our working MSR,
									;  r11 our desired MSR							
	if COPY_VECTORS
	andi.	r0, r11, 0x0040			; Check to see whether we and the client are using
									;  the same area for vectors. If not, just set IP.
	if HIGH_VECTORS
	crnot	cr0_eq, cr0_eq
	endif							; cr0[eq] = 0 if we need to copy in our vectors
	endif
	
	if HIGH_VECTORS
	ori		r11, r11, 0x0040		; Load our desired IP into r11
	else
	rlwinm	r11, r11, 0, 0xFFFFFFBF
	endif

	blt		cr3, ii_le
	rlwinm	r11, r11, 0, 0xFFFEFFFF	; Load our desired ILE into r11
	b		ii_le_out
ii_le:
	oris	r11, r11, 0x1
ii_le_out:

	mr.		r29, r29
	beq		ii_vm
	ori		r11, r11, 0x30			; Turn IR, DR on if in virtual-mode
ii_vm:

	lwz		r29, 0(r31)

	mflr	r12
	bl		ii_here
ii_here:
	mflr	r9
	lwz		r3, IV_VIRT_BASE(r22)
	lwz		r4, IV_REAL_BASE(r22)
	sub		r8, r9, r3				; convert code addr to real address
	sub		r29, r29, r3			; convert savearea to real address
	add		r8, r8, r4
	add		r29, r29, r4

	addi	r8, r8, ii_real - ii_here
	addi	r9, r9, ii_after_real - ii_here

	lwz		r6, IV_INTERNALS(r22)
	lwz		r5, INT_NTRANS(r6)
	subi	r5, r5, 1				; Our SPRG0
	lwz		r7, IV_TSTORE(r22)

	sub		r6, r6, r3				; Convert internals, translation store
	sub		r7, r7, r3 				;  to real addressses, which the vectors need
	add		r6, r6, r4				; r6 is our SPRG1
	add		r7, r7, r4				; r7 is our SPRG2

	rlwinm	r10, r10, 0, 0xFFFFFFCF	; IR, DR off; EE already off

	align 5							; Get inside a cache line
	nop								;  so we don't get caught by an SWT exception
	mtsrr0	r8
	mtsrr1	r10
	rfi

ii_real:							; No interrupts should be occurring now.
	mtsprg	0, r5					; Set our SPRGs
	mtsprg	1, r6
	mtsprg	2, r7
	
	if COPY_VECTORS					; Never copy vectors if COPY_VECTORS = 0
	
	bne		cr0, ii_no_copy_vectors	; Check whether we need to copy vectors
	
	li		r0, 0xC00				; Copy 12k
	mtctr	r0
	
	addi	r29, r29, XCS_VECTORS - 4	; Get dest w/offset
	if HIGH_VECTORS
	lis		r4, 0xFFF0
	subi	r4, r4, 4
	else
	li		r4, -4					; Load offseted vector base
	endif

ii_saveloop:
	lwzu	r3, 4(r4)
	stwu	r3, 4(r29)
	bdnz	ii_saveloop

	bl		my_vectors_in

	endif

ii_no_copy_vectors:
	mtsrr0	r9						; No need to worry about SWT exceptions here
	mtsrr1	r11
	rfi

ii_after_real:
	mtlr	r12

	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr

;; Restores the client's MSR, vectors, and SPRGs.

; (restore-ints)		( xclient-save -- )
paren_restore_ints:
	mfmsr	r11
	rlwinm	r10, r11, 0, 0xFFFF7FFF
	mtmsr	r10
	
	mflr	r7
	bl		ri_here
ri_here:
	mflr	r9

	lwz		r3, IV_VIRT_BASE(r22)
	lwz		r4, IV_REAL_BASE(r22)
	sub		r8, r9, r3				; convert code addr to real address
	sub		r29, r29, r3			; convert savearea to real address
	add		r8, r8, r4
	add		r29, r29, r4

	addi	r8, r8, ri_real - ri_here
	addi	r9, r9, ri_after_real - ri_here

	lwz		r12, IV_INTERNALS(r22)
	lwz		r12, INT_CLI_CTX(r12)
	
	lwz		r3, CTX_SPRG0(r12)		; Get client's SPRGs for later
	lwz		r4, CTX_SPRG1(r12)
	lwz		r5, CTX_SPRG2(r12)
	lwz		r6, CTX_SPRG3(r12)

	lwz		r12, CTX_MSR(r12)		; Get client's MSR

	if COPY_VECTORS					; Determine whether we need to copy vectors
	xor		r0, r11, r12
	andi.	r0, r0, 0x0040
	endif							; cr0[eq]=0 means we need to copy vectors

	rlwinm	r10, r10, 0, 0xFFFFFFCF	; IR, DR off; EE already off

	align 5
	nop
	mtsrr0	r8
	mtsrr1	r10
	rfi

ri_real:
	mtsprg	0, r3					; Set client's SPRGs
	mtsprg	1, r4
	mtsprg	2, r5
	mtsprg	3, r6

	if COPY_VECTORS
	
	bne		ri_no_copy_vectors		; Check whether vectors need to be copied
	
	li		r0, 0xC00				; Copy 12k
	mtctr	r0
									; Load offseted src
	addi	r29, r29, XCS_VECTORS - 4

	if HIGH_VECTORS
	lis		r4, -0x0010
	subi	r4, r4, 4
	else
	li		r4, -4					; Load offseted dest
	endif

ri_restore_loop:
	lwzu	r3, 4(r29)
	stwu	r3, 4(r4)
	bdnz	ri_restore_loop

	endif

ri_no_copy_vectors:
	mtsrr0	r9
	mtsrr1	r12						; Set client's MSR
	rfi

ri_after_real:
	mtlr	r7

	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

;; Disables translation, and restores the client's SDR1, BATs, SRs
;;  from an extended client save structure. Real-mode only, unless
;;  install-ath-w/-ints is true. In real-mode, translation left disabled.
;;  EE also left disabled.

; (restore-ath)		( xclient-save real-mode? -- )
paren_restore_ath:
	mfmsr	r13
	rlwinm	r13, r13, 0, 0xFFFF7FFF
	mtmsr	r13
	
	cmplwi	cr1, r29, 0				; Put real-mode? setting into cr1_gt
	lwz		r29, 0(r31)
		
	mflr	r16
	bl		ra_here
ra_here:
	mflr	r12

	lwz		r3, IV_VIRT_BASE(r22)
	lwz		r4, IV_REAL_BASE(r22)
	sub		r8, r12, r3				; convert code addr to real address
	sub		r29, r29, r3			; convert savearea to real address
	add		r8, r8, r4
	add		r29, r29, r4

	addi	r8, r8, ra_real - ra_here
	addi	r12, r12, ra_after_real - ra_here

	rlwinm	r11, r13, 0, 0xFFFFFFCF	; IR, DR off; EE already off

	align	5
	nop
	mtsrr0	r8
	mtsrr1	r11
	rfi
	
ra_real:
	lwz		r3, XCS_SDR1(r29)
	sync
	mtsdr1	r3
	isync

	addi	r3, r29, XCS_SR - 4
	lis		r4, 0x1000
	li		r10, 0
ra_sr_loop:
	lwzu	r5, 4(r3)
	isync
	mtsrin	r5, r10
	isync
	add.	r10, r10, r4
	bne		ra_sr_loop

	addi	r3, r29, XCS_BAT
	bl		load_all_bats			; trashes r4-r11

	bgt		cr1, ra_after_real		; don't turn IR, DR back on if in real-mode.
	mtsrr0	r12
	mtsrr1	r13
	rfi
	
ra_after_real:
	mtlr	r16

	lwz		r29, 4(r31)
	addi	r31, r31, 8
	blr


;; Saves the client's SDR1, BATs, and SRs into an extended client save
;;  structure.

;; Sets up SDR1, BATs, SRs, and MSR for Open Firmware's use.
;;  Disables translation, interrupts to do this, and enables
;;  translation afterward.


; (install-ath)		( xclient-save -- )
paren_install_ath:
	mfsdr1	r3
	stw		r3, XCS_SDR1(r29)

	addi	r3, r29, XCS_SR - 4
	lis		r4, 0x1000
	li		r10, 0
ia_save_sr_loop:
	mfsrin	r5, r10
	add.	r10, r10, r4
	stwu	r5, 4(r3)
	bne		ia_save_sr_loop

	mfspr	r3, ibat0u
	stw		r3, XCS_IBAT + 0x00(r29)
	mfspr	r3, ibat0l
	stw		r3, XCS_IBAT + 0x04(r29)
	mfspr	r3, ibat1u
	stw		r3, XCS_IBAT + 0x08(r29)
	mfspr	r3, ibat1l
	stw		r3, XCS_IBAT + 0x0C(r29)
	mfspr	r3, ibat2u
	stw		r3, XCS_IBAT + 0x10(r29)
	mfspr	r3, ibat2l
	stw		r3, XCS_IBAT + 0x14(r29)
	mfspr	r3, ibat3u
	stw		r3, XCS_IBAT + 0x18(r29)
	mfspr	r3, ibat3l
	stw		r3, XCS_IBAT + 0x1C(r29)

	bso		cr3, ia_save_601

	mfspr	r3, dbat0u
	stw		r3, XCS_DBAT + 0x00(r29)
	mfspr	r3, dbat0l
	stw		r3, XCS_DBAT + 0x04(r29)
	mfspr	r3, dbat1u
	stw		r3, XCS_DBAT + 0x08(r29)
	mfspr	r3, dbat1l
	stw		r3, XCS_DBAT + 0x0C(r29)
	mfspr	r3, dbat2u
	stw		r3, XCS_DBAT + 0x10(r29)
	mfspr	r3, dbat2l
	stw		r3, XCS_DBAT + 0x14(r29)
	mfspr	r3, dbat3u
	stw		r3, XCS_DBAT + 0x18(r29)
	mfspr	r3, dbat3l
	stw		r3, XCS_DBAT + 0x1C(r29)

ia_save_601:

	mflr	r16
	bl		ia_here
ia_here:
	mflr	r12

	lwz		r3, IV_VIRT_BASE(r22)
	lwz		r4, IV_REAL_BASE(r22)
	sub		r8, r12, r3					; convert code addr to real address
	add		r8, r8, r4
	
	addi	r8, r8, ia_real - ia_here
	addi	r12, r12, ia_after_real - ia_here

	lwz		r5, IV_INTERNALS(r22)		; convert internals ptr to real address
	sub		r5, r5, r3
	add		r5, r5, r4

	blt		cr4, ia_sdr1_swt			; Have SWT?

	li		r4, 1						; Form our SDR1 while the initvec is easily
	lwz		r3, IV_PT_SIZE(r22)			;  accessed.
	slw		r4, r4, r3
	subi	r4, r4, 1
	lwz		r3, IV_PT(r22)
	or		r4, r4, r3					; SDR1-to-be is in r4
	b		ia_got_my_sdr1

ia_sdr1_swt:
	lis		r4, 0xABCD					; SWT: set SDR1 = 0xABCD0000

ia_got_my_sdr1:
	mfmsr	r10							; We will set up our MSR here
	ori		r13, r10, 0x3032			; ME, IR, DR, RI, FP on later
	rlwinm	r13, r13, 0, 0xFFFF3FFF		; Let EE be off -- platform-independent
										;  code can turn it on later.
	rlwinm	r13, r13, 0, 0xFFFFF0FF		; FE0, BE, SE, FE1 off; if LE were misconfigured,
										;  we wouldn't be here. ILE, IP are configured by
										;  (install-ints)

	rlwinm	r10, r10, 0, 0xFFFF7FFF		; EE, IR, DR off now
	rlwinm	r10, r10, 0, 0xFFFFFFCF

	align 5								; r13 has our desired MSR
	nop
	mtsrr0	r8
	mtsrr1	r10
	rfi

ia_real:
	sync
	mtsdr1	r4
	isync
	stw		r4, INT_MY_SDR1(r5)			; Also set INT_MY_SDR1, which may have been
										;  purposefully invalidated by (client-maps).
										; This should be done while IR=DR=0.

	lis		r6, 0x2012					; SRx = $201275xx
	ori		r6, r6, 0x7500
	lis		r4, 0x1000
	li		r7, 0
ia_sr_loop:
	isync
	mtsrin	r6, r7
	isync
	add.	r7, r7, r4
	addi	r6, r6, 0x11
	bne		ia_sr_loop

	addi	r3, r5, INT_OF_BATS
	bl		load_all_bats				; trashes r4-r11
	
	mtsrr0	r12
	mtsrr1	r13
	rfi

ia_after_real:
	mtlr	r16
	
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

load_all_bats:	; Loads all BATs from a BAT storage block;
				;  assumes this does not affect the mapping of
				;  its code or the BAT storage block.

				; in:      r3: pointer to BAT storage block.
				;     cr3[so]: 601? 
				; trashes: r4-r11
; Format of BAT storage block:
;
;  +0x00 ibat0u/bat0u
;  +0x04 ibat0l/bat0l
;   ...
;  +0x1C ibat3l/bat3l
;  +0x20 dbat0u		[for non-601's]
;   ...
;  +0x3C dbat3l

	lwz		r4, 0x00(r3)
	lwz		r5, 0x04(r3)
	lwz		r6, 0x08(r3)
	lwz		r7, 0x0C(r3)
	lwz		r8, 0x10(r3)
	lwz		r9, 0x14(r3)
	lwz		r10, 0x18(r3)
	lwz		r11, 0x1C(r3)
	mtspr	ibat0u, r4
	isync
	mtspr	ibat0l, r5
	isync
	mtspr	ibat1u, r6
	isync
	mtspr	ibat1l, r7
	isync
	mtspr	ibat2u, r8
	isync
	mtspr	ibat2l, r9
	isync
	mtspr	ibat3u, r10
	isync
	mtspr	ibat3l, r11
	isync

	bsolr	cr3

	lwz		r4, 0x20(r3)
	lwz		r5, 0x24(r3)
	lwz		r6, 0x28(r3)
	lwz		r7, 0x2C(r3)
	lwz		r8, 0x30(r3)
	lwz		r9, 0x34(r3)
	lwz		r10, 0x38(r3)
	lwz		r11, 0x3C(r3)
	isync
	mtspr	dbat0u, r4
	isync
	mtspr	dbat0l, r5
	isync
	mtspr	dbat1u, r6
	isync
	mtspr	dbat1l, r7
	isync
	mtspr	dbat2u, r8
	isync
	mtspr	dbat2l, r9
	isync
	mtspr	dbat3u, r10
	isync
	mtspr	dbat3l, r11
	isync
	blr





ci_swapdesc:
	MAKE_EMPTY_SWD

go_swapdesc:
	MAKE_EMPTY_SWD

callback_swapdesc:
	MAKE_EMPTY_SWD
	
cx_swapdesc:
	MAKE_EMPTY_SWD

swapstore:
	ds.b		SS_SIZE
		
set_603_power:
	mfmsr	r3			; EE off
	rlwinm	r3, r3, 0, 0xFFFF7FFF
	mtmsr	r3
	isync
	
	rlwinm	r3, r3, 0, 0xFFFBFFFF
	mtmsr	r3
	isync
	
	mfspr	r4, hid0
	rlwimi	r4, r29, 21, 0x00E00000
	mtspr	hid0, r4
	isync
	
	lis		r4, 0x7FFF
	mtdec	r4
	isync
	mtdec	r4
	
	lis		r0, 0x40
	mtctr	r0
	
	ori		r4, r3, 0x8002	; Turn EE, RI on
	mtmsr	r4
	isync
	
	oris	r5, r4, 0x0004
	sync
	mtmsr	r5
	isync

s603p_wait:
	bdnz	s603p_wait

	lwz		r29, 0(r31)
	addi	r31, r31, 4
	blr

	endif
	
;;;;;; temporary mapping of segments for IO

	ifdef __MAPIO

bracket_map_io:
	
	bsolr	cr3				; 601s may leave
							; invalidate BATs 2 & 3
	li		r5, 0
	
	isync
	mtspr	dbat2u, r5
	isync
	mtspr	ibat2u, r5
	isync

	isync
	mtspr	dbat3u, r5
	isync
	mtspr	ibat3u, r5
	isync

	lis		r2, 0x6000		; Framebuffer memory
	ori		r2, r2, 0x1FFF
	lis		r1, 0x6000
	ori		r1, r1, 0x42	; Wimg
	
	isync
	mtspr	dbat2l, r1
	isync
	mtspr	dbat2u, r2
	isync

	lis		r2, 0x5000		; IO memory
	ori		r2, r2, 0x1FFF
	lis		r1, 0x5000
	ori		r1, r1, 0x2A	; wImG
	
	isync
	mtspr	dbat3l, r1
	isync
	mtspr	dbat3u, r2
	isync
	
	blr
	
	endif
	

;;;;;; debug output sc

	ifdef __DEBUG_OUT

bracket_square:
	if DEBUG_OUTPUT

	lis		r0, 0xBABA			; step marker
	ori		r0, r0, 0xA5
	sc
	
	lis		r0, 0xBABB			; high half of TOS
	rlwimi	r0, r29, 16, 16, 31
	sc
	
	lis		r0, 0xBABB			; low half of TOS
	rlwimi	r0, r29, 0, 16, 31
	sc
	
	endif
	
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	
	blr
	
	endif
	
;;;;;; hosted remnants

	ifdef __HOSTED
	
host_key:
	
	import .GetOSEvent
	
	mflr	r16
	subi	SP, SP, 0x80

hklp:
	li		r3, 0x28
	addi	r4, SP, 0x40
	bl		.GetOSEvent
	tocreload
	
	cmplwi	r3, 0
	beq		hklp

	stwu	r29, -4(r31)
	lbz		r29, 0x45(SP)
	
	addi	SP, SP, 0x80
	mtlr	r16
	blr

host_key_question:	
	import .OSEventAvail
	
	mflr	r16
	subi	SP, SP, 0x80

	li		r3, 0x28
	addi	r4, SP, 0x40
	bl		.OSEventAvail
	tocreload
	
	stwu	r29, -4(r31)
	neg		r29, r3
	
	addi	SP, SP, 0x80
	mtlr	r16
	blr
	
host_emit:	
	import .ScrollRect
	import .DrawChar
	import .MoveTo
	import .EraseRect
	
	mflr	r16
	subi	SP, SP, 0x80
	
	cmplwi	r29, 0x0A
	beq		lf
	cmplwi	r29, 0x0D
	beq		rt
	cmplwi	r29, 0x09
	beq		ta
	
	lhz		r13, 0xDFE(0)
	li		r4, 478
	mr		r3, r13
	bl		.MoveTo
	tocreload
	
	mr		r3, r29
	bl		.DrawChar
	tocreload
	
	addi	r13, r13, 6
	sth		r13, 0xDFE(0)
	b		nd
ta:
	lhz		r3, 0xDFE(0)
	li		r4, 48
	addi	r3, r3, 48
	divwu	r3, r3, r4
	mulli	r3, r3, 48
	cmplwi	r3, 0x1C0
	blt		te
	li		r3, 0
	sth		r3, 0xDFE(0)
	b		lf
te:
	sth		r3, 0xDFE(0)
	b		nd
lf:	
	lis		r3, 11
	lis		r14, 480
	stw		r3, 40(SP)
	ori		r14, r14, 512
	addi	r3, SP, 40
	stw		r14, 44(SP)
	li		r4, 0
	lis		r13, 469
	li		r5, -11
	li		r6, 0
	bl		.ScrollRect
	tocreload
	
	stw		r13, 40(SP)
	addi	r3, SP, 40
	stw		r14, 44(SP)
	bl		.EraseRect
	tocreload
	
	b		nd
rt:
	li		r0, 0
	sth		r0, 0xDFE(0)
nd:
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	addi	SP, SP, 0x80
	mtlr	r16
	blr

host_bye:
	import .fexit
	
hblp:
	bl		.fexit
	tocreload
	b		hblp
	
bracketdebug:	
	mflr	r16
	subi	SP, SP, 0x40		; Raise the stack for protection
	bl		.Debugger
	tocreload
	
	addi	SP, SP, 0x40
	mtlr	r16
	blr

; (host-read)		( addr len offset drn drvr# -- actual )
host_read:
	import .PBReadSync
	
	mflr	r16
	subi	SP, SP, 0x40

	lwz		r4, 0(r31)
	lwz		r5, 4(r31)
	lwz		r6, 8(r31)
	lwz		r7, 0xC(r31)
	
	bl		hr_here
hr_here:
	mflr	r17
	addi	r17, r17, hr_pb - hr_here
	li		r0, 0
	stw		r0, 0xC(r17)
	sth		r29, 0x18(r17)
	sth		r4, 0x16(r17)
	li		r0, 1
	sth		r0, 0x2C(r17)
	stw		r5, 0x2E(r17)
	stw		r6, 0x24(r17)
	stw		r7, 0x20(r17)
	
	mr		r3, r17
	bl		.PBReadSync
	tocreload
	
	mr.		r3, r3
	bne		hr_fail
	lwz		r29, 0x28(r17)
	
hr_exit:
	addi	r31, r31, 0x10
	addi	SP, SP, 0x40
	mtlr	r16
	blr

hr_fail:
	li		r29, 0
	b		hr_exit
hr_pb:
	ds.b	0x32
	align	4

host_alarms_store:
	import stop_alarms[RW]
	import alarm_task_ptr[RW]
	import .PrimeTime

	cmplwi	r29, 0
	lwz		r29, 0(r31)
	addi	r31, r31, 4
	bne		host_alarms_on
	
host_alarms_off:
	lwz		r3, stop_alarms[TC](RTOC)
	li		r4, -1
	stw		r4, 0(r3)
	blr

host_alarms_on:
	mflr	r0
	stw		r0, 0x8(SP)
	stwu	SP, -0x40(SP)

	lwz		r3, stop_alarms[TC](RTOC)
	li		r4, 0
	stw		r4, 0(r3)
	
	lwz		r3, alarm_task_ptr[TC](RTOC)
	li		r4, 5
	lwz		r3, 0(r3)
	bl		.PrimeTime
	tocreload
	
	lwz		r0, 0x48(SP)
	addi	SP, SP, 0x40
	mtlr	r0
	blr
	
host_ahandler_store:
	import alarm_handler[RW]
	
	lwz		r3, alarm_handler[TC](RTOC)
	stw		r29, 0(r3)
	lwz		r29, 4(r31)
	addi	r31, r31, 4
	blr
	
	impd stop_alarms
	impd alarm_task_ptr
	impd alarm_handler
	
	; void alarm_timer_handler(TMTaskPtr myTask)
	func alarm_timer_handler

	import .PrimeTime
	import alarm_handler[RW]
	import stop_alarms[RW]
	import alarm_dsp[RW]
	import alarm_rsp[RW]
	import alarm_iv[RW]
	import alarm_task_ptr[RW]
	
	mflr	r0
	stmw	r13, -0x4C(SP)
	stw		r2, -0x50(SP)
	stw		r0, 8(SP)
	stwu	SP, -0xA0(SP)
	
	lwz		r7, stop_alarms[TC](RTOC)
	lwz		r7, 0(r7)
	cmplwi	r7, 0
	bne		ahandler_end
	
	lwz		r3, alarm_task_ptr[TC](RTOC)
	lwz		r3, 0(r3)
	li		r4, alarm_granularity
	bl		.PrimeTime
	tocreload

	lwz		r22, alarm_iv[TC](RTOC)
	lwz		r22, 0(r22)
	li		r29, 0
	lwz		r30, alarm_rsp[TC](RTOC)
	lwz		r30, 0(r30)
	lwz		r31, alarm_dsp[TC](RTOC)
	lwz		r31, 0(r31)
	
	lwz		r7, alarm_handler[TC](RTOC)
	lwz		r7, 0(r7)
	cmplwi	r7, 0
	beq		ahandler_end
	mtctr	r7
	bctrl

ahandler_end:
	lwz		r0, 0xA8(SP)
	addi	SP, SP, 0xA0
	lmw		r13, -0x4C(SP)
	lwz		r2, -0x50(SP)
	mtlr	r0
	blr

host_user_abort:
	lwz		r3, IV_RSTACK_BASE(r22)
	addi	r3, r3, 0x10
	lwz		r4, alarm_rsp[TC](RTOC)
	lwz		r4, 0(r4)
hua_l:
	cmplw	r3, r4
	stwu	r29, -4(r3) 
	bgt		hua_l
	
	b		ahandler_end
	
	impd alarm_handler
	impd stop_alarms
	impd alarm_dsp
	impd alarm_rsp
	impd alarm_iv
	impd alarm_task_ptr	

	endif

;
core_end:
;

