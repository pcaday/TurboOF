; The bootstrap Forth compiler
; ----------------------------------------
;
; This tiny piece of code is rrsponsible for bootstrapping
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
;  +0  name length
;  +1  word type, OR'ed from:
;       0x01 immediate
;       0x02 primitive
;  +2  filler
;  +8  absolute address of code or compiled word
;  +16 name (16 bytes)
;
; Compiled word format:
; ---------------------
; A compiled word is just a sequence of cells, terminated by -1.
; Its values are indices into the bootstrap dictionary.
;
;

; General register assignments:

; RAX    top of stack
; RBX	 global data
; RCX	 scratch
; RDX	 scratch
; RSI	 temporary register 1
; RDI	 temporary register 2
; RBP	 data stack pointer
; RSP	 return stack pointer
; R8-R15 scratch
;

%include "x86_64-core.i"

; Bootstrapper helper functions.

; Parse a whitespace-delimited string from the Forth text, returning
;  the address and length of the string.

parse:				; (output) rcx: string-addr  rdx: string-len 
	push	rdi
	push	rax
	
	mov		rdi, [rbx+GDBootstrapForthPtr]
	mov		al, 0x20
.skip_blanks:
	scasb
	jae		.skip_blanks
	
	mov		rcx, rdi
.find_blank:
	scasb
	jb		.find_blank
	
	mov		rdx, rdi
	mov		[rbx+GDBootstrapForthPtr], rdi
	sub		rdx, rcx
	dec		rcx
	
	pop		rax
	pop		rdi
	ret


; Look up a string in the bootstrap dictionary.
find:				; (input)  rcx: string-addr  rdx: string-len
					; (output) rcx: dictionary entry ptr   rdx: dictionary entry #
	push	rsi
	push	rdi
	
	mov		r8, rcx
	mov		r9, rdx
	
	mov		rdx, [rbx+GDBootstrapDictCount]	; rdx: current entry #
	imul	r10, rdx, BDELength
	add		r10, [rbx+GDBootstrapDictBase]	; rax: pointer to current entry

	mov		rcx, r9							; get string length
.find_main_loop:
	sub		r10, BDELength
	dec		rdx
	
	; Compare word length first
	cmp		cl, [r10+BDENameLength]
	jne		.find_main_loop_next
	
	; If word length equal, compare words
	lea		rsi, [r10+BDEName]
	mov		rdi, r8
	repe cmpsb

	je		.found_word
	
	mov		rcx, r9							; reload string length
.find_main_loop_next:
	test	rdx, rdx
	jns		.find_main_loop

	; Word not found: error
.bootstrap_find_error:
	ud2
	jmp		.bootstrap_find_error
	
.found_word:
	mov		rcx, r10						; return entry ptr
											; return entry # already in rdx	
	pop		rdi
	pop		rsi
	ret

; Main bootstrap interpreter/compiler loop
;  (input)  rbx: bootstrap data structure, set up
bootstrap_main_loop:
	call	parse
	call	find
		
	; Check if this word is immediate
	mov		r8b, [rcx+BDEType]
	test	r8b, 0x01
	jnz		.main_immed
	
	; No, compile it
	mov		rcx, [rbx+GDBootstrapCompilePtr]
	mov		[rcx], rdx
	add		rcx, 8
	mov		[rbx+GDBootstrapCompilePtr], rcx
	jmp		bootstrap_main_loop

.main_immed:
	; It's an immediate word: test if it's native or compiled
	test	r8b, 0x02
	jz		.main_interp
	
	call	[rcx+BDECodePtr]				; primitive; just call it.
	jmp		bootstrap_main_loop
	
.main_interp:
	xor		rdx, rdx
	mov		rcx, [rcx+BDECodePtr]			; load interp ptr
	push	rdx								; push zero on stack
											;  when this is reached, interpreter returns to compiler
	jmp		.run_loop_entry

.run_loop:
	mov		rcx, [rbx+GDBootstrapInterpPtr]	; get interp ptr
