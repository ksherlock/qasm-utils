*
*
* process the macro file, looking for 
*
*
	ent process_mac_dir
	ext do_opcode
	ext do_label
	ext find_entry
	ext insert_entry
	ext update_entry

inmac dw 0
missing dw 0

process_mac_dir
* scan macro files in 4:
* scan twice to resolve dependencies.

	stz :pass

	lda #process_mac_line-1
	sta line_rtn

]loop
	_OpenGS :open
	bcs :err

	lda :open_refNum
	sta :close_refNum
	sta :dir_refNum


]dloop
	_GetDirEntryGS :dir
	bcs :eof
	jsr one_dir_entry
	lda missing
	bne ]dloop

:eof
	_CloseGS :close
	lda missing
	beq :done

	lda :pass
	bne :done
	inc :pass
	bra ]loop

:done
	clc
	rts

:err
	phl #:path4
	_QADrawErrStringL
	phl #:cosp
	_QADrawErrString
	_QAErrorMsg


	pla
	sec
	rts

:close	dw 1
:close_refNum dw 0

:open	dw 3
:open_refNum dw 0
	dl :path4
	dw 1 ; read-only


:path4 strl "4:"

:cosp	str ': '


:pass dw 0



dir	dw 7
dir_refNum dw 0
	dw 0 ; flags
	dw 1 ; base
	dw 1 ; displacement
	dw 0 ; entry
	dl :dir_name
dir_ftype dw 0
dir_eof dl 0
dir_name
	dw 64+2+2
	ds 64+2


one_dir_entry

	lda dir_eof
	ora dir_eof+2
	bne :szok
	rts
:szok
	lda dir_ftype
	cmp #4 ; text
	beq :ftok
	cmp #$b0 ; apw src
	beq :ftok
	rts
:ftok
	lda dir_name+2
	cmp #64
	bcc :nmok
	rts
:nmok
	tax ; count
	sep #$20
	sta input
	dex
]loop	lda dir_name+2,x
	sta input+1,x
	dex
	bpl ]loop

	rep #$20

	jmp process_file




process_mac_line

	stz label
	stz name
	stz operand
	stz flags

	sty :line_start

	sep #$20
	jsr do_label
	bcs :eof ; can skip the entire line
	jsr do_opcode
	bcs :instr ; was a label so we might need to copy it.

	sty :save_y ; for pmc...
	jsr next_line ; just get it now...
	sty :line_end

* if we're not in a macro we care about, just check for 'mac'...
	rep #$20
	bit inmac
	bmi :lookup

	lda name
	cmp #$036d ; 03 'm'
	bne :nmac
	lda name+2
	cmp #$6361
	bne :nmac 
	jmp :mac
:nmac
	ldy :line_end
	rts

:lookup
	jsr find_entry
	bcs :missing
	lda flags
	and #$00ff
	beq :instr
	asl
	tax
	jmp (:table,x)
:table dw :unk,:instr,:mac,:eom,:pmc,:put
:line_start dw 0
:line_end dw 0

:eof
	rts

:missing
* opcode not in table - treat it as a macro dependency.
*	bit inmac
*	bpl :igmiss

	lda #%1000_0000_0000_0000
	sta flags
	jsr emplace_entry
	inc missing
	jmp append_line

*:igmiss	ldy :line_end
*	rts

:unk ; previously seen macro
:instr
:put
	jmp append_line
*	rep #$20
*	bit inmac
*	bmi append_line
*	ldy :line_end
*	rts

:pmc ; this needs to parse out operand to get the macro name in case it's a dependency....
	mx %00
*	bit inmac
*	bpl :igpmc
	sep #$20
	ldy :save_y
	jsr do_operand_pmc
	rep #$20
	bcs :pmcapp ; no operand????

	lda #%1000_0000_0000_0000
	jsr insert_entry
:pmcapp jmp append_line

*:igpmc
*	ldy :line_end
*	rts


:eom
	mx %00
*	bpl inmac
	stz inmac
	jmp append_line
*	bmi append_line
*	ldy :line_end
*	rts

:mac
* check if the label is needed
	lda label
	and #$00ff
	beq :nomac
	ldx #label
	ldy #name
	mvn #label,#name
	jsr find_entry
	bcc :addmac
:nomac
	ldy :line_end
	rts

:addmac
	lda #%0100_0000_0000_0000
	sta flags
	jsr update_entry ; just update the flags.
	sec
	ror inmac
*	bra :instr2
* drop through....

append_line
	lda :line_end
	sec
	sbc :line_start
	clc
	adc offset
	cmp #512
	bcc :ok

* todo - write macro buffer to disk...

	stz offset


]ok


	sep #$20
	ldy :line_start
	ldx offset

]loop	lda [fptr],y
	and #$7f
	sta buffer,x
	inx
	iny
	cpy :line_end
	bcc ]loop
	stx offset



	ldy :line_end
	rts


offset dw 0
buffer	ds 512

