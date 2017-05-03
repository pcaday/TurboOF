; Wrapper around x86-core for a hosted build.

%include "x86_64-core-wrap.i"
%include "x86_64-core.i"

section .text

	; Memory Layout of *fmem
	;
	;  +0		Bootstrap dictionary			(room for 0x100 definitions)
	;  +0x2000	Bootstrap compiled code storage	(room for 0x400 tokens)
	;  +0x4000-0x5FFF Data stack				(can overwrite bootstrap area once finished)
	;  +0x5F80	Data stack base					(top of data stack area - 0x80 underflow buffer)
	;  +0x6000-0x7FFF Return stack
	;  +0x7F80  Return stack base				(top of return stack area - 0x80 underflow buffer)
	;  +0x8000	Init vector
	;  +0x8100  Global data
	;  +0x8200  Forth data area
	;   .
	;   .
	;   .
	;  end		Alloc-mem base (grows backwards)
	

; void fentry(void *fmem, unsigned int fmem_len, void *text);
global fentry
fentry:
	push	rbp
	mov		rbp, rsp						; Make a stack frame in case C cares

	lea		r11, [sys_ctx]
	push	r11
	call	savetocontext					; Save registers to system context

	; r8: fmem, r9: fmem_len, r10: text
	%ifdef WINDOWS
	mov		r10, r8
	mov		r8, rcx
	mov		r9d, edx
	%else
	mov		r8, rdi
	mov		r9d, esi
	mov		r10, rdx
	%endif
	
	lea		rbx, [r8+FMemGlobalData]		; global data struct
	lea		rdi, [r8+FMemInitVec]			; init vector

	lea		rsi, [r8+FMemBootstrapCode]
	mov		[rbx+GDBootstrapCompilePtr], rsi

	mov		[rbx+GDBootstrapForthPtr], r10
	mov		[rbx+GDInitVec], rdi
	mov		qword [rbx+GDSignalHandler], 0
	
	sub		rsp, 0x80						; Put some space on stack...
	and		rsp, ~0xF						;  16-byte align it...
	mov		[rbx+GDSystemStack], rsp		;  and save it.
	
	lea		rsi, [r8+FMemForthData]
	mov		[rdi+IVDataBase], rsi
	lea		rsi, [r8+FMemBootstrapDict]
	mov		[rdi+IVBDBase], rsi
	mov		[rdi+IVFTextBase], r10
	mov		[rdi+IVRealSize], r9
	mov		[rdi+IVVirtSize], r9
	add		r9, r8							; get end of fmem
	mov		[rdi+IVAMBase], r9
	mov		[rdi+IVRealBase], r8
	mov		[rdi+IVVirtBase], r8
	mov		[rdi+IVGlobalData], rbx
	
	mov		r11, rdi
	
	; Copy bootstrap dictionary
	lea		rsi, [__bcat_start]				; Get absolute address of stored bootstrap dictionary
											; The code pointers in the dictionary are also relative to this address.
	mov		rdx, rsi
	lea		rdi, [r8+FMemBootstrapDict]
	mov		rcx, BDECount
	cld
	
	mov		[rbx+GDBootstrapDictBase], rdi
	mov		[rbx+GDBootstrapDictCount], rcx
	
.bd_copy_loop:
	movsq									; Name length and type fields
	lodsq									; Code pointer field
	add		rax, rdx						;	convert code pointer to absolute address
	stosq
	movsq									; Name (16 bytes)
	movsq
	loop	.bd_copy_loop
	
	; Initialize stacks
	lea		rsp, [r8+FMemRStackBase]
	lea		rbp, [r8+FMemStackBase]

	mov		[r11+IVStackBase], rbp
	mov		[r11+IVRStackBase], rsp
	
	add		rbp, 8
	xor		rsi, rsi
	xor		rdi, rdi
	mov		rax, 0xBEADFACEBEEFCAFE
	
	mov		qword [inforth], -1
	
	; The Forth context is ready. Save it!
	lea		r11, [forth_ctx]
	push	r11
	call	savetocontext
	