.run_loop_entry:
	; (input) rcx: current interpreter pointer
	mov		rdx, [rcx]						; load word # and multiply by BDE length
	shl		rdx, BDELength_log2				;
	test	rdx, rdx						; check for word # -1 (= end of word)
	js		.run_done						;
	add		rcx, 8							; increment interp ptr
	mov		[rbx+GDBootstrapInterpPtr], rcx	; update interp ptr

	add		rdx, [rbx+GDBootstrapDictBase]	; load pointer to bde
	
	test	byte [rdx+BDEType], 0x02		; check if this word is native code.
	mov		rcx, [rdx+BDECodePtr]			; meanwhile, load code ptr

	jnz		.run_native
	
	push	qword [rbx+GDBootstrapInterpPtr]; push return addr on return stack
	jmp		.run_loop_entry					; rcx is already loaded to run
	
.run_native:
	call	rcx								; run ze code!
	jmp		.run_loop

.run_done:
	; Done with this word. Pop the return stack.
	pop		rcx

	; If ECX is zero, we finished the top-level word. Return
	;  to compiling!
	jrcxz	bootstrap_main_loop
	
	; Otherwise, we need to return to the calling word,
	;  and ECX is the new interpreter pointer.
	jmp		.run_loop_entry
	



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
	MakeBDEntry	lstore, 'l!', 2, 0
	MakeBDEntry	lfetch, 'l@', 2, 0
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
	push	rax
	push	rsi
	push	rdi
	
	call	parse
	xchg	rcx, rdx
	
	mov		rsi, [rbx+GDBootstrapDictCount]
	imul	rax, rsi, BDELength
	inc		rsi
	add		rax, [rbx+GDBootstrapDictBase]
	mov		[rbx+GDBootstrapDictCount], rsi

	lea		rdi, [rax+BDEName]
	mov		rsi, rdx

	mov		rdx, [rbx+GDBootstrapCompilePtr]
	
	mov		byte [rax+BDENameLength], cl
	mov		byte [rax+BDEType], 0x00
	mov		qword [rax+BDECodePtr], rdx
	rep		movsb
	
	pop		rdi
	pop		rsi
	pop		rax
	ret

; immediate (bootstrap) make last definition immediate ( -- )
immediate:
	imul	rcx, [rbx+GDBootstrapDictCount], BDELength
	add		rcx, [rbx+GDBootstrapDictBase]				; load pointer past last entry
	mov		byte [rcx-BDELength+BDEType], 0x01			; go back 1 and mark immediate
	ret

; ; (bootstrap) end definition ( -- )
semi:
	mov		rcx, [rbx+GDBootstrapCompilePtr]
	mov		qword [rcx], -1
	add		rcx, 8
	mov		[rbx+GDBootstrapCompilePtr], rcx
	ret

; in (bootstrap) get next character from Forth text	( -- char )
_in:
	mov		rcx, [rbx+GDBootstrapForthPtr]
	mov		[rbp-8], rax
	sub		rbp, 8
	movzx	rax, byte [rcx]
	inc		rcx
	mov		[rbx+GDBootstrapForthPtr], rcx
	ret

; _n (bootstrap) compile a literal     ( lit -- )
_n:
	mov		rcx, [rbx+GDBootstrapCompilePtr]
	mov		qword [rcx], ToN_BDENumber					; compile >_n
	mov		qword [rcx+8], rax
	add		rcx, 16
	mov		[rbx+GDBootstrapCompilePtr], rcx
	mov		rax, [rbp]
	add		rbp, 8
	ret

; >_n (bootstrap) load a literal from compiled word	( -- lit )
;		This is not called by bootstrap Forth code, but rather
;       compiled in by _n.
to_n:
	mov		rcx, [rbx+GDBootstrapInterpPtr]
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, [rcx]
	add		rcx, 8
	mov		[rbx+GDBootstrapInterpPtr], rcx
	ret

; General primitives

; +: add top two items on stack
_add:
	add		rax, [rbp]
	add		rbp, 8
	ret

; -: subtract top item on stack from next-to-top
_sub:
	sub		rax, [rbp]
	add		rbp, 8
	neg		rax
	ret

; *: multiply top two items on stack (low word of result)
_mul:
	imul	rax, [rbp]
	add		rbp, 8
	ret
	
; /: signed divide top item on stack into next-to-top, rounding toward zero
;     (no trapping is performed for divide by zero or 0x80000000 / -1)
_div:
	mov		rcx, rax
	mov		rax, [rbp]
	mov		rdx, rax
	add		rbp, 8
	sar		rdx, 63
	idiv	rcx
	ret

