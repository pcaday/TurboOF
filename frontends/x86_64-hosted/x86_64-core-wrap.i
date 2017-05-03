%ifndef __X86_CORE_WRAP_HEADER_I
%define	__X86_WRAP_CORE_HEADER_I 1

	; Forth memory layout
	FMemBootstrapDict		equ 0x0
	FMemBootstrapCode		equ 0x2000
	FMemStackBase			equ 0x5F80
	FMemRStackBase			equ 0x7F80
	FMemInitVec				equ 0x8000
	FMemGlobalData			equ 0x8100
	FMemForthData			equ 0x8200

	FMemRStackSize			equ 0x1F80

	; Context layout
	Ctx_rax					equ 0x0
	Ctx_rbx					equ 0x8
	Ctx_rcx					equ 0x10
	Ctx_rdx					equ 0x18
	Ctx_rsi					equ 0x20
	Ctx_rdi					equ 0x28
	Ctx_rbp					equ 0x30
	Ctx_rsp					equ 0x38
	Ctx_r8					equ 0x40
	Ctx_r9					equ 0x48
	Ctx_r10					equ 0x50
	Ctx_r11					equ 0x58
	Ctx_r12					equ 0x60
	Ctx_r13					equ 0x68
	Ctx_r14					equ 0x70
	Ctx_r15					equ 0x78
	ContextSize				equ 0x80
	
	
	; Flags for swaptocontext/loadcontext
	LeaveNone				equ 0x0
	LeaveRAX				equ 0x1
	LeaveRBX				equ 0x2
	LeaveRCX				equ 0x4
	LeaveRDX				equ 0x8
	LeaveRSI				equ 0x10
	LeaveRDI				equ 0x20
	LeaveRSP				equ 0x80
	LeaveR8					equ 0x100
	NoSaveRAX				equ 0x10000
	NoSaveRBX				equ 0x20000
	NoSaveRCX				equ 0x40000
	NoSaveRDX				equ 0x80000
	NoSaveRSI				equ 0x100000
	NoSaveRBP				equ 0x400000
	NoSaveRSP				equ 0x800000
	IsLoad					equ 0x10000000
	
	
	%ifdef WINDOWS
		%define rarg1		rcx
		%define rarg2		rdx
		%define rarg3		r8
		%define rarg4		r9
	%else
		%define rarg1		rdi
		%define rarg2		rsi
		%define rarg3		rdx
		%define rarg4		rcx
		%define rarg5		r8
		%define rarg6		r9
	%endif
%endif