;	call	bracketdump
	
	jmp		bootstrap_main_loop


loadcontext:
	; Input:
	;			---------------
	;			new context ptr
	;			---------------
	;			bitmask of registers to leave (qword)
	;			---------------
	;			return addr
	;	rsp ->	---------------
	or		qword [rsp+8], IsLoad
	jmp		loadcontext_in

savetocontext:
	; Input:
	;			---------------
	;			context ptr
	;			---------------
	;			return addr
	;	rsp ->	---------------
	
	; Just call swaptocontext with the context ptr as old and new contexts.
	sub		rsp, 16					; make space
	push	rax
	
	mov		rax, [rsp+0x18]			; move return addr down
	mov		[rsp+8], rax
	mov		rax, [rsp+0x20]			; duplicate context ptr
	mov		[rsp+0x18], rax
	mov		qword [rsp+0x10], 0		; any bitmask is OK really
	
	pop		rax
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
	;	rsp ->	---------------
	push	rbp
	
	mov		rbp, [rsp+0x20]					; old context ptr
	mov		[rbp+Ctx_rdi], rdi				; save RDI
	mov		rdi, [rsp+0x10]					; load RDI with flags
	
	test	edi, NoSaveRAX					; save general purpose regs according to flags
	jnz		.norax
	mov		[rbp+Ctx_rax], rax
.norax:
	test	edi, NoSaveRBX
	jnz		.norbx
	mov		[rbp+Ctx_rbx], rbx
.norbx:
	test	edi, NoSaveRCX
	jnz		.norcx
	mov		[rbp+Ctx_rcx], rcx
.norcx:
	test	edi, NoSaveRDX
	jnz		.nordx
	mov		[rbp+Ctx_rdx], rdx
.nordx:
	test	edi, NoSaveRSI
	jnz		.norsi
	mov		[rbp+Ctx_rsi], rsi
.norsi:
	test	edi, NoSaveRBP
	jnz		.norbp
	pop		qword [rbp+Ctx_rbp]
	jmp		.rbpdone
.norbp:
	add		rsp, 4							; drop
.rbpdone:
	test	edi, NoSaveRSP
	jnz		.norsp
	lea		rsi, [rsp+0x20]					; stack ptr before swapto
	mov		[rbp+Ctx_rsp], rsi
.norsp:
	mov		[rbp+Ctx_r8], r8
	mov		[rbp+Ctx_r9], r9
	mov		[rbp+Ctx_r10], r10
	mov		[rbp+Ctx_r11], r11
	mov		[rbp+Ctx_r12], r12
	mov		[rbp+Ctx_r13], r13
	mov		[rbp+Ctx_r14], r14
	mov		[rbp+Ctx_r15], r15

loadcontext_in:
	pop		r14								; return addr
	pop		r15								; flags
	pop		rbp								; new context ptr

	test	r15d, LeaveRAX
	jnz		.norax
	mov		rax, [rbp+Ctx_rax]
.norax:
	test	r15d, LeaveRBX
	jnz		.norbx
	mov		rbx, [rbp+Ctx_rbx]
.norbx:
	test	r15d, LeaveRCX
	jnz		.norcx
	mov		rcx, [rbp+Ctx_rcx]
.norcx:
	test	r15d, LeaveRDX
	jnz		.nordx
	mov		rdx, [rbp+Ctx_rdx]
.nordx:
	test	r15d, LeaveRSI
	jnz		.norsi
	mov		rsi, [rbp+Ctx_rsi]
.norsi:
	test	r15d, LeaveRDI
	jnz		.nordi
	mov		rdi, [rbp+Ctx_rdi]
.nordi:
	test	r15d, LeaveRSP
	jnz		.norsp
	mov		rsp, [rbp+Ctx_rsp]
	jmp		.rspdone