; >r: pop item off data stack and push it on the return stack
tor:
	pop		rcx
	push	rax
	mov		rax, [rbp]
	push	rcx
	add		rbp, 8
	ret

; r>: pop item off return stack and push it on the data stack
fromr:
	pop		rcx
	mov		[rbp-8], rax
	pop		rax
	sub		rbp, 8
	push	rcx
	ret

; r@: push top item of return stack onto data stack
rfetch:
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, [rsp+8]
	ret

; rpick: push i'th item (zero-based) from top of return stack onto data stack
rpick:
	mov		rax, [rsp+rax*8+8]
	ret
	
; cstore: store a byte at an address		( byte addr -- )
cstore:
	mov		rcx, [rbp]
	mov		[rax], cl
	mov		rax, [rbp+8]
	add		rbp, 16
	ret

; wstore: store doublet at an address		( word addr -- )
wstore:
	mov		rcx, [rbp]
	mov		[rax], cx
	mov		rax, [rbp+8]
	add		rbp, 16
	ret

; lstore: store quadlet at an address		( long addr -- )
lstore:
	mov		rcx, [rbp]
	mov		[rax], ecx
	mov		rax, [rbp+8]
	add		rbp, 16
	ret

; store: store a cell at an address			( cell addr -- )
store:
	mov		rcx, [rbp]
	mov		[rax], rcx
	mov		rax, [rbp+8]
	add		rbp, 16
	ret

; cfetch: load an unsigned byte from an address		( addr -- byte )
cfetch:
	movzx	rax, byte [rax]
	ret

; wfetch: load a doublet from an address			( addr -- word )
wfetch:
	movzx	rax, word [rax]
	ret

; lfetch: load a quadlet from an address			( addr -- long )
lfetch:
	mov		eax, dword [rax]
	ret

; fetch: load a cell from an address				( addr -- cell )
fetch:
	mov		rax, qword [rax]
	ret

; _1!: pop top of data stack and store in temporary register 1
_1store:
	mov		rsi, rax
	mov		rax, [rbp]
	add		rbp, 8
	ret

; _2!: pop top of data stack and store in temporary register 2
_2store:
	mov		rdi, rax
	mov		rax, [rbp]
	add		rbp, 8
	ret

; _1@: push value in temporary register 1 onto data stack
_1fetch:
	sub		rbp, 8
	mov		[rbp], rax
	mov		rax, rsi
	ret

; _2@: push value in temporary register 2 onto data stack
_2fetch:
	sub		rbp, 8
	mov		[rbp], rax
	mov		rax, rdi
	ret

; <: signed comparison of values	( a b -- (is a < b?) )
lessthan:
	cmp		rax, [rbp]
	setle	dl					; not (a < b), 0 = false, 1 = true
	add		rbp, 8
	movzx	rax, dl
	dec		rax					; (a < b),     0 = false, -1 = true
	ret

; u<: unsigned comparison of values	( a b -- (is a < b?) )
ulessthan:
	cmp		rax, [rbp]
	setbe	dl
	add		rbp, 8
	movzx	rax, dl
	dec		rax
	ret

; =: equality of values ( a b -- (does a == b?) )
equals:
	cmp		rax, [rbp]
	setne	dl
	add		rbp, 8
	movzx	rax, dl
	dec		rax
	ret

; <<: left shift ( a u -- (a << u) )
lshift:
	mov		rcx, rax
	mov		rax, [rbp]
	shl		rax, cl
	add		rbp, 8
	ret

; >>: logical right shift ( u1 u2 -- (u1 >> u2) )
rshift:
	mov		rcx, rax
	mov		rax, [rbp]
	shr		rax, cl
	add		rbp, 8
	ret

; >>a: arithmetic right shift ( u1 u2 -- (u1 >> u2) )
rshifta:
	mov		rcx, rax
	mov		rax, [rbp]
	sar		rax, cl
	add		rbp, 8
	ret

; >>r: right rotate ( u1 u2 -- (u1 >>r u2) )
rrot:
	mov		rcx, rax
	mov		rax, [rbp]
	ror		rax, cl
	add		rbp, 8
	ret

; and: logical AND top two stack values
_and:
	and		rax, [rbp]
	add		rbp, 8
	ret

; or: logical OR top two stack values
_or:
	or		rax, [rbp]
	add		rbp, 8
	ret

