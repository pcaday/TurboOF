; The bootstrap Forth compiler
; ----------------------------------------
;
; This tiny piece of code is responsible for bootstrapping
;  a (native code) second stage Forth interpreter and compiler,
;  which will then compile the final Forth interpreter/compiler.
;
; It maintains a bootstrap dictionary, whose entries are called
;  BDEs. New word definitions are stored as sequences of cells.
;
; The bootstrapper is very limited: 16-character max name lengths,
;  with no control flow instructions or literal number parsing.
;  (It can, however, load literals on the stack with the help
;   of a number parser in the bootstrap Forth code.)
;
; It does not include a Forth interpreter per se. Instead, compiled words
;  can be marked immediate, so that they will be executed when found
;  instead of compiled (as in normal Forth, except the bootstrapper
;  is always compiling).
;
; Control flow is done by changing the pointers on the return stack,
;  so the return stack behavior of the bootstrapper is important.
;  A return stack entry is just a pointer to the next code word index
;  to execute in a compiled word (see compiled word format later).
;
; Characters <= 0x20 (ASCII space) are considered blanks.
;
; Dictionary array format (entry length: 6 cells = 24 bytes)
; ----------------------------------------------------------
;  +0 name length
;  +1 word type, OR'ed from:
;      0x01 immediate
;      0x02 primitive
;  +2 filler
;  +4 absolute address of code or compiled word
;  +8 name (16 bytes)
;
; Compiled word format:
; ---------------------
; A compiled word is just a sequence of cells, terminated by -1.
; Its values are indices into the bootstrap dictionary.
;
;

; General register assignments:

; EAX   top of stack
; EBX	global data
; ECX	scratch
; EDX	scratch
; ESI	temporary register 1
; EDI	temporary register 2
; EBP	data stack pointer
; ESP	return stack pointer
;
;
; Global data structure (in EBX)
;  +0	pointer to beginning of bootstrap dictionary
;  +4	number of bootstrap dictionary entries
;  +8   bootstrap interpreter instruction pointer
;  +C   bootstrap compiler pointer
;  +10	bootstrap Forth source code pointer
;  +14  initialization vector
;  +18	system stack (hosted)


%include "x86-core.i"

; Bootstrapper helper functions.

; Parse a whitespace-delimited string from the Forth text, returning
;  the address and length of the string.

parse:				; (output) ecx: string-addr  edx: string-len 
	push	edi
	push	eax
	
	mov		edi, [ebx+GDBootstrapForthPtr]
	mov		al, 0x20
skip_blanks:
	scasb
	jae		skip_blanks
	
	mov		ecx, edi
find_blank:
	scasb
	jb		find_blank
	
	mov		edx, edi
	mov		[ebx+GDBootstrapForthPtr], edi
	sub		edx, ecx
	dec		ecx
	
	pop		eax
	pop		edi
	ret


; Look up a string in the bootstrap dictionary.
find:				; (input)  ecx: string-addr  edx: string-len
					; (output) ecx: dictionary entry ptr   edx: dictionary entry #
	push	eax
	push	esi
	push	edi
	push	ebp								; ebp: string addr
	push	edx								; store string length on stack
	
	mov		ebp, ecx
	
	mov		edx, [ebx+GDBootstrapDictCount]	; edx: current entry #
	imul	eax, edx, BDELength
	add		eax, [ebx+GDBootstrapDictBase]	; eax: pointer to current entry

	mov		ecx, [esp]						; get string length
find_main_loop:
	sub		eax, BDELength
	dec		edx
	
	; Compare word length first
	cmp		cl, [eax+BDENameLength]
	jne		find_main_loop_next
	
	; If word length equal, compare words
	lea		esi, [eax+BDEName]
	mov		edi, ebp
	repe cmpsb

	je		found_word
	
	mov		ecx, [esp]						; reload string length
find_main_loop_next:
	test	edx, edx
	jns		find_main_loop

	; Word not found: error
bootstrap_find_error:
	ud2
	jmp		bootstrap_find_error
	