.norsp:
	test	r15d, IsLoad					; pop old ctx if swapping and
	jnz		.rspdone						;  keeping stack
	add		rsp, 4
.rspdone:
	test	r15d, LeaveR8
	jnz		.nor8
	mov		r8, [rbp+Ctx_r8]
.nor8:

	push	r14								; stuff return addr on new stack
	
	mov		rbp, [rbp+Ctx_rbp]
	mov		r9, [rbp+Ctx_r9]
	mov		r10, [rbp+Ctx_r10]
	mov		r11, [rbp+Ctx_r11]
	mov		r12, [rbp+Ctx_r12]
	mov		r13, [rbp+Ctx_r13]
	mov		r14, [rbp+Ctx_r14]
	mov		r15, [rbp+Ctx_r15]
	
	ret

; Re-enter Forth after a signal.
; void freentry(int reentry_cause, int64 *reentry_data)
;
; Note that the C prototype has int *reentry_data -- but it's really an array of 2 int64s.
;
global freentry
freentry:
	pop		rdx								; drop

%ifdef WINDOWS
	; Variables already in the correct registers.
%else
	mov		ecx, edi						; rcx: reentry_cause
	mov		rdx, rsi						; rdx: reentry_data
%endif
	
	; Swap back to Forth context, dragging RCX and RDX with us
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword LeaveRCX | LeaveRDX | NoSaveRSP
	call	swaptocontext

	; Push arguments to signal handler onto data stack:
	;   ( data0 data1 cause )
	mov		[rbp-0x8], rax
	mov		rax, rcx
	
	mov 	rcx, [rdx]
	mov		[rbp-0x10], rcx
	mov		rcx, [rdx+8]
	mov		[rbp-0x18], rcx
	
	sub		rbp, 0x18

	; Call Forth handler, if defined
	mov		rcx, [rbx+GDSignalHandler]
	jrcxz	.nohandler
	call	rcx
	
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
	; If from Forth, load system context first.
	
	; Save old stack
	mov		rax, rsp

	; Check if in Forth
	mov		r9, qword [inforth]
	test	r9, r9
	jz		.notforth
	
	; Load system context if so. (unclear if this is necessary)
	;  Don't save Forth context as the signal handler
	;  has trashed registers. Keep the arguments we're given.
	lea		r11, [sys_ctx]
	push	r11
%ifdef WINDOWS
	push	qword LeaveRCX | LeaveRDX | LeaveR8 | LeaveRAX
%else
	push	qword LeaveRDI | LeaveRSI | LeaveRDX | LeaveRAX
%endif
	call	loadcontext

.notforth:	
	and		rsp, -16			; align stack...
	sub		rsp, 8
	push	rax					; save old stack pointer in case handler returns
	
	; Add fourth argument: were we in Forth?
%ifdef WINDOWS
	mov		rarg4, qword [inforth]
%else
	mov		rarg4, qword [inforth]
%endif
	mov		qword [inforth], 0
	
	; OK, args are ready for the C signal handler
	; void c_sighandler(int sig, siginfo_t *siginfo, ucontext_t *uap, int wasInForth)
	call	c_sighandler
	
	; The C signal handler returned. Restore old stack pointer and return.
	pop		rsp
	ret

; Hosted primitives for I/O and debugging
;
; Each of these are wrappers around corrrsponding C functions that actually do the
;  work. They are rrsponsible for swapping from the Forth context to the system
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
	mov		[rbp-8], rax
	sub		rbp, 8
	
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveNone
	call	swaptocontext
	
	and		rsp, -16
	call	c_host_key
	movzx	rax, al
	
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword LeaveRAX | NoSaveRSP
	call	swaptocontext

	mov		qword [inforth], -1
	
	ret


