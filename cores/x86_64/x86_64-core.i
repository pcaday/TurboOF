%ifndef __X86_CORE_HEADER_I
%define	__X86_CORE_HEADER_I 1

	; Bootstrap dictionary entry structure
	BDENameLength	equ 0
	BDEType			equ 1
	BDECodePtr		equ 8
	BDEName			equ 0x10

	BDELength		equ 0x20		; Total size
	BDELength_log2	equ	5
	
	; Global data structure
	GDBootstrapDictBase		equ 0x00
	GDBootstrapDictCount	equ 0x08
	GDBootstrapInterpPtr	equ 0x10
	GDBootstrapCompilePtr	equ 0x18
	GDBootstrapForthPtr		equ 0x20
	GDInitVec				equ 0x28
	GDSystemStack			equ 0x30		; not used
	GDSavedRStack			equ 0x38
	GDSignalHandler			equ 0x40
	
	; Initialization vector
	IVDataBase		equ 0x0
	IVBDBase		equ 0x8
	IVStackBase		equ 0x10
	IVRStackBase	equ 0x18
	IVFTextBase		equ 0x20
	IVAMBase		equ 0x28
	IVRealBase		equ 0x30
	IVRealSize		equ 0x38
	IVVirtBase		equ 0x40
	IVVirtSize		equ 0x48
	IVGlobalData	equ 0x50


	; MakeBDEntry(label, name, nlength, immediate)
	%macro MakeBDEntry 4
		%strlen __MakeBDEntry_namelen %2
		db		__MakeBDEntry_namelen			; name length
		db		2 | %4							; type (always native, possibly immediate)
		dw		0								; padding
		dd		0								; padding
		dq		(%1 - __bcat_start)				; code ptr (to be relocated later)
		db		%2								; name
		times (16-__MakeBDEntry_namelen) db ' ' ; fill 16-byte name field
	%endm

	; CurrentBDENumber
	%define CurrentBDENumber (($-__bcat_start)/BDELength)

	; BDECount
	%define BDECount ((__bcat_end - __bcat_start)/BDELength)

%endif