found_word:
	pop		ecx								; remove string length from stack; value not used
	
	mov		ecx, eax						; return entry ptr
											; return entry # already in edx
	
	pop		ebp
	pop		edi
	pop		esi
	pop		eax
	ret

; Main bootstrap interpreter/compiler loop
;  (input)  ebx: bootstrap data structure, set up
bootstrap_main_loop:
	call	parse
	call	find
	
	; Move entry # to high half of edx
	shl		edx, 16
	
	; Check if this word is immediate
	mov		dl, [ecx+BDEType]
	test	dl, 0x01
	jnz		main_immed
	
	; No, compile it
	shr		edx, 16
	mov		ecx, [ebx+GDBootstrapCompilePtr]
	mov		[ecx], edx
	add		ecx, 4
	mov		[ebx+GDBootstrapCompilePtr], ecx
	jmp		bootstrap_main_loop

main_immed:
	; It's an immediate word: test if it's native or compiled
	test	dl, 0x02
	jz		main_interp
	
	call	[ecx+BDECodePtr]				; primitive; just call it.
	jmp		bootstrap_main_loop
	
main_interp:
	xor		edx, edx
	mov		ecx, [ecx+BDECodePtr]			; load interp ptr
	push	edx								; push zero on stack
											;  when this is reached, interpreter returns to compiler
	jmp		run_loop_entry

run_loop:
	mov		ecx, [ebx+GDBootstrapInterpPtr]	; get interp ptr
run_loop_entry:
	; (input) ecx: current interpreter pointer
	imul	edx, [ecx], BDELength			; load word # and multiply by BDE length
	test	edx, edx						; check for word # -1 (= end of word)
	js		run_done						;
	add		ecx, 4							; increment interp ptr
	mov		[ebx+GDBootstrapInterpPtr], ecx	; update interp ptr

	add		edx, [ebx+GDBootstrapDictBase]	; load pointer to bde
	
	test	byte [edx+BDEType], 0x02		; check if this word is native code.
	mov		ecx, [edx+BDECodePtr]			; meanwhile, load code ptr

	jnz		run_native
	
	push	dword [ebx+GDBootstrapInterpPtr]; push return addr on return stack
	jmp		run_loop_entry					; ecx is already loaded to run
	
run_native:
	call	ecx								; run ze code!
	jmp		run_loop

run_done:
	; Done with this word. Pop the return stack.
	pop		ecx

	; If ECX is zero, we finished the top-level word. Return
	;  to compiling!
	jecxz	bootstrap_main_loop
	
	; Otherwise, we need to return to the calling word,
	;  and ECX is the new interpreter pointer.
	jmp		run_loop_entry
	



; Bootstrap dictionary
__bcat_start:

; Base set
	MakeBDEntry	colon, ':', 1, 1
	MakeBDEntry	immediate, 'immediate', 9, 1
	MakeBDEntry	semi, ';', 1, 1
	MakeBDEntry	_in, 'in', 2, 0
	MakeBDEntry	_n, '_n', 2, 0

	%assign ToN_BDENumber (($-__bcat_start)/BDELength)

	MakeBDEntry	to_n, '>_n', 3, 0		
	MakeBDEntry	_add, '+', 1, 0
	MakeBDEntry	_sub, '-', 1, 0
	MakeBDEntry	_mul, '*', 1, 0
	MakeBDEntry	_div, '/', 1, 0
	MakeBDEntry	tor, '>r', 2, 0
	MakeBDEntry	fromr, 'r>', 2, 0
	MakeBDEntry	rfetch, 'r@', 2, 0
	MakeBDEntry	rpick, 'rpick', 5, 0
	MakeBDEntry	cstore, 'c!', 2, 0
	MakeBDEntry	cfetch, 'c@', 2, 0
	MakeBDEntry	wstore, 'w!', 2, 0
	MakeBDEntry	wfetch, 'w@', 2, 0
	MakeBDEntry	store, '!', 1, 0
	MakeBDEntry	fetch, '@', 1, 0
	MakeBDEntry	_1store, '_1!', 3, 0
	MakeBDEntry	_1fetch, '_1@', 3, 0
	MakeBDEntry	_2store, '_2!', 3, 0
	MakeBDEntry	_2fetch, '_2@', 3, 0
	MakeBDEntry	lessthan, '<', 1, 0
	MakeBDEntry	ulessthan, 'u<', 2, 0
	MakeBDEntry	equals, '=', 1, 0
	MakeBDEntry	lshift, '<<', 2, 0
	MakeBDEntry	rshift, '>>', 2, 0
	MakeBDEntry	rshifta, '>>a', 3, 0
	MakeBDEntry	rrot, '>>r', 3, 0
	MakeBDEntry	_and, 'and', 3, 0
	MakeBDEntry	_or, 'or', 2, 0
	MakeBDEntry	_xor, 'xor', 3, 0
	MakeBDEntry	slashmod, '/mod', 4, 0
	MakeBDEntry	uslashmod, 'u/mod', 5, 0
	MakeBDEntry	umslashmod, 'um/mod', 6, 0
	MakeBDEntry	umstar, 'um*', 3, 0
	MakeBDEntry	mstar, 'm*', 2, 0
	MakeBDEntry	execute, 'execute', 7, 0
	MakeBDEntry	dspstore, 'dsp!', 4, 0
	MakeBDEntry	dspfetch, 'dsp@', 4, 0
	MakeBDEntry	rspstore, 'rsp!', 4, 0
	MakeBDEntry	rspfetch, 'rsp@', 4, 0
	MakeBDEntry	move, 'move', 4, 0
	MakeBDEntry	fill, 'fill', 4, 0
	MakeBDEntry	comp, 'comp', 4, 0
	MakeBDEntry	flush, 'flush', 5, 0
	MakeBDEntry	bracketcore, '<core>', 6, 0

; Compilation
	MakeBDEntry	pparen_literal, '((literal))', 11, 0
	MakeBDEntry	paren_compile, '(compile)', 9, 0
	MakeBDEntry	paren_prologue, '(prologue)', 10, 0
	MakeBDEntry	paren_epilogue, '(epilogue)', 10, 0
	MakeBDEntry	paren_branch, '(branch)', 8, 0
	MakeBDEntry	paren_f_branch, '(f-branch)', 10, 0
	MakeBDEntry	paren_t_branch, '(t-branch)', 10, 0
	MakeBDEntry	paren_return, '(return)', 8, 0
	MakeBDEntry	paren_resolve, '(>resolve)', 10, 0
	MakeBDEntry	slash_code, '/code', 5, 0
	MakeBDEntry	slash_prologue, '/prologue', 9, 0
	MakeBDEntry	slash_epilogue, '/epilogue', 9, 0
	MakeBDEntry	slash_literal, '/literal', 8, 0
	MakeBDEntry	slash_branch, '/branch', 7, 0
	MakeBDEntry	slash_compile, '/compile', 8, 0
	MakeBDEntry	body_offset, 'body-offset', 11, 0	
	MakeBDEntry	decompile, 'decompile', 9, 0
	MakeBDEntry	decompile_to, 'decompile>', 10, 0
	MakeBDEntry	rs_to_compile, 'rs>compile', 10, 0
	
	MakeBDEntry	exec_able, "exec'able", 9, 0
	MakeBDEntry	paren_colon_exec_able, "(:-exec'able)", 13, 0

; x86 specific	
	MakeBDEntry	initvecat, 'initvec@', 8, 0

; Add any extra entries defined by a wrapper, if any.
%ifmacro ExtraBDEntries 0
	ExtraBDEntries
%endif

__bcat_end:






	

; : (bootstrap) begin definition ( -- )
colon:
	push	eax
	push	esi
	push	edi
	
	call	parse
	xchg	ecx, edx
	
	mov		esi, [ebx+GDBootstrapDictCount]
	imul	eax, esi, BDELength
	inc		esi
	add		eax, [ebx+GDBootstrapDictBase]
	mov		[ebx+GDBootstrapDictCount], esi

	lea		edi, [eax+BDEName]
	mov		esi, edx

	mov		edx, dword [ebx+GDBootstrapCompilePtr]
	
	mov		byte [eax+BDENameLength], cl
	mov		byte [eax+BDEType], 0x00
	mov		dword [eax+BDECodePtr], edx
	rep		movsb
	
	pop		edi
	pop		esi
	pop		eax
	ret