; (host-key?): return if a character has been pressed      ( -- key? )
paren_host_key_question:
	mov		[rbp-8], rax
	sub		rbp, 8
	
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveNone
	call	swaptocontext
	
	and		rsp, -16
	call	c_host_key_question
	movzx	rax, al
	neg		rax
	
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword LeaveRAX | NoSaveRSP
	call	swaptocontext

	mov		qword [inforth], -1
	
	ret


; (host-emit): output a character							( char -- )
paren_host_emit:
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveRAX
	call	swaptocontext
	
	and		rsp, -16
	mov		rarg1, rax
	call	c_host_emit
	
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword NoSaveRSP
	call	swaptocontext
	mov		qword [inforth], -1

	mov		rax, [rbp]
	add		rbp, 8
	ret
	

; (host-bye): exit to shell									( -- )
paren_host_bye:
	; Swap out of Forth context
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveRAX
	call	swaptocontext
	
	; Align and call C code
	and		rsp, -16
	call	c_host_bye
	
	; _c_host_bye should not return; if so...
	call	abort


; <dump>:	dump current state								( -- )
bracketdump:
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveRAX
	call	swaptocontext
		
	and		rsp, -16

	%ifdef WINDOWS
	sub		rsp, 8
	push	qword [forth_ctx + Ctx_rbx]
	push	qword [forth_ctx + Ctx_rsp]	

	mov		rarg1, rax
	mov		rarg2, [forth_ctx + Ctx_rsi]
	mov		rarg3, [forth_ctx + Ctx_rdi]
	mov		rarg4, [forth_ctx + Ctx_rbp]
	%else
	mov		rarg1, rax
	mov		rarg2, [forth_ctx + Ctx_rsi]
	mov		rarg3, [forth_ctx + Ctx_rdi]
	mov		rarg4, [forth_ctx + Ctx_rbp]
	mov		rarg5, [forth_ctx + Ctx_rsp]
	mov		rarg6, [forth_ctx + Ctx_rbx]
	%endif

	call	c_dump	
		
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword NoSaveRSP
	call	swaptocontext
	mov		qword [inforth], -1

	ret


; (host-rest): wait for a short period of time for user input to occur			( -- )
paren_host_rest:
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveNone
	call	swaptocontext
		
	and		rsp, -16

	call	c_host_rest
		
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword NoSaveRSP
	call	swaptocontext
	mov		qword [inforth], -1

	ret

; (host-is-window): provide pointers to #lines and #columns			( #l #c -- )
paren_host_is_window:
	mov		rcx, [rbp]
	
	mov		qword [inforth], 0
	lea		r11, [forth_ctx]
	push	r11
	lea		r11, [sys_ctx]
	push	r11
	push	qword LeaveRAX | LeaveRCX
	call	swaptocontext
	
	and		rsp, -16

	mov		rarg1, rcx				; no-op for Win64 ABI
	mov		rarg2, rax
	
	call	c_host_is_window
	
	lea		r11, [sys_ctx]
	push	r11
	lea		r11, [forth_ctx]
	push	r11
	push	qword NoSaveRSP
	call	swaptocontext
	mov		qword [inforth], -1

	mov		rax, [rbp+8]
	add		rbp, 16
	ret


; <debug>:	enter debugger										( -- )
bracketdebug:
	int3
	ret
	

; <ctx>:	return pointer to either Forth or system context	( sys? -- ptr )
bracketctx:
	test	rax, rax
	jnz		.sysctx
	lea		rax, [forth_ctx]
	ret
.sysctx:
	lea		rax, [sys_ctx]
	ret


; ----------------------
; Common core
; ----------------------
%include "x86_64-core.S"


; ----------------------
; Data for x86_64-core-wrap
; ----------------------

section .bss
bits 64
default rel

global forth_ctx
global sys_ctx

; Context storage
forth_ctx:
	resb ContextSize 
sys_ctx:
	resb ContextSize

; Flag whether we're in Forth code
inforth:
	resq 1




