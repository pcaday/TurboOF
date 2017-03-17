	ifndef __PPC_FUNC_I
__PPC_FUNC_I set 1

	macro
	func &fnName
		export &fnName[DS]
		export .&fnName[PR]
		
		tc &fnName[TC], &fnName[DS]
		
		csect &fnName[DS]
			DC.L .&fnName[PR]
			DC.L TOC[tc0]
		
		function .&fnName[PR]
		csect .&fnName[PR]
		&fnName:
	endm

	macro
	func_align &fnName, &fnAlign
		export &fnName[DS]
		export .&fnName[PR]
		
		tc &fnName[TC], &fnName[DS]
		
		csect &fnName[DS]
			DC.L .&fnName[PR]
			DC.L TOC[tc0]
		
		function .&fnName[PR]
		csect .&fnName[PR], &fnAlign
		&fnName:
	endm
	
	macro
	extdata &dName
		export &dName[RW]
	
		tc &dName[TC], &dName[RW]
		csect &dName[RW]
	endm
	
	macro
	impd &dName
		toc
		tc &dName[TC], &dName[RW]
	endm
	
	macro
	tocreload
		lwz		RTOC, 0x14(SP)
	endm
	
	endif