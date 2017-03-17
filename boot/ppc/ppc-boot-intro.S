	tc ppc_boot_len[TC], ppc_boot_len[RO]
	tc ppc_boot[TC], ppc_boot[RO]

	export ppc_boot_len[RO]
	csect ppc_boot_len[RO], 5
	dc.l last_code - commencement	
	ds.l 7
	
	export ppc_boot[RO]
	csect ppc_boot[RO], 5

;	export ppc_boot[DS]
;	export .ppc_boot[PR]
;	
;	tc ppc_boot[TC], ppc_boot[DS]
;	
;	csect ppc_boot[DS]
;		dc.l .ppc_boot[PR]
;		dc.l toc[tc0]
;	
;	function .ppc_boot[PR]
;	csect .ppc_boot[PR], 5