; xor: logical XOR top two stack values
_xor:
	xor		rax, [rbp]
	add		rbp, 8
	ret

; /mod: signed remainder and modulus  ( a b -- mod(a/b) rem(a/b) )
slashmod:
	mov		rcx, rax
	mov		rax, [rbp]
	mov		rdx, rax
	sar		rdx, 63
	idiv	rcx
	mov		[rbp], rdx
	ret

; u/mod: unsigned remainder and modulus  ( a b -- mod(a/b) rem(a/b) )
uslashmod:
	xor		rdx, rdx
	mov		rcx, rax
	mov		rax, [rbp]
	div		rcx
	mov		[rbp], rdx
	ret

; um/mod: double cell unsigned remainder and modulus ( d b -- mod(d/b) rem(d/b) )
umslashmod:
	mov		rcx, rax
	; x86 raises #DE if the divide overflows... sigh.
	;  to avoid, first reduce high half of dividend modulo divisor.
	mov		rax, [rbp]
	xor		rdx, rdx
	div		rcx

	; new high half already in rdx
	mov		rax, [rbp+8]
	div		rcx
	mov		[rbp+8], rdx
	add		rbp, 8
	ret

; um*: full unsigned multiply ( a b -- d )
umstar:
	mul		qword [rbp]			; implicit first op rdx:rax
	mov		[rbp], rax
	mov		rax, rdx
	ret

; m*: full signed multiply ( a b -- d )
mstar:
	imul	qword [rbp]			; implicit first op rdx:rax
	mov		[rbp], rax
	mov		rax, rdx
	ret

; execute: branch to execution token ( xt -- )
;	(here 64-bit mode, 64-bit XTs)
execute:
	mov		rcx, rax
	mov		rax, [rbp]
	add		rbp, 8
	jmp		rcx
	
; dsp!: pop top of data stack into data stack pointer
dspstore:
	mov		rbp, rax
	ret

; dsp@: push data stack pointer onto data stack
dspfetch:
	mov		[rbp-8], rax
	mov		rax, rbp
	sub		rbp, 8
	ret

; rsp!: pop top of data stack into return stack pointer
rspstore:
	pop		rcx
	mov		rsp, rax
	mov		rax, [rbp]
	add		rbp, 8
	jmp		rcx

; rsp@: push return stack pointer onto data stack
rspfetch:
	mov		[rbp-8], rax
	lea		rax, [rsp+8]
	sub		rbp, 8
	ret

; move: move data ( src dest len -- )
;
; len is unsigned.
move:
	push	rsi				; save off RSI/RDI
	push	rdi
	mov		rcx, rax		; load addresses and length
	mov		rsi, [rbp+8]
	mov		rdi, [rbp]
	dec		rax
	jrcxz	move_done		; whoops, no move
	cld						; prepare for forward move
	
	cmp		rsi, rdi		; compare src and dest
	ja		move_loop		; source after dest => move forward
	je		move_done		; source equals dest => done
	add		rsi, rax		; source before dest => move backward 
	add		rdi, rax
	std
move_loop:
	rep movsb
	
move_done:
	mov		rax, [rbp+16]	; pop 3 cells off stack
	add		rbp, 24
	pop		rdi				; restore RSI/RDI
	pop		rsi
	cld						; reset direction flag
	ret

; fill: fill memory with byte ( addr len byte -- )
;
; len is unsigned.
fill:
	push	rdi				; save off RDI
	cld
	mov		rcx, [rbp]
	mov		rdi, [rbp+8]
	
	jrcxz	fill_done
	
	rep stosb				; AL already has byte to fill with

fill_done:
	mov		rax, [rbp+16]
	add		rbp, 24
	pop		rdi
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
	push	rsi
	push	rdi
	mov		rcx, rax
	mov		rsi, [rbp+8]
	mov		rdi, [rbp]
	xor		rax, rax
	
	jrcxz	compeq
	
	repe cmpsb
								; flags contain the result of the last comparison
	seta	al					; handle greater than or equal cases
	jae		compdone			
	dec		rax					; less than
	
compeq:
compdone:
	pop		rdi
	pop		rsi
	add		rbp, 16
	ret
	
; flush: write back memory region to main memory	( addr len -- )
;   no-op for now -- this is used for dma-sync, so may need to be tailored
;                     to individual platforms.
flush:
	mov		rax, [rbp+8]
	add		rbp, 16
	ret
	