; immediate (bootstrap) make last definition immediate ( -- )
immediate:
	imul	ecx, [ebx+GDBootstrapDictCount], BDELength
	add		ecx, [ebx+GDBootstrapDictBase]				; load pointer past last entry
	mov		byte [ecx-BDELength+BDEType], 0x01			; go back 1 and mark immediate
	ret

; ; (bootstrap) end definition ( -- )
semi:
	mov		ecx, [ebx+GDBootstrapCompilePtr]
	mov		dword [ecx], -1
	add		ecx, 4
	mov		[ebx+GDBootstrapCompilePtr], ecx
	ret

; in (bootstrap) get next character from Forth text	( -- char )
_in:
	mov		ecx, [ebx+GDBootstrapForthPtr]
	mov		[ebp-4], eax
	sub		ebp, 4
	movzx	eax, byte [ecx]
	inc		ecx
	mov		[ebx+GDBootstrapForthPtr], ecx
	ret

; _n (bootstrap) compile a literal     ( lit -- )
_n:
	mov		ecx, [ebx+GDBootstrapCompilePtr]
	mov		dword [ecx], ToN_BDENumber					; compile >_n
	mov		[ecx+4], eax
	add		ecx, 8
	mov		[ebx+GDBootstrapCompilePtr], ecx
	mov		eax, [ebp]
	add		ebp, 4
	ret

; >_n (bootstrap) load a literal from compiled word	( -- lit )
;		This is not called by bootstrap Forth code, but rather
;       compiled in by _n.
to_n:
	mov		ecx, [ebx+GDBootstrapInterpPtr]
	mov		[ebp-4], eax
	sub		ebp, 4
	mov		eax, [ecx]
	add		ecx, 4
	mov		[ebx+GDBootstrapInterpPtr], ecx
	ret

; General primitives

; +: add top two items on stack
_add:
	add		eax, [ebp]
	add		ebp, 4
	ret

; -: subtract top item on stack from next-to-top
_sub:
	sub		eax, [ebp]
	add		ebp, 4
	neg		eax
	ret

; *: multiply top two items on stack (low word of result)
_mul:
	imul	eax, [ebp]
	add		ebp, 4
	ret
	
; /: signed divide top item on stack into next-to-top, rounding toward zero
;     (no trapping is performed for divide by zero or 0x80000000 / -1)
_div:
	mov		ecx, eax
	mov		eax, [ebp]
	mov		edx, eax
	add		ebp, 4
	sar		edx, 31
	idiv	ecx
	ret

; >r: pop item off data stack and push it on the return stack
tor:
	pop		ecx
	push	eax
	mov		eax, [ebp]
	push	ecx
	add		ebp, 4
	ret

; r>: pop item off return stack and push it on the data stack
fromr:
	pop		ecx
	mov		[ebp-4], eax
	pop		eax
	sub		ebp, 4
	push	ecx
	ret

; r@: push top item of return stack onto data stack
rfetch:
	mov		[ebp-4], eax
	sub		ebp, 4
	mov		eax, [esp+4]
	ret

; rpick: push i'th item (zero-based) from top of return stack onto data stack
rpick:
	mov		eax, [esp+eax*4+4]
	ret
	
; cstore: store a byte at an address		( byte addr -- )
cstore:
	mov		ecx, [ebp]
	mov		[eax], cl
	mov		eax, [ebp+4]
	add		ebp, 8
	ret

; wstore: store a word at an address		( word addr -- )
wstore:
	mov		ecx, [ebp]
	mov		[eax], cx
	mov		eax, [ebp+4]
	add		ebp, 8
	ret

; store: store a cell at an address			( cell addr -- )
store:
	mov		ecx, [ebp]
	mov		[eax], ecx
	mov		eax, [ebp+4]
	add		ebp, 8
	ret

; cfetch: load an unsigned byte from an address		( addr -- byte )
cfetch:
	movzx	eax, byte [eax]
	ret

