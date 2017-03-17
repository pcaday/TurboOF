%ifndef __X86_CORE_WRAP_HEADER_I
%define	__X86_WRAP_CORE_HEADER_I 1

	; Forth memory layout
	FMemBootstrapDict		equ 0x0
	FMemBootstrapCode		equ 0x1800
	FMemStackBase			equ 0x37C0
	FMemRStackBase			equ 0x47C0
	FMemInitVec				equ 0x4800
	FMemGlobalData			equ 0x4900
	FMemForthData			equ 0x4A00

	FMemRStackSize			equ 0x0FC0


	; Context layout
	Ceax					equ 0x0
	Cebx					equ 0x4
	Cecx					equ 0x8
	Cedx					equ 0xC
	Cesi					equ 0x10
	Cedi					equ 0x14
	Cebp					equ 0x18
	Cesp					equ 0x1C
	ContextSize				equ 0x20
	
	
	; Flags for swaptocontext/loadcontext
	LeaveNone				equ 0x0
	LeaveEAX				equ 0x1
	LeaveEBX				equ 0x2
	LeaveECX				equ 0x4
	LeaveEDX				equ 0x8
	LeaveESP				equ 0x80
	NoSaveEAX				equ 0x100
	NoSaveEBX				equ 0x200
	NoSaveECX				equ 0x400
	NoSaveEDX				equ 0x800
	NoSaveESI				equ 0x1000
	NoSaveEBP				equ 0x4000
	NoSaveESP				equ 0x8000
	IsLoad					equ 0x10000
	
	
%endif