; <core>: get core information string			( -- addr len )
bracketcore:
	call	bcend
bcstart:
	db		'TOF x86_64core (development)'
bcend:
	pop		rcx
	mov		[rbp-8], rax
	mov		[rbp-16], rcx
	mov		rax, bcend - bcstart
	sub		rbp, 16
	ret

; ((literal)): compile machine code for putting a literal on the stack
;        			( literal addr -- newaddr )
; Generated code:
;   mov		[rbp-8], rax			48 89 45 F8
;   sub		rbp, 8					48 83 ED 08
;   mov		rax, literal			48 B8 xx xx xx xx xx xx xx xx
;     (later special case: xor rax, rax for literal zero    48 31 C0 )
pparen_literal:
	mov		rcx, [rbp]
	add		rbp, 8
	mov		dword [rax], 0xF8458948
	mov		dword [rax+4], 0x08ED8348
	mov		word [rax+8], 0xB848
	mov		qword [rax+10], rcx
	add		rax, 18
	ret

; (compile): compile machine code for calling a Forth word
;					( xt addr -- newaddr )
; Generated code:
;   mov     rcx, literal			48 B9 xx xx xx xx xx xx xx xx
;	call	rcx						FF D1
paren_compile:
	mov		rcx, [rbp]
	add		rbp, 8
	mov		word [rax], 0xB948
	mov		qword [rax+2], rcx
	mov		word [rax+10], 0xD1FF
	add		rax, 12
	ret

; (prologue): compile machine code for the prologue of a Forth word
;					( addr -- newaddr )
; Generated code:
;	nop					90
;
; Although no prologue is needed for execution on x86_64, it might be needed
;  in order for tools using decompile to find the beginning of a word.
paren_prologue:
	mov		byte [rax], 0x90
	inc		rax
	ret

; (epilogue): compile machine code for the epilogue of a Forth word
;					( addr -- newaddr )
; Generated code:
;	ret					C3
paren_epilogue:
	mov		byte [rax], 0xC3
	inc		rax
	ret
	
; (branch): compile machine code for an unconditional branch (to be resolved later)
;					( addr -- newaddr )
; Generated code:
;	jmp		(TBD)		E9 xx xx xx xx
paren_branch:
	xor		ecx, ecx
	mov		byte [rax], 0xE9
	mov		dword [rax+1], ecx
	add		rax, 5
	ret

; (f-branch): compile machine code for a branch if false (to be resolved later)
;					( addr -- newaddr )
; Generated code:
;	add		rbp, 8			48 83 C5 08
;	test	rax, rax		48 85 C0
;   mov		rax, [rbp-8]	48 8B 45 F8
;	jz		(TBD)			0F 84 xx xx xx xx
paren_f_branch:
	mov		ch, 0x84

paren_cond_branch:
	mov		cl, 0x0F
	xor		edx, edx
	mov		dword [rax],    0x08C58348
	mov		dword [rax+4],  0x48C08548
	mov		dword [rax+8],  0x0FF8458B
	mov		byte [rax+12],  ch
	mov		dword [rax+13], edx
	add		rax, 17
	ret

; (t-branch): compile machine code for a branch if true (to be resolved later)
;					( addr -- newaddr )
; Generated code:
;	add		rbp, 8			48 83 C5 08
;	test	rax, rax		48 85 C0
;   mov		rax, [rbp-8]	48 8B 45 F8
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
	mov		rcx, [rbp]
	add		rbp, 16
	sub		rax, rcx
	movsxd	rdx, eax		; Check if the offset fits in 32 bits. There are no conceivable cases currently
	cmp		rdx, rax        ;  where this will fail, but just in case...
	jne		.toolong
	mov		[rcx-4], eax
	mov		rax, [rbp-8]
	ret
.toolong:
	ud2


; /code: return instruction size granularity in bytes  ( -- n )
;   for x86_64, this is 1.
slash_code:
push_literal_1:
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, 1
	ret

; /prologue: return prologue size in bytes  ( -- n )
;   for x86_64, this is 1.
slash_prologue:
	jmp		push_literal_1

; /epilogue: return epilogue size in bytes  ( -- n )
;   for x86_64, this is 1.
slash_epilogue:
	jmp		push_literal_1

