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
          ext  buffer,input

          ent  process_src
          ent  do_operand_pmc
          ent  do_label
          ent  do_opcode
          ent  label,operand

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





process_src
          debug 'process_src'

          stz  buffer_offset
          stz  pass

          lda  #process_src_line-1
          sta  line_rtn
          jsr  process_file

*
* now repeat for all use/put files.
*
          ldx  buffer_offset
          beq  :done
          stz  buffer,x
          lda  #$8080
          sta  pass
          stz  buffer_offset ; end when 0-terminated.
]loop
          ldx  buffer_offset
          lda  buffer,x
          and  #$ff
          beq  :done

          sta  r0
          lda  #buffer
          clc
          adc  buffer_offset
          tax
          ldy  #input
          lda  r0
          mvn  #buffer,#input
          lda  r0
          clc
          adc  buffer_offset
          inc
          sta  buffer_offset
* append .S
          ldx  r0
          do   0
          sep  #$20
          lda  #'.'
          sta  input+1,x
          lda  #'S'
          sta  input+2,x
          inc  input
          inc  input
          rep  #$20
          fin
          lda  #'.s'
          sta  input+1,x
          inc  input        ; we're 16-bit but it's ok since < $fd bytes - no carry to second bit.
          inc  input

          jsr  process_file
          bra  ]loop


:done     rts



process_src_line

          debug 'process_src_line'

* input:
* y: offset in fptr [start of line]
* line_start, line_end variables set

          mx   %10

          ldx  #0
          stx  label
          stx  name
          stx  operand
          stx  flags

          txa               ; 0s 16-bit a

          jsr  do_label
          bcs  :eof

          jsr  do_opcode
          bcs  :eof

          sty  y_save       ; save
          rep  #$20
          lda  #%1000_0000_0000_0000
          sta  flags
          jsr  insert_entry
          bcs  :known

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

:none
:eom
          rts

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
          jmp  insert_entry

:put
          mx   %00
          ldy  y_save
          sep  #$20
          jmp  do_operand_path

* not strictly correct; consider " pmc lda" - this would be a macro named lda.
:pmc
          mx   %00
          ldy  y_save
          sep  #$20
          jsr  do_operand_pmc ; load macro into name
          bcs  :pmc_rts

          rep  #$20
          lda  #%1000_0000_0000_0000
          sta  flags
          jmp  insert_entry
:pmc_rts  rts

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
:cr       sec
          rts

:fin
:fincr
          clc
          rts



do_operand_pmc
* load the operand for a pmc
* stores directly into name
* and stops at the first ';'
* -- advances to next line --

          mx   %10
          bit  pass
          bmi  :fin

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
:cr       sec
          rts

:fin
:fincr
          clc
          rts


do_operand_path
*
* operand is a path; stick it in the buffer so we can process it later.
*

          mx   %10

          ldx  buffer_offset
          cmp  #1024-128
          bcs  :cr          ; not enough space...

          ldx  #0
          stz  operand



* skip whitespace...
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


          dey
]loop     lda  [fptr],y
          iny
          and  #$7f
          cmp  #' '+1
          bcc  :fin
          sta  operand+1,x
          inc  operand
          inx
          cpx  #operand_size-3 ; too big?
          bcs  :cr
          bra  ]loop

:comment
:cr       sec
          rts

:fin
* now put the name in the buffer to process later...


* add the .S suffix

          do   0
          lda  #'.'
          sta  operand+1,x
          lda  #'S'
          sta  operand+2,s
          inc  operand
          inc  operand
          inx
          inx
          fin

          rep  #$20

* a = count,
* x = src
* y = dest
          phx               ; save length
          lda  buffer_offset
          clc
          adc  #buffer
          tay
          txa               ; size, w/o length byte
          ldx  #operand     ; source
          mvn  #operand,#buffer

          pla               ; length
          sec               ; +1 for length byte
          adc  buffer_offset
          sta  buffer_offset

          sep  #$20
          clc
          rts



          sav  macgen.2.l
