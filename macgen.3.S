*
*
* process a macro file, looking for macros that we care about.
*
*

          lst  off
          xc
          xc
          mx   %00
          cas  se

          rel

          use  macgen.equ
          use  macgen.macs

          ent  process_mac_dir
          ext  do_opcode
          ext  do_label
          ext  do_operand_pmc

          ext  find_entry
          ext  insert_entry
          ext  update_entry
          ext  emplace_entry
          ext  buffer
          ext  input
          ext  process_dir
          ext  label,operand,name,flags

inmac     dw   0
missing   dw   0
pass      dw   0

process_mac_dir
* scan macro files in 4:
* scan twice to resolve dependencies.

          stz  pass
          stz  inmac
          stz  missing

          lda  #process_mac_line-1
          sta  line_rtn


          lda  :4
          sta  input
          lda  :4+2
          sta  input+2
          lda  :4+4
          sta  input+4
          jsr  process_dir
          rts



:4        strl '4:'


process_mac_line

          mx   %10
          ldx  #0
          stx  label
          stx  name
          stx  operand
          stx  flags

          txa

          jsr  do_label
          bcs  :eof         ; can skip the entire line
          jsr  do_opcode
          bcs  :instr       ; was a label so we might need to copy it.

          sty  y_save      ; for pmc...

* if we're not in a macro we care about, just check for 'mac'...
          rep  #$20
          bit  inmac
          bmi  :lookup

          lda  name
          cmp  #'m'*256+3   ; 03 'm'
          bne  :nmac
          lda  name+2
          cmp  #'ca'
          bne  :nmac
          jmp  :mac
:nmac
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

:eof
          rts

:missing
* opcode not in table - treat it as a macro dependency.

          lda  #%1000_0000_0000_0000
          sta  flags
          jsr  emplace_entry
          inc  missing
*          jmp  append_line ; drop through...


:unk                        ; previously seen macro
:instr
:put
          jmp  append_line

:pmc                        ; this needs to parse out operand to get the macro name in case it's a dependency....
          mx   %00
          sep  #$20
          ldy  y_save
          jsr  do_operand_pmc
          rep  #$20
          bcs  :pmcapp      ; no operand????

          lda  #%1000_0000_0000_0000
          jsr  insert_entry
:pmcapp   jmp  append_line


:eom
          mx   %00
          stz  inmac
          jmp  append_line

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
          lda  line_end
          sec
          sbc  line_start
          clc
          adc  offset
          cmp  #512
          bcc  :ok

* todo - write macro buffer to disk...

          stz  offset


:ok
          sep  #$20
          ldy  line_start
          ldx  offset

]loop     lda  [fptr],y
          and  #$7f
          sta  buffer,x
          inx
          iny
          cpy  line_end
          bcc  ]loop
          stx  offset

          rts


offset    dw   0