; /literal: return (maximum) size of literal code in bytes  ( -- n )
;   for x86_64, this is 18.
slash_literal:
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, 18
	ret

; /branch: return size of unconditional branch code in bytes  ( -- n )
;   for x86_64, this is 5.
slash_branch:
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, 5
	ret

; /compile: return size of word call in bytes  ( -- n )
;   for x86_64, this is 12.
slash_compile:
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, 12
	ret

; body-offset: return size of code for a create (literal + [return | unconditional branch])
;               in bytes ( -- n ). Should be a multiple of the cell size.
;   for x86_64, this is 24.
body_offset:
	mov		[rbp-8], rax
	sub		rbp, 8
	mov		rax, 24
	ret

; decompile: read compiled machine code and classify.
;   ( addr -- addr' dest	0  (word call)		48 B9 plus 10 bytes
;			| addr' n		1  (literal)		48 89 plus 16 bytes
;			| addr'			2  (prologue)		90
;			| addr'			3  (epilogue)		C3
;			| addr' dest	4  (branch)			E9 plus 4 bytes
;			| addr' dest	6  (true branch)	48 83 (10 bytes) 85 (4 bytes)
;			| addr' dest	7  (false branch)	48 83 (10 bytes) 84 (4 bytes)
;			| addr'			10 (other)											)
;   The top cell of the result indicates the type. For some types, the next cell contains more information.
;   Finally, the next address to decompile is left on the stack.
;
; decompile>: skip an instruction in compiled machine code.
;   ( addr -- addr' )

decompile_to:
	xor		rcx, rcx
	jmp		decompile_main
	
decompile:
	mov		cl, 1
	
decompile_main:
	mov		dl, byte [rax]
	cmp		dl, 0x48	; REX prefix?
	jne		decompile_decode
	inc		rax
	jmp		decompile_main

decompile_decode:
	cmp		dl, 0xB9
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
	inc		rax
	jrcxz	decompile_to_out
	mov		ch, 10
	jmp		decompile_out_1
	
decompile_call:
	add		rax, 11
	jrcxz	decompile_to_out

	mov		rdx, qword [rax-10]
	mov		ch, 0
	jmp		decompile_out_2

decompile_lit:
	add		rax, 17
	jrcxz	decompile_to_out
	
	mov		rdx, qword [rax-8]
	mov		ch, 1
	jmp		decompile_out_2

decompile_prologue:
	mov		ch, 2
	jmp		decompile_1byte

decompile_epilogue:	
	mov		ch, 3
decompile_1byte:
	inc		rax
	jrcxz	decompile_to_out
	
	jmp		decompile_out_1


decompile_to_out:				; put this code in the middle to allow for
	ret							;  short (jrcxz) jumps here.
	
decompile_cond_branch:
	mov		dl, byte [rax+11]
	sub		dl, 0x84
	cmp		dl, 0x2
	jae		decompile_other
	
	add		rax, 16
	jrcxz	decompile_to_out
	
	mov		ch, 7
	sub		ch, dl
	movsxd	rdx, dword [rax-4]
	add		rdx, rax
	jmp		decompile_out_2

decompile_branch:
	add		rax, 5
	jrcxz	decompile_to_out
	
	movsxd	rdx, dword [rax-4]
	mov		ch, 4
	add		rdx, rax

decompile_out_2:
	mov		[rbp-8], rax
	mov		[rbp-16], rdx
	sub		rbp, 16
	jmp		decompile_out_common
decompile_out_1:
	mov		[rbp-8], rax
	sub		rbp, 8
decompile_out_common:
	mov		al, ch
	movzx	rax, al
	ret


; rs>compile: convert a return stack entry into the location of the call instruction that created it.
;                                                           ( return-stack-entry -- addr )
;    for x86-64, subtract size of call instruction
rs_to_compile:
	sub		rax, 12
	ret


; exec'able: make data region executable by processor		( addr len -- )
;     a no-op for x86-64
exec_able:
	mov		rax, [rbp+8]
	add		rbp, 16
	ret


; (:-exec'able): make newly compiled Forth word executable by processor		( addr len -- )
;     a no-op for x86
paren_colon_exec_able:
	jmp		exec_able





; initvec@: retrieve entry from the initialization vector	( entry -- val )
initvecat:
	mov		rcx, [rbx+GDInitVec]
	mov		rax, [rcx+rax*8]
	ret




