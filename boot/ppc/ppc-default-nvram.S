

nv_default:
	dc.l	0			; xsum, ignored.
	dc.w	0x80		; word length, also ignored.
	dc.w	0			; flags
	dc.l	-1			; real-base
	dc.l	-1			; real-size
	dc.l	-1			; virt-base
	dc.l	-1			; virt-size
	dc.l	0x0			; load-base
	dc.l	0x1000		; screen-#rows
	dc.l	0x1000		; screen-#columns
	dc.l	0			; nvram-block#
	ds.b	0x10		; nvram-device
	ds.b	0x40		; boot-device
	ds.b	0x20		; boot-file
	ds.b	0x40		; diag-device
	ds.b	0x20		; diag-file
	dc.b	'keyboard'	; input-device
	dc.b	0
	ds.b	0x1F - 8
	dc.b	'screen'	; output-device
	dc.b	0
	ds.b	0x1F - 8
	ds.b	0x40		; boot-command
	ds.b	0x88		; nvramrc
	
nv_default_end: