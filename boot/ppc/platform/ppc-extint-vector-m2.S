	mtsprg	3, r2
	mfsprg	r2, 1
	stw		r7, INT_R7(r2)
	mfcr	r7
	stw		r7, INT_CR(r2)
	stw		r3, INT_R3(r2)

	; Must set up translation to access I/O
	
	lis		r7, 0x50F0
	ori		r7, r7, 0x002A
	isync
	mtspr	dbat3l, r7
	isync
	lis		r7, 0x50F0
	ori		r7, r7, 0x001F
	isync
	mtspr	dbat3u, r7
	isync
	
	mfmsr	r7
	ori		r7, r7, 0x10				; DR on
	mtmsr	r7
	isync
	
	lis		r2, 0x50F2
	ori		r2, r2, 0xA000
	
	lwz		r7, 0(r2)
	ori		r7, r7, 0x80
	stw		r7, 0(r2)
	eieio
	lwz		r3, 0(r2)
	rlwimi	r3, r3, 3, 0x38
	stw		r3, 0(r2)
	eieio
	
	mfmsr	r7
	rlwinm	r7, r7, 0, 0xFFFFFFEF		; DR off
	mtmsr	r7
	isync

	li		r7, 0
	isync
	mtspr	dbat3u, r7
	isync
	mtspr	dbat3l, r7
	isync
	
	mfsprg	r2, 1
	stb		r3, INT_PLATFORM_USE(r2)	; Store 68k interrupt level
	rlwinm	r3, r3, 0, 0x7
	cmplwi	r3, 7						; Check for NMI
	lwz		r3, INT_R3(r2)
	
;	ba		__forth_quit
	beq-	_0x0500_m2_quit
	
	lwz		r7, INT_CR(r2)
	mtcr	r7
	lwz		r7, INT_R7(r2)
	mfsprg	r2, 3
	rfi
	
_0x0500_m2_quit:				; Land here for NMI
	li		r7, 0x500
	li		r31, 0				; Force an unrecoverable exception
	ba		__forth_quit