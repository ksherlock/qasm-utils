
          lst  off
          rel
          xc
          xc
          mx   %00

          tbx
          use  qatools.macs


readEnable equ $0001
writeEnable equ $0002

attrLocked equ $8000
attrNoSpec equ $0008




          dum  0
user_id   ds   2
cmdline   ds   4
ptr       ds   4
objptr    ds   4

handle    ds   4



reloc     ds   8


r0        ds   2
          dend

main
          phk
          plb
          sta  user_id
          stx  cmdline+2
          sty  cmdline


          jsr  getopt
          bcs  :err

          jsr  loadfile
          bcs  :err

          jsr  relocs
          bcs  :disp
          jsr  labels

:disp
          psl  handle
          _DisposeHandle

          clc
          lda  #0
          rtl

:err      lda  #1
          sec
          rtl



getopt

          lda  #0
          ldy  #8
          sep  #$20

* skip past the command name...
]loop
          lda  [cmdline],y
          beq  :eol
          iny
          cmp  #' '+1
          bcs  ]loop

* skip past white space...
]loop
          lda  [cmdline],y
          beq  :eol
          iny
          cmp  #' '+1
          bcc  ]loop

          ldx  #1
          sta  input+2
* parameter!
]loop
          lda  [cmdline],y
          beq  :eop
          iny
          cmp  #' '+1
          bcc  :ws
          sta  input+2,x
          inx
          bra  ]loop

:eol
          rep  #$20
          sec
          rts

          mx   %10
:eop
:ws
          stx  input
          rep  #$20
          clc
          rts





          mx   %00

loadfile

          _GSOS:GetFileInfo info
          bcs  :err_toolbox
          lda  info_fileType
          cmp  #$f8         ; rel
          bne  :err_file_type
          lda  info_eof+2
          cmp  #2
          bcs  :err_too_big



* _QALoadFile expects a p-string
          lda  input
          xba
          sta  input

          pha               ; space
          pha
          psl  #input+1
          psl  #0           ; pos
          psl  info_eof
          psl  #0           ; type list
          psw  user_id
          psl  #0           ; address
          psw  #attrLocked.attrNoSpec
          _QALoadFile
          plx
          stx  handle
          plx
          stx  handle+2
          bcs  :err_toolbox

          lda  [handle]
          sta  objptr
          clc
          adc  info_auxType
          sta  ptr

          ldy  #2
          lda  [handle],y
          sta  objptr+2
          adc  #0
          sta  ptr+2

          clc
          rts

:err_file_type
:err_too_big
:err_toolbox
          sec
          rts


PrWord_8000
* adjust a by $8000 and print it
          clc
          adc  #$8000
          pha
          _QAPrByteL
          rts


relocs
          ldy  #0

]loop
          lda  [ptr],y
          sta  reloc
          and  #$00ff
          beq  :eof
          sta  :op
          and  #$0f
          cmp  #$0f
          beq  :ok
          brl  :bad_reloc

:eof
* bump to externs....
          iny
          tya
          clc
          adc  ptr
          sta  ptr
          lda  #0
          adc  ptr+2
          sta  ptr+2
          clc
          rts

:ok
          iny
          iny
          lda  [ptr],y
          sta  reloc+2
          iny
          iny
          sty  :y

          lda  reloc
          and  #$00ff
          pha
          _QAPrByte
          _QADrawSpace
          lda  reloc+1
          pha
          _QAPrByteL
          _QADrawSpace
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  :op
          cmp  #$ff
          bne  :dispatch

* extended shift
          ldy  :y
          lda  [ptr],y
          sta  reloc+4
          iny
          iny
          lda  [ptr],y
          sta  reloc+6
          iny
          iny
          sty  :y

          _QADrawSpace
          lda  reloc+4
          and  #$00ff
          pha
          _QAPrByte
          _QADrawSpace

          lda  reloc+4
          xba
          and  #$00ff
          pha
          lda  reloc+6
          pha
          pea  %0_10_1_0000_0000_0000 ; right justified, 0-filled
          pea  6            ; field size
          _QADrawHex