; wfetch: load an unsigned word from an address		( addr -- word )
wfetch:
	movzx	eax, word [eax]
	ret

; fetch: load a cell from an address				( addr -- cell )
fetch:
	mov		eax, dword [eax]
	ret

; _1!: pop top of data stack and store in temporary register 1
_1store:
	mov		esi, eax
	mov		eax, [ebp]
	add		ebp, 4
	ret

; _2!: pop top of data stack and store in temporary register 2
_2store:
	mov		edi, eax
	mov		eax, [ebp]
	add		ebp, 4
	ret

; _1@: push value in temporary register 1 onto data stack
_1fetch:
	sub		ebp, 4
	mov		[ebp], eax
	mov		eax, esi
	ret

; _2@: push value in temporary register 2 onto data stack
_2fetch:
	sub		ebp, 4
	mov		[ebp], eax
	mov		eax, edi
	ret

; <: signed comparison of values	( a b -- (is a < b?) )
lessthan:
	cmp		eax, [ebp]
	setle	dl					; not (a < b), 0 = false, 1 = true
	add		ebp, 4
	movzx	eax, dl
	dec		eax					; (a < b),     0 = false, -1 = true
	ret

; u<: unsigned comparison of values	( a b -- (is a < b?) )
ulessthan:
	cmp		eax, [ebp]
	setbe	dl
	add		ebp, 4
	movzx	eax, dl
	dec		eax
	ret

; =: equality of values ( a b -- (does a == b?) )
equals:
	cmp		eax, [ebp]
	setne	dl
	add		ebp, 4
	movzx	eax, dl
	dec		eax
	ret

; <<: left shift ( a u -- (a << u) )
lshift:
	mov		ecx, eax
	mov		eax, [ebp]
	shl		eax, cl
	add		ebp, 4
	ret

; >>: logical right shift ( u1 u2 -- (u1 >> u2) )
rshift:
	mov		ecx, eax
	mov		eax, [ebp]
	shr		eax, cl
	add		ebp, 4
	ret

; >>a: arithmetic right shift ( u1 u2 -- (u1 >> u2) )
rshifta:
	mov		ecx, eax
	mov		eax, [ebp]
	sar		eax, cl
	add		ebp, 4
	ret

; >>r: right rotate ( u1 u2 -- (u1 >>r u2) )
rrot:
	mov		ecx, eax
	mov		eax, [ebp]
	ror		eax, cl
	add		ebp, 4
	ret

; and: logical AND top two stack values
_and:
	and		eax, [ebp]
	add		ebp, 4
	ret

; or: logical OR top two stack values
_or:
	or		eax, [ebp]
	add		ebp, 4
	ret

; xor: logical XOR top two stack values
_xor:
	xor		eax, [ebp]
	add		ebp, 4
	ret

; /mod: signed remainder and modulus  ( a b -- mod(a/b) rem(a/b) )
slashmod:
	mov		ecx, eax
	mov		eax, [ebp]
	mov		edx, eax
	sar		edx, 31
	idiv	ecx
	mov		[ebp], edx
	ret

; u/mod: unsigned remainder and modulus  ( a b -- mod(a/b) rem(a/b) )
uslashmod:
	xor		edx, edx
	mov		ecx, eax
	mov		eax, [ebp]
	div		ecx
	mov		[ebp], edx
	ret

; um/mod: double cell unsigned remainder and modulus ( d b -- mod(d/b) rem(d/b) )
umslashmod:
	mov		ecx, eax
	; x86 raises #DE if the divide overflows... sigh.
	;  to avoid, first reduce high half of dividend modulo divisor.
	mov		eax, [ebp]
	xor		edx, edx
	div		ecx

	; new high half already in edx
	mov		eax, [ebp+4]
	div		ecx
	mov		[ebp+4], edx
	add		ebp, 4
	ret

; um*: full unsigned multiply ( a b -- d )
umstar:
	mul		dword [ebp]			; implicit first op edx:eax
	mov		[ebp], eax
	mov		eax, edx
	ret

