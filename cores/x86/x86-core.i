%ifndef __X86_CORE_HEADER_I
%define	__X86_CORE_HEADER_I 1

	; Bootstrap dictionary entry structure
	BDENameLength	equ 0
	BDEType			equ 1
	BDECodePtr		equ 4
	BDEName			equ 8

	BDELength		equ 0x18		; Total size

	; Global data structure
	GDBootstrapDictBase		equ 0x00
	GDBootstrapDictCount	equ 0x04
	GDBootstrapInterpPtr	equ 0x08
	GDBootstrapCompilePtr	equ 0x0C
	GDBootstrapForthPtr		equ 0x10
	GDInitVec				equ 0x14
	GDSystemStack			equ 0x18		; not used
	GDSavedRStack			equ 0x1C
	GDSignalHandler			equ 0x20
	
	; Initialization vector
	IVDataBase		equ 0x0
	IVBDBase		equ 0x4
	IVStackBase		equ 0x8
	IVRStackBase	equ 0xC
	IVFTextBase		equ 0x10
	IVAMBase		equ 0x14
	IVRealBase		equ 0x18
	IVRealSize		equ 0x1C
	IVVirtBase		equ 0x20
	IVVirtSize		equ 0x24
	IVGlobalData	equ 0x28


	; MakeBDEntry(label, name, nlength, immediate)
	%macro MakeBDEntry 4
		%strlen __MakeBDEntry_namelen %2
		db		__MakeBDEntry_namelen			; name length
		db		2 | %4							; type (always native, possibly immediate)
		dw		0								; padding
		dd		(%1 - __bcat_start)				; code ptr (to be relocated later)
		db		%2								; name
		times (16-__MakeBDEntry_namelen) db ' ' ; fill 16-byte name field
	%endm

	; CurrentBDENumber
	%define CurrentBDENumber (($-__bcat_start)/BDELength)

	; BDECount
	%define BDECount ((__bcat_end - __bcat_start)/BDELength)

%endif

