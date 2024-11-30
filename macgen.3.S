*
*
* process a macro file, looking for macros that we care about.
*
*
          ent  process_mac_dir
          ext  do_opcode
          ext  do_label
          ext  find_entry
          ext  insert_entry
          ext  update_entry

inmac     dw   0
missing   dw   0

process_mac_dir
* scan macro files in 4:
* scan twice to resolve dependencies.

          stz  :pass

          lda  #process_mac_line-1
          sta  line_rtn


process_mac_line

          stz  label
          stz  name
          stz  operand
          stz  flags

          sty  :line_start

          sep  #$20
          jsr  do_label
          bcs  :eof         ; can skip the entire line
          jsr  do_opcode
          bcs  :instr       ; was a label so we might need to copy it.

          sty  :save_y      ; for pmc...
          jsr  next_line    ; just get it now...
          sty  :line_end

* if we're not in a macro we care about, just check for 'mac'...
          rep  #$20
          bit  inmac
          bmi  :lookup

          lda  name
          cmp  #$036d       ; 03 'm'
          bne  :nmac
          lda  name+2
          cmp  #$6361
          bne  :nmac
          jmp  :mac
:nmac
          ldy  :line_end
          rts

:lookup
          jsr  find_entry
          bcs  :missing
          lda  flags
          and  #$00ff
          beq  :instr
          asl
          tax
          jmp  (:table,x)
:table    dw   :unk,:instr,:mac,:eom,:pmc,:put
:line_start dw 0
:line_end dw   0

:eof
          rts

:missing
* opcode not in table - treat it as a macro dependency.
* bit inmac
* bpl :igmiss

          lda  #%1000_0000_0000_0000
          sta  flags
          jsr  emplace_entry
          inc  missing
          jmp  append_line

*:igmiss ldy :line_end
* rts

:unk                        ; previously seen macro
:instr
:put
          jmp  append_line
* rep #$20
* bit inmac
* bmi append_line
* ldy :line_end
* rts

:pmc                        ; this needs to parse out operand to get the macro name in case it's a dependency....
          mx   %00
* bit inmac
* bpl :igpmc
          sep  #$20
          ldy  :save_y
          jsr  do_operand_pmc
          rep  #$20
          bcs  :pmcapp      ; no operand????

          lda  #%1000_0000_0000_0000
          jsr  insert_entry
:pmcapp   jmp  append_line

*:igpmc
* ldy :line_end
* rts


:eom
          mx   %00
* bpl inmac
          stz  inmac
          jmp  append_line
* bmi append_line
* ldy :line_end
* rts

:mac
* check if the label is needed
          lda  label
          and  #$00ff
          beq  :nomac
          ldx  #label
          ldy  #name
          mvn  #label,#name
          jsr  find_entry
          bcc  :addmac
:nomac
          ldy  :line_end
          rts

:addmac
          lda  #%0100_0000_0000_0000
          sta  flags
          jsr  update_entry ; just update the flags.
          sec
          ror  inmac
* bra :instr2
* drop through....

append_line
          lda  :line_end
          sec
          sbc  :line_start
          clc
          adc  offset
          cmp  #512
          bcc  :ok

* todo - write macro buffer to disk...

          stz  offset


]ok


          sep  #$20
          ldy  :line_start
          ldx  offset

]loop     lda  [fptr],y
          and  #$7f
          sta  buffer,x
          inx
          iny
          cpy  :line_end
          bcc  ]loop
          stx  offset



          ldy  :line_end
          rts


offset    dw   0
buffer    ds   512