; m*: full signed multiply ( a b -- d )
mstar:
	imul	dword [ebp]			; implicit first op edx:eax
	mov		[ebp], eax
	mov		eax, edx
	ret

; execute: branch to execution token ( xt -- )
;	(here 32-bit mode, 32-bit XTs)
execute:
	mov		ecx, eax
	mov		eax, [ebp]
	add		ebp, 4
	jmp		ecx
	
; dsp!: pop top of data stack into data stack pointer
dspstore:
	mov		ebp, eax
	ret

; dsp@: push data stack pointer onto data stack
dspfetch:
	mov		[ebp-4], eax
	mov		eax, ebp
	sub		ebp, 4
	ret

; rsp!: pop top of data stack into return stack pointer
rspstore:
	pop		ecx
	mov		esp, eax
	mov		eax, [ebp]
	add		ebp, 4
	jmp		ecx
;	push	ecx				; don't push anything onto the rstack
;	ret						; throw sets the rstack into an area with no space.

; rsp@: push return stack pointer onto data stack
rspfetch:
	mov		[ebp-4], eax
	lea		eax, [esp+4]
	sub		ebp, 4
	ret

; move: move data ( src dest len -- )
;
; len is unsigned.
move:
	push	esi				; save off ESI/EDI
	push	edi
	mov		ecx, eax		; load addresses and length
	mov		esi, [ebp+4]
	mov		edi, [ebp]
	dec		eax
	jecxz	move_done		; whoops, no move
	cld						; prepare for forward move
	
	cmp		esi, edi		; compare src and dest
	ja		move_loop		; source after dest => move forward
	je		move_done		; source equals dest => done
	add		esi, eax		; source before dest => move backward 
	add		edi, eax
	std
move_loop:
	rep movsb
	
move_done:
	mov		eax, [ebp+8]	; pop 3 cells off stack
	add		ebp, 12
	pop		edi				; restore ESI/EDI
	pop		esi
	cld						; reset direction flag
	ret

; fill: fill memory with byte ( addr len byte -- )
;
; len is unsigned.
fill:
	push	edi				; save off EDI
	cld
	mov		ecx, [ebp]
	mov		edi, [ebp+4]
	
	jecxz	fill_done
	
	rep stosb				; AL already has byte to fill with

fill_done:
	mov		eax, [ebp+8]
	add		ebp, 12
	pop		edi
	ret

; comp: compare memory regions byte-by-byte (unsigned)		( addr1 addr2 len -- -1|0|1 )
;
; Result code indicates how the regions compare:
;         1:  addr1,len > addr2,len
;         0:  addr1,len = addr2,len
;        -1:  addr1,len < addr2,len
;
; len is unsigned.
comp:
	cld
	push	esi
	push	edi
	mov		ecx, eax
	mov		esi, [ebp+4]
	mov		edi, [ebp]
	xor		eax, eax
	
	jecxz	compeq
	
	repe cmpsb
								; flags contain the result of the last comparison
	seta	al					; handle greater than or equal cases
	jae		compdone			
	dec		eax					; less than
	
compeq:
compdone:
	pop		edi
	pop		esi
	add		ebp, 8
	ret
	
; flush: write back memory region to main memory	( addr len -- )
;   no-op for now -- this is used for dma-sync, so may need to be tailored
;                     to individual platforms.
flush:
	mov		eax, [ebp+4]
	add		ebp, 8
	ret
	
; <core>: get core information string			( -- addr len )
bracketcore:
	call	bcend
bcstart:
	db		'TOF x86core (development)'
bcend:
	pop		ecx
	mov		[ebp-4], eax
	mov		[ebp-8], ecx
	mov		eax, bcend - bcstart
	sub		ebp, 8
	ret

; ((literal)): compile machine code for putting a literal on the stack
;        			( literal addr -- newaddr )
; Generated code:
;   mov		[ebp-4], eax			89 45 FC
;   sub		ebp, 4					83 ED 04
;   mov		eax, literal			B8 xx xx xx xx
;     (later special case: xor eax, eax for literal zero    31 C0 )
pparen_literal:
	mov		ecx, [ebp]
	add		ebp, 4
	mov		dword [eax], 0x83FC4589
	mov		dword [eax+4], 0x00B804ED
	mov		dword [eax+7], ecx
	add		eax, 11
	ret