:dispatch
          ~QATabtoCol #24
          lda  :op
          and  #$00f0
          lsr
          lsr
          lsr
          tax
          jsr  (:table,x)
          cmp  #0
          beq  :cr
          pea  #^*
          pha
          ~QATabToCol #48
          _QADrawString
:cr       _QADrawCR
          ldy  :y
          brl  ]loop



:table
          dw   :0,:1,:2,:3,:4,:5,:6,:7
          dw   :8,:9,:a,:b,:c,:d,:e,relocf


:y        ds   2
:op       ds   2


:bad_reloc

          ~QADrawStr #:bad_str

          lda  :op
          pha
          _QAPrByte
          _QADrawCR

          sec
          rts

:bad_str  str  'Invalid relocation type: $'


* $0f - 1 byte relocation
:0
* address
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte
          lda  #:0s
          rts

:0s       str  '[1-byte reloc]'

* $1f - 1 byte relocation (external)
:1
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  #:1s
          rts

:1s       str  '[1-byte reloc, external]'

* $2f - 3 byte relocation
:2
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          ldy  reloc+1
          lda  [objptr],y
          jsr  PrWord_8000
*          sta  reloc+4
*          iny
*          iny
*          lda  [objptr],y
*          and  #$00ff
*          sta  reloc+6

*          ~QADrawHex reloc+4;#%0_10_1_0000_0000_0000;#6
          lda  #:02s
          rts
:02s      str  '[3-byte reloc]'

* $3f - 3 byte relocation (external)
:3
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  #:03s
          rts
:03s      str  '[3-byte reloc, external]'

* $4f - 1 byte reloc w/ 8 bit shift
* eg: mx %11 / ldx  #>internal
:4
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          ~QADrawChar #'>'
          ldy  reloc+1
          lda  [objptr],y
          and  #$00ff
          clc
          adc  #$ff80
          pha
          _QAPrByte
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte
          lda  #:4s
          rts


:4s       str  '[1-byte reloc, 8-bit shift]'

* $5f - ???
:5
          pla
          brl  :bad_reloc

* $6f - ???
:6
          pla
          brl  :bad_reloc

* $7f - ???
:7
          pla
          brl  :bad_reloc

* $8f - 2 byte relocation
:8
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          ldy  reloc+1
          lda  [objptr],y
          jsr  PrWord_8000
*          pha
*          _QAPrByteL
          lda  #:8s
          rts

:8s       str  '[2-byte reloc]'

* $9f - 2 byte relocation (external)
:9
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte
          lda  #:9s
          rts

:9s       str  '[2-byte reloc, external]'

* $af - ddb
:a
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          ldy  reloc+1
          lda  [objptr],y
          xba ; of course....
          jsr  PrWord_8000
*          pha
*          _QAPrByteL
          lda  #:as
          rts
:as       str  '[ddb]'

