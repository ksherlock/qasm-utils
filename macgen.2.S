          lst  off

          xc
          xc
          mx   %00
          cas  se

          rel

          use  4:mem.macs
          use  4:util.macs


          use  macgen.equ
          use  macgen.macs


* tbx on



          ext  insert_entry
          ext  name,flags
          ext  process_file
          ext  buffer

          ent  process_src

*
* this scans the file and adds an entry for any encountered macros
* (known and unknown) into the hash table.
* Additionally, USE/PUT paths are stored for later processing
*
*



label_size equ 32
operand_size equ 64

label     ds   label_size
operand   ds   operand_size

input     str  'test.s'     ; ds 128




process_src
	debug 'process_src'
          lda  #process_src_line-1
          sta  line_rtn
          jmp  process_file





process_src_line

	debug 'process_src_line'

* input:
* y: offset in fptr [start of line]
* output:
* y: offset in fptr [start of next line]
* carry: set if $00 encountered

          stz  label
          stz  name
          stz  operand
          stz  flags

          lda  #0
          ldx  #0
          sep  #$20

          jsr  do_label
          bcs  :eof

          jsr  do_opcode
          bcs  :eof

          sty  :y_temp      ; save
          rep  #$20
          lda  #%1000_0000_0000_0000
          sta  flags
          jsr  insert_entry
          bcs  :known
          ldy  :y_temp
          jmp  next_line

:eof      rts

:known
          mx   %00
* entry already exists in hash table. check for special type
          lda  flags
          and  #$00ff
          asl
          tax
          jmp  (:table,x)
:table    dw   :none,:none,:mac,:eom,:pmc,:put
:y_temp   dw   0

:none
:eom
          ldy  :y_temp
          jmp  next_line

          lst  on
:mac
* define label as the macro


          lda  #%0100_0000_0000_0000
          sta  flags

          lda  label
          and  #$00ff
          beq  :none
          ldx  #label
          ldy  #name
          mvn  #label,#name
          jsr  insert_entry



          bra  :none
          lst  off
* ldy :y_temp
* jmp next_line_mx

:put
          mx   %00
          ldy  :y_temp
          sep  #$20
          jsr  do_operand
* rep #$20
* bcc :put1
          rts
*:put1
* todo
          rts

* not strictly correct; consider pmc lda
:pmc
          mx   %00
          ldy  :y_temp
          sep  #$20
          jsr  do_operand_pmc ; load macro into name
          bcc  :pmc1
:rts      rts
:pmc1
          phy               ; save
          rep  #$20
          lda  #%1000_0000_0000_0000
          sta  flags
          jsr  insert_entry
          ply               ; restore
          rts

do_label
* loads label
* returns carry set if blank and eof encountered.

          mx   %10

          ldx  #0
          stx  label

          lda  [fptr],y
          iny

          and  #$7f
          cmp  #$0d
          beq  :cr
          cmp  #'*'
          beq  :comment
          cmp  #';'
          beq  :comment
          cmp  #' '+1
          bcc  :ws

          dey               ; re-process.
]loop
          lda  [fptr],y
          and  #$7f
          cmp  #$0d
          beq  :fin
          iny
          cmp  #' '+1
          bcc  :fin
          lc
          sta  label+1,x
          cpx  #label_size
          bcs  ]loop
          inc  label
          inx
          bra  ]loop

:comment
          jsr  next_line
:cr       sec
          rts
:fin
:ws
          clc
          rts


do_opcode
* loads opcode, into name field (since we always need to look it up)
* returns carry set if blank and eof encountered.
          mx   %10
          ldx  #0
          stx  name

* skip past any whitespace/comment

]loop
          lda  [fptr],y
          iny
          and  #$7f
          cmp  #$0d
          beq  :cr
          cmp  #';'
          beq  :comment
          cmp  #' '+1
          bcc  ]loop

          dey               ; re-process
]loop     lda  [fptr],y
          and  #$7f
          cmp  #$0d
          beq  :fin
          iny
          cmp  #' '+1
          bcc  :fin
          lc
          sta  name+1,x
          cpx  #name_size
          bcs  ]loop
          inc  name
          inx
          bra  ]loop

:comment
          jsr  next_line
:cr       sec
          rts

:fin
          clc
          rts


do_operand
* load operand
* returns carry set if blank and eof encountered.
* -- advances to next line --


          mx   %10
          ldx  #0
          stx  operand

* skip past any whitespace/comment

]loop
          lda  [fptr],y
          iny
          and  #$7f
          cmp  #$0d
          beq  :cr
          cmp  #';'
          beq  :comment
          cmp  #' '+1
          bcc  ]loop

          dey               ; re-process
]loop     lda  [fptr],y
          iny
          and  #$7f
          cmp  #$0d
          beq  :fincr
          cmp  #' '+1
          bcc  :fin
          lc
          sta  operand+1,x
          cpx  #operand_size
          bcs  ]loop
          inc  operand
          inx
          bra  ]loop

:comment
          jsr  next_line
:cr       sec
          rts

:fin
          jsr  next_line
:fincr
          clc
          rts



do_operand_pmc
* load the operand for a pmc
* stores directly into name
* and stops at the first ';'
* -- advances to next line --

          mx   %10
          ldx  #0
          stx  name

* skip past any whitespace/comment

]loop
          lda  [fptr],y
          iny
          and  #$7f
          cmp  #$0d
          beq  :cr
          cmp  #';'
          beq  :comment
          cmp  #' '+1
          bcc  ]loop

          dey               ; re-process
]loop     lda  [fptr],y
          iny
          and  #$7f
          cmp  #$0d
          beq  :fincr
          cmp  #' '+1
          bcc  :fin
          cmp  #';'
          beq  :fin
          lc
          sta  name+1,x
          cpx  #name_size
          bcs  ]loop
          inc  name
          inx
          bra  ]loop

:comment
          jsr  next_line
:cr       sec
          rts

:fin
          jsr  next_line
:fincr
          clc
          rts


next_line
* advance to cr, then skip past it.
          sep  #$20
]loop     lda  [fptr],y
* beq :eof
          iny
* beq :eof
          and  #$7f
          cmp  #$0d
          bne  ]loop
          clc
          rts

*:eof sec
* rep #$30
* rts





          sav  macgen.2.l