; (compile): compile machine code for calling a Forth word
;					( xt addr -- newaddr )
; Generated code:
;	call	(relative addr of xt)	E8 displacement
paren_compile:
	mov		ecx, [ebp]
	add		eax, 5
	add		ebp, 4
	sub		ecx, eax
	mov		byte [eax-5], 0xE8
	mov		dword [eax-4], ecx
	ret

; (prologue): compile machine code for the prologue of a Forth word
;					( addr -- newaddr )
; Generated code:
;	nop					90
;
; Although no prologue is needed for execution on x86, it might be needed
;  in order for tools using decompile to find the beginning of a word.
paren_prologue:
	mov		byte [eax], 0x90
	inc		eax
	ret

; (epilogue): compile machine code for the epilogue of a Forth word
;					( addr -- newaddr )
; Generated code:
;	ret					C3
paren_epilogue:
	mov		byte [eax], 0xC3
	inc		eax
	ret
	
; (branch): compile machine code for an unconditional branch (to be resolved later)
;					( addr -- newaddr )
; Generated code:
;	jmp		(TBD)		E9 xx xx xx xx
paren_branch:
	xor		ecx, ecx
	mov		byte [eax], 0xE9
	mov		dword [eax+1], ecx
	add		eax, 5
	ret

; (f-branch): compile machine code for a branch if false (to be resolved later)
;					( addr -- newaddr )
; Generated code:
;	add		ebp, 4			83 C5 04
;	test	eax, eax		85 C0
;   mov		eax, [ebp-4]	8B 45 FC
;	jz		(TBD)			0F 84 xx xx xx xx
paren_f_branch:
	mov		ch, 0x84

paren_cond_branch:
	mov		cl, 0x0F
	xor		edx, edx
	mov		dword [eax],    0x8504C583
	mov		dword [eax+4],  0xFC458BC0
	mov		 word [eax+8],  cx
	mov		dword [eax+10], edx
	add		eax, 14
	ret

; (t-branch): compile machine code for a branch if true (to be resolved later)
;					( addr -- newaddr )
; Generated code:
;	add		ebp, 4			83 C5 04
;	test	eax, eax		85 C0
;   mov		eax, [ebp-4]	8B 45 FC
;	jnz		(TBD)			0F 85 xx xx xx xx
paren_t_branch:
	mov		ch, 0x85
	jmp		paren_cond_branch

; (return):
paren_return:
	jmp		paren_epilogue

; (>resolve): resolve a previously compiled conditional or unconditional branch
;					( addr-after-branch branch-to-addr -- )
paren_resolve:
	; In all cases, the offset is stored at the end of the branching instructions.
	mov		ecx, [ebp]
	add		ebp, 8
	sub		eax, ecx
	mov		[ecx-4], eax
	mov		eax, [ebp-4]
	ret


; /code: return instruction size granularity in bytes  ( -- n )
;   for x86, this is 1.
slash_code:
push_literal_1:
	mov		[ebp-4], eax
	sub		ebp, 4
	mov		eax, 1
	ret

; /prologue: return prologue size in bytes  ( -- n )
;   for x86, this is 1.
slash_prologue:
	jmp		push_literal_1

; /epilogue: return epilogue size in bytes  ( -- n )
;   for x86, this is 1.
slash_epilogue:
	jmp		push_literal_1

; /literal: return (maximum) size of literal code in bytes  ( -- n )
;   for x86, this is 11.
slash_literal:
	mov		[ebp-4], eax
	sub		ebp, 4
	mov		eax, 11
	ret

; /branch: return size of unconditional branch code in bytes  ( -- n )
;   for x86, this is 5.
slash_branch:
push_literal_5:
	mov		[ebp-4], eax
	sub		ebp, 4
	mov		eax, 5
	ret

; /compile: return size of word call in bytes  ( -- n )
;   for x86, this is 5.
slash_compile:
	jmp		push_literal_5

