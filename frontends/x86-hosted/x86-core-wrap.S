; Wrapper around x86-core for a hosted build.

%include "x86-core-wrap.i"
%include "x86-core.i"






section .text

	; Memory Layout of *fmem
	;
	;  +0		Bootstrap dictionary			(room for 0x100 definitions)
	;  +0x1800	Bootstrap compiled code storage	(room for 0x400 tokens)
	;  +0x2800-0x37FF Data stack
	;  +0x37C0	Data stack base					(top of data stack area - 0x40 underflow buffer)
	;  +0x3800-0x47FF Return stack
	;  +0x47C0  Return stack base				(top of return stack area - 0x40 underflow buffer)
	;  +0x4800	Init vector
	;  +0x4900  Global data
	;  +0x4A00  Forth data area
	;   .
	;   .
	;   .
	;  end		Alloc-mem base (grows backwards)
	

; void fentry(void *fmem, unsigned int fmem_len, void *text);
global fentry
fentry:
	push	ebp
	mov		ebp, esp						; Make a stack frame in case C cares

	push	sys_ctx
	call	savetocontext					; Save registers to system context

	
	mov		ebp, [esp+8]					; fmem
	mov		ecx, [esp+12]					; fmem_len
	mov		edx, [esp+16]					; text
	
	lea		ebx, [ebp+FMemGlobalData]		; global data struct
	lea		edi, [ebp+FMemInitVec]			; init vector

	lea		esi, [ebp+FMemBootstrapCode]
	mov		[ebx+GDBootstrapCompilePtr], esi

	mov		[ebx+GDBootstrapForthPtr], edx
	mov		[ebx+GDInitVec], edi
	mov		[ebx+GDSignalHandler], dword 0
	
	sub		esp, 0x40						; Put some space on stack...
	and		esp, ~0xF						;  16-byte align it...
	mov		[ebx+GDSystemStack], esp		;  and save it.
	
	lea		esi, [ebp+FMemForthData]
	mov		[edi+IVDataBase], esi
	lea		esi, [ebp+FMemBootstrapDict]
	mov		[edi+IVBDBase], esi
	mov		[edi+IVFTextBase], edx
	mov		[edi+IVRealSize], ecx
	mov		[edi+IVVirtSize], ecx
	add		ecx, ebp						; get end of fmem
	mov		[edi+IVAMBase], ecx
	mov		[edi+IVRealBase], ebp
	mov		[edi+IVVirtBase], ebp
	mov		[edi+IVGlobalData], ebx
	
	
	; Copy bootstrap dictionary
	mov		edx, __bcat_start				; Get absolute address of stored bootstrap dictionary
											; The code pointers in the dictionary are also relative to this address.
	mov		esi, edx
	lea		edi, [ebp+FMemBootstrapDict]
	mov		ecx, BDECount
	cld
	
	mov		[ebx+GDBootstrapDictBase], edi
	mov		[ebx+GDBootstrapDictCount], ecx
	
bd_copy_loop:
	movsd									; Name length and type fields
	lodsd									; Code pointer field
	add		eax, edx						;	convert code pointer to absolute address
	stosd
	movsd									; Name (16 bytes)
	movsd
	movsd
	movsd
	loop	bd_copy_loop
	
	; Initialize stacks
	lea		edi, [ebp+FMemInitVec]			; reload init vector

	lea		esp, [ebp+FMemRStackBase]
	lea		ebp, [ebp+FMemStackBase]		; yes, it's an add

	mov		[edi+IVStackBase], ebp
	mov		[edi+IVRStackBase], esp
	
	add		ebp, 4
	xor		esi, esi
	xor		edi, edi
	mov		eax, 0xBEEFCAFE
	
	mov		dword [inforth], 0xFFFFFFFF
	
	; The Forth context is ready. Save it!
	push	forth_ctx
	call	savetocontext
	
;	call	bracketdump
	
	jmp		bootstrap_main_loop


loadcontext:
	; Input:
	;			---------------
	;			new context ptr
	;			---------------
	;			bitmask of registers to leave
	;			---------------
	;			return addr
	;	esp ->	---------------
	or		dword [esp+4], IsLoad
	jmp		loadcontext_in

savetocontext:
	; Input:
	;			---------------
	;			context ptr
	;			---------------
	;			return addr
	;	esp ->	---------------
	
	; Just call swaptocontext with the context ptr as old and new contexts.
	sub		esp, 8					; make space
	push	eax
	
	mov		eax, [esp+12]			; move return addr down
	mov		[esp+4], eax
	mov		eax, [esp+16]			; duplicate context ptr
	mov		[esp+12], eax
	mov		dword [esp+8], 0		; any bitmask is OK really
	
	pop		eax
	; fall through