* $bf - ddb (external
:b
          ~QAPrByteL reloc+1
          ~QADrawChar #$2c
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte
          lda  #:bs
          rts
:bs       str  '[ddb, external]'

* $cf - ds \
:c

          ~QADrawStr #:ds

          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  #0
          rts
:ds       str  'DS \,$'


* $df - ???
:d
          pla
          brl  :bad_reloc

* $ef - err \
:e

          ~QADrawStr #:err

          ~QAPrByteL reloc+1
          lda  #0
          rts

:err      str  'ERR \,$'
          rts

* $ff - extended shift
relocf

          ~QAPrByteL reloc+1
          ~QADrawChar #$2c

          lda  reloc+4
          and  #$00f8
          cmp  #$d0
          beq  :d0
          pla
          brl  :bad_reloc
:d0
          lda  reloc+4
          and  #$000f
          asl
          tax
          jmp  (:table,x)
:table
          dw   :0,:1,:2,:3,:4,:5,:6,:7

* $ff d0 - 16-bit, 1-byte shift
:0
          ~QADrawChar #'^'
          lda  reloc+5
          jsr  PrWord_8000
*          lda  reloc+7
*          and  #$00ff
*          pha
*          pei  reloc+5
*          pea  #%0_10_1_0000_0000_0000
*          pea  6
*          _QADrawHex

          lda  #:0s
          rts
:0s       str  '[1-byte reloc, 16-bit shift]'

:4
          ~QADrawChar #'^'
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  #:4s
          rts
:4s       str  '[1-byte reloc, 16-bit shift, external]'



* $ff d1 - 8-bit, 2-byte shift
:1
          ~QADrawChar #'>'
          lda  reloc+5
          jsr  PrWord_8000

*          lda  reloc+7
*          and  #$00ff
*          pha
*          pei  reloc+5
*          pea  #%0_10_1_0000_0000_0000
*          pea  6
*          _QADrawHex

          lda  #:1s
          rts
:1s       str  '[2-byte reloc, 8-bit shift]'

:5
          ~QADrawChar #'>'
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  #:5s
          rts
:5s       str  '[2-byte reloc, 8-bit shift, external]'


* $ff d1 - 8-bit, 2-byte shift
:3
          ~QADrawChar #'>'
          lda  reloc+5
          jsr  PrWord_8000
*          lda  reloc+7
*          and  #$00ff
*          pha
*          pei  reloc+5
*          pea  #%0_10_1_0000_0000_0000
*          pea  6
*          _QADrawHex

          lda  #:3s
          rts
:3s       str  '[1-byte reloc, 8-bit shift]'

:7
          ~QADrawChar #'>'
          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          lda  #:7s
          rts
:7s       str  '[1-byte reloc, 8-bit shift, external]'


:2
:6
          pla               ; drop through...


:bad_reloc

          ~QADrawStr #:bad_str

          lda  reloc+4
          and  #$00ff
          pha
          _QAPrByte
          _QADrawCR

          sec
          rts

:bad_str  str  'Invalid relocation type: $'


labels
* print the external names

          ldy  #0
          stz  :value
          stz  :value+2

]loop
          lda  [ptr],y
          and  #$00ff
          bne  :ok
:eof
          clc
          rts

:ok       sta  :op

          iny

*copy the name over
          and  #$1f
          sta  :name
          ldx  #0

          sep  #$20
]nloop    lda  [ptr],y
          iny
          sta  :name+2,x
          inx
          cpx  :name
          bne  ]nloop

          rep  #$20


          lda  [ptr],y
          sta  :value
          iny
          lda  [ptr],y
          sta  :value+1
          iny
          iny
          sty  :y

          lda  :op
          bit  #$20
          bne  :equ
          bit   #$80
          beq  :ent
:ext
          _QADrawSpace
          _QADrawSpace

* ext are $8000, exd is not.
* only 256 externals allowed so they can't overflow...
          lda  :value
          bpl  :exd
          jsr  PrWord_8000
          lda  #:extstr
          bra  :prname
:exd
	  ~QAPrByteL :value
          lda  #:exdstr
          bra  :prname
:ent
          _QADrawSpace
          _QADrawSpace
          lda :value
          jsr  PrWord_8000
          lda  #:entstr
          bra  :prname

:equ      ~QADrawHex :value;#%0_10_1_0000_0000_0000;#6
          lda  #:equstr

:prname
          pea  #^*
          pha
          _QADrawString

          ~QADrawStrL #:name
          _QADrawCR
          ldy  :y
          brl  ]loop


:y        ds   2
:op       ds   2
:value    ds   4
:name     ds   34           ; max $1f

:equstr   str  '  EQU '
:entstr   str  '  ENT '
:extstr   str  '  EXT '
:exdstr   str  '  EXD '
*****

info
info_pCount dw 9
info_pathname adrl input
info_access ds 2
info_fileType ds 2
info_auxType ds 4
info_storageType ds 2
info_create ds 8
info_mod  ds   8
info_option adrl 0
info_eof  dl   0


input     ds   256+2


          sav  objdump.l