; body-offset: return size of code for a create (literal + [return | unconditional branch])
;               in bytes ( -- n ). Should be a multiple of the cell size.
;   for x86, this is 16.
body_offset:
	mov		[ebp-4], eax
	sub		ebp, 4
	mov		eax, 16
	ret

; decompile: read compiled machine code and classify.
;   ( addr -- addr' dest	0  (word call)		E8 plus 4 bytes
;			| addr' n		1  (literal)		89 plus 10 bytes
;			| addr'			2  (prologue)		90
;			| addr'			3  (epilogue)		C3
;			| addr' dest	4  (branch)			E9 plus 4 bytes
;			| addr' dest	6  (true branch)	83 (8 bytes) 85 (4 bytes)
;			| addr' dest	7  (false branch)	83 (8 bytes) 84 (4 bytes)
;			| addr'			10 (other)											)
;   The top cell of the result indicates the type. For some types, the next cell contains more information.
;   Finally, the next address to decompile is left on the stack.
;
; decompile>: skip an instruction in compiled machine code.
;   ( addr -- addr' )

decompile_to:
	xor		ecx, ecx
	jmp		decompile_main
	
decompile:
	mov		cl, 1
	
decompile_main:
	mov		dl, byte [eax]
	cmp		dl, 0xE8
	je		decompile_call
	cmp		dl, 0x89
	je		decompile_lit
	cmp		dl, 0x83
	je		decompile_cond_branch
	cmp		dl, 0xE9
	je		decompile_branch
	cmp		dl, 0x90
	je		decompile_prologue
	cmp		dl, 0xC3
	je		decompile_epilogue
	
decompile_other:		; unrecognized
	inc		eax
	jecxz	decompile_to_out
	mov		ch, 10
	jmp		decompile_out_1
	
decompile_call:
	add		eax, 5
	jecxz	decompile_to_out

	mov		edx, [eax-4]
	mov		ch, 0
	add		edx, eax
	jmp		decompile_out_2

decompile_lit:
	add		eax, 11
	jecxz	decompile_to_out
	
	mov		edx, [eax-4]
	mov		ch, 1
	jmp		decompile_out_2

decompile_prologue:
	mov		ch, 2
	jmp		decompile_1byte

decompile_epilogue:	
	mov		ch, 3
decompile_1byte:
	inc		eax
	jecxz	decompile_to_out
	
	jmp		decompile_out_1


decompile_to_out:				; put this code in the middle to allow for
	ret							;  short (jecxz) jumps here.
	
decompile_cond_branch:
	mov		dl, byte [eax+9]
	sub		dl, 0x84
	cmp		dl, 0x2
	jae		decompile_other
	
	add		eax, 14
	jecxz	decompile_to_out
	
	mov		ch, 7
	sub		ch, dl
	mov		edx, [eax-4]
	add		edx, eax
	jmp		decompile_out_2

decompile_branch:
	add		eax, 5
	jecxz	decompile_to_out
	
	mov		edx, [eax-4]
	mov		ch, 4
	add		edx, eax

decompile_out_2:
	mov		[ebp-4], eax
	mov		[ebp-8], edx
	sub		ebp, 8
	jmp		decompile_out_common
decompile_out_1:
	mov		[ebp-4], eax
	sub		ebp, 4
decompile_out_common:
	movzx	eax, ch
	ret


; rs>compile: convert a return stack entry into the location of the call instruction that created it.
;                                                           ( return-stack-entry -- addr )
;    for x86, subtract size of call instruction
rs_to_compile:
	sub		eax, 5
	ret


; exec'able: make data region executable by processor		( addr len -- )
;     a no-op for x86
exec_able:
	mov		eax, [ebp+4]
	add		ebp, 8
	ret


; (:-exec'able): make newly compiled Forth word executable by processor		( addr len -- )
;     a no-op for x86
paren_colon_exec_able:
	jmp		exec_able





; initvec@: retrieve entry from the initialization vector	( entry -- val )
initvecat:
	mov		ecx, [ebx+GDInitVec]
	mov		eax, [ecx+eax*4]
	ret