swaptocontext:
	; Input:
	;			---------------
	;			old context ptr
	;			---------------
	;			new context ptr
	;			---------------
	;			flags
	;			---------------
	;			return addr
	;	esp ->	---------------
	push	ebp
	
	mov		ebp, [esp+0x10]					; old context ptr
	mov		[ebp+Cedi], edi					; save EDI
	mov		edi, [esp+0x08]					; load EDI with flags
	
	test	edi, NoSaveEAX					; save general purpose regs according to flags
	jnz		.noeax
	mov		[ebp+Ceax], eax
.noeax:
	test	edi, NoSaveEBX
	jnz		.noebx
	mov		[ebp+Cebx], ebx
.noebx:
	test	edi, NoSaveECX
	jnz		.noecx
	mov		[ebp+Cecx], ecx
.noecx:
	test	edi, NoSaveEDX
	jnz		.noedx
	mov		[ebp+Cedx], edx
.noedx:
	test	edi, NoSaveESI
	jnz		.noesi
	mov		[ebp+Cesi], esi
.noesi:
	test	edi, NoSaveEBP
	jnz		.noebp
	pop		dword [ebp+Cebp]
	jmp		.ebpdone
.noebp:
	add		esp, 4							; drop
.ebpdone:
	test	edi, NoSaveESP
	jnz		.noesp
	lea		esi, [esp+0x10]					; stack ptr before swapto
	mov		[ebp+Cesp], esi
.noesp:

loadcontext_in:
	pop		esi								; return addr
	pop		edi								; flags (already in EDI...)
	pop		ebp								; new context ptr

	test	edi, LeaveEAX
	jnz		.noeax
	mov		eax, [ebp+Ceax]
.noeax:
	test	edi, LeaveEBX
	jnz		.noebx
	mov		ebx, [ebp+Cebx]
.noebx:
	test	edi, LeaveECX
	jnz		.noecx
	mov		ecx, [ebp+Cecx]
.noecx:
	test	edi, LeaveEDX
	jnz		.noedx
	mov		edx, [ebp+Cedx]
.noedx:
	test	edi, LeaveESP
	jnz		.noesp
	mov		esp, [ebp+Cesp]
	jmp		.espdone
.noesp:
	test	edi, IsLoad						; pop old ctx if swapping and
	jnz		.espdone						;  keeping stack
	add		esp, 4
.espdone:

	push	esi								; stuff return addr on new stack
	
	mov		esi, [ebp+Cesi]	
	mov		edi, [ebp+Cedi]
	mov		ebp, [ebp+Cebp]
	
	ret

; Re-enter Forth after a signal.
; void freentry(int reentry_cause, int *reentry_data)
global freentry
freentry:
	pop		edx								; drop
	pop		ecx								; ecx: reentry_cause
	pop		edx								; edx: reentry_data

	; Swap back to Forth context, dragging ECX and EDX with us
	push	sys_ctx
	push	forth_ctx
	push	dword LeaveECX | LeaveEDX
	call	swaptocontext

	; Push arguments to signal handler onto data stack:
	;   ( data0 data1 cause )
	mov		[ebp-0x4], eax
	mov		eax, ecx
	
	mov		ecx, [edx]
	mov		[ebp-0x8], ecx
	mov		ecx, [edx+4]
	mov		[ebp-0xC], ecx
	
	sub		ebp, 0xC

	; Call Forth handler, if defined
	mov		ecx, [ebx+GDSignalHandler]
	jecxz	.nohandler
	call	ecx
	
	; No handler or handler returned? Exit.
.nohandler:
	jmp		paren_host_bye



; Raw POSIX signal handler.
; void sighandler(int sig, siginfo_t *siginfo, ucontext_t *uap)
global sighandler
extern c_sighandler
extern abort

sighandler:
	; We arrive either from Forth or from a system call.
	; If from Forth, load system context first; also need to move args to system stack
	; Either way, ECX and EDX should be safe to use.
	
	; Check if in Forth
	mov		edx, dword [inforth]
	test	edx, edx
	mov		ecx, esp			; save stack pointer
	jz		.notforth
	
	; Load system context if so. Don't save Forth context as the signal handler
	;  has trashed registers.
	
	push	sys_ctx
	push	dword LeaveECX | LeaveEDX
	call	loadcontext
	
	mov		dword [inforth], 0

.notforth:	
	and		esp, -16			; align stack...
	sub		esp, 12
	push	ecx					; save old stack pointer in case handler returns
	
	push	dword [ecx+0xC]		; repush args
	push	dword [ecx+0x8]
	push	dword [ecx+0x4]
	push	edx					; plus, an additional first arg indicating whether we were in Forth

	; OK, args are ready for the C signal handler
	; void c_sighandler(int wasInForth, int sig, siginfo_t *siginfo, ucontext_t *uap)
	call	c_sighandler
	
	; The C signal handler returned. Restore old stack pointer and return.
	mov		esp, [esp+16]
	ret

; Hosted primitives for I/O and debugging
;
; Each of these are wrappers around corresponding C functions that actually do the
;  work. They are responsible for swapping from the Forth context to the system
;  context, calling the C routine, then swapping back to the Forth context.

%macro	ExtraBDEntries 0
	MakeBDEntry	bracketdebug, '<debug>', 7, 0
	MakeBDEntry	bracketdump, '<dump>', 6, 0
	MakeBDEntry	bracketctx, '<ctx>', 5, 0
	MakeBDEntry	paren_host_bye, '(host-bye)', 10, 0
	MakeBDEntry	paren_host_key_question, '(host-key?)', 11, 0
	MakeBDEntry	paren_host_key, '(host-key)', 10, 0
	MakeBDEntry	paren_host_emit, '(host-emit)', 11, 0
	MakeBDEntry	paren_host_rest, '(host-rest)', 11, 0
	MakeBDEntry	paren_host_is_window, '(host-is-win)', 13, 0
%endmacro


extern c_host_key
extern c_host_key_question
extern c_host_emit
extern c_host_rest
extern c_host_bye
extern c_host_is_window
extern c_dump

; (host-key): get the next character (waiting if necessary) from the keyboard     ( -- char )
paren_host_key:
	mov		[ebp-4], eax
	sub		ebp, 4
	
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveNone
	call	swaptocontext
	
	and		esp, -16
	call	c_host_key
	movzx	eax, al
	
	push	sys_ctx
	push	forth_ctx
	push	dword LeaveEAX | NoSaveESP
	call	swaptocontext

	mov		dword [inforth], -1
	
	ret


; (host-key?): return if a character has been pressed      ( -- key? )
paren_host_key_question:
	mov		[ebp-4], eax
	sub		ebp, 4
	
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveNone
	call	swaptocontext
	
	and		esp, -16
	call	c_host_key_question
	movzx	eax, al
	neg		eax
	
	push	sys_ctx
	push	forth_ctx
	push	dword LeaveEAX | NoSaveESP
	call	swaptocontext

	mov		dword [inforth], -1
	
	ret


; (host-emit): output a character							( char -- )
paren_host_emit:
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveEAX
	call	swaptocontext
	
	and		esp, -16
	sub		esp, 12
	push	eax
	call	c_host_emit
	
	push	sys_ctx
	push	forth_ctx
	push	dword NoSaveESP
	call	swaptocontext
	mov		dword [inforth], -1

	mov		eax, [ebp]
	add		ebp, 4	
	ret
	

; (host-bye): exit to shell									( -- )
paren_host_bye:
	; Swap out of Forth context
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveEAX
	call	swaptocontext
	
	; Align and call C code
	and		esp, -16
	call	c_host_bye
	
	; _c_host_bye should not return; if so...
	call	abort


; <dump>:	dump current state								( -- )
bracketdump:
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveEAX
	call	swaptocontext
		
	and		esp, -16
	sub		esp, 8

	push	dword [forth_ctx + Cebx]
	push	dword [forth_ctx + Cesp]
	push	dword [forth_ctx + Cebp]
	push	dword [forth_ctx + Cedi]
	push	dword [forth_ctx + Cesi]
	push	eax

	call	c_dump	
		
	push	sys_ctx
	push	forth_ctx
	push	dword NoSaveESP
	call	swaptocontext
	mov		dword [inforth], -1

	ret


; (host-rest): wait for a short period of time for user input to occur			( -- )
paren_host_rest:
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveNone
	call	swaptocontext
		
	and		esp, -16

	call	c_host_rest
		
	push	sys_ctx
	push	forth_ctx
	push	dword NoSaveESP
	call	swaptocontext
	mov		dword [inforth], -1

	ret

; (host-is-window): provide pointers to #lines and #columns			( #l #c -- )
paren_host_is_window:
	mov		ecx, [ebp]
	
	mov		dword [inforth], 0
	push	forth_ctx
	push	sys_ctx
	push	dword LeaveEAX | LeaveECX
	call	swaptocontext
	
	and		esp, -16
	sub		esp, 8
	push	eax
	push	ecx
	call	c_host_is_window
	
	push	sys_ctx
	push	forth_ctx
	push	dword NoSaveESP
	call	swaptocontext
	mov		dword [inforth], -1

	mov		eax, [ebp+4]
	add		ebp, 8
	ret


; <debug>:	enter debugger										( -- )
bracketdebug:
	int3
	ret
	

; <ctx>:	return pointer to either Forth or system context	( sys? -- ptr )
bracketctx:
	test	eax, eax
	jnz		.sysctx
	mov		eax, forth_ctx
	ret
.sysctx:
	mov		eax, sys_ctx
	ret


; ----------------------
; Common core
; ----------------------
%include "x86-core.S"


; ----------------------
; Data for x86-core-wrap
; ----------------------

section .bss

global forth_ctx
global sys_ctx

; Context storage
forth_ctx:
	resb ContextSize 
sys_ctx:
	resb ContextSize

; Flag whether we're in Forth code
inforth:
	resd 1




