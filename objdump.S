
          lst  off
          rel
          xc
          xc
          mx   %00

          tbx
          use  qatools.macs


debug     mac
          brl  eom
          dw   $7771
          str  ]1
eom       eom


_SetTrace mac
          ldx  #$11ff
          jsl  $e10000
          eom


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

names     ds   4
nptr      ds   4


reloc     ds   8


r0        ds   2



offset    ds   2
reference ds   4
size      ds   2
shift     ds   2
msg       ds   2
ext       ds   2
extoff    ds   2
inline    ds   4


          err  *>255
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


          jsr  scan_names

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
          jmp  help
*          sec
*          rts

          mx   %10
:eop
:ws
          stx  input
          rep  #$20
          clc
          rts


help
          ~QADrawErrStr #:msg
          sec
          rts
:msg      str  'Usage: dumpobj file.l',0d



          mx   %00

loadfile

          _GSOS:GetFileInfo info
          bcs  :err_toolbox
          lda  info_fileType
          cmp  #$f8         ; rel
          bne  :err_file_type
          lda  info_eof+2
          cmp  #2
          bcc  :ok

:err_file_type
:err_too_big
          ~QADrawErrStrL #input
          ~QADrawErrStr #:badft
          sec
          rts


:err_toolbox
          pha
:etb2     ~QADrawErrStrL #input
          ~QADrawErrStr #:cosp
          _QAErrorMsg
          sec
          rts

:err_toolbox_xba
          pha
          lda  input
          xba
          sta  input
          bra  :etb2


:cosp     str  ': '
:badft    str  ': Invalid REL file',0d


:ok

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
          bcs  :err_toolbox_xba

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



PrWord_8000
* adjust a by $8000 and print it
          clc
          adc  #$8000
          pha
          _QAPrByteL
          rts


print_ref
          bit  ext
          bmi  :ext
          ~QADrawChar #'$'
          ~QAPrByteL reference
          rts
:ext
* print as external # +/- offset

          lda  reference
          jsr  print_name
* ~QADrawDec reference;#0;#0
          lda  inline
          ora  inline+2
          bne  :adj
          rts
:adj
          lda  size
          asl
          tax
          jmp  (:table,x)
:table    dw   :0,:1,:2,:3,:4
:1
          lda  inline
          and  #$0080
          beq  :plus
          ora  #$ff00
          sta  inline
          lda  #-1
          sta  inline+2
:minus
* for large values, display in hex
	  lda inline+2
	  cmp #$ffff
	  bne :mihex
	  lda inline
	  cmp #-255
	  bcc :mihex
          ~QADrawDec inline;#%1_00_0_0000_0000_0000;0 ; signed
          rts

:mihex
	  ~QADrawHex inline;#%1_00_0_1_000_0000_0000;0
	  rts
:2
:3
:4
          lda  inline+2
          bmi  :minus

:plus
* for large values, display in hex
          ~QADrawChar #'+'
	  lda inline+2
	  bne :plhex
	  lda inline
	  cmp #255
	  bcs :plhex
          ~QADrawDec inline;#%0_00_0_0000_0000_0000;0 ; unsigned
          rts
:plhex
	  ~QADrawHex inline;#%0_00_0_1_000_0000_0000;0
          rts

:0
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
          _QADrawCR
          clc
          rts


*
* format:
* offset reference size shift comment raw bytes
* 1234   5678   01    00           xx xxxx xx


*
* todo -- external labels may have an adjustment, which is stored in-line
* eg, dw ''
*


:ok
          iny
          iny
          lda  [ptr],y
          sta  reloc+2
          iny
          iny

          lda  :op
          cmp  #$ff         ; extended shift?
          bne  :ok2

          lda  [ptr],y
          iny
          iny
          sta  reloc+4
          lda  [ptr],y
          iny
          iny
          sta  reloc+6

:ok2      sty  :y


          lda  reloc+1
          sta  offset
          stz  reference+2
          stz  ext
          stz  extoff
          stz  extoff+2

          ldy  reloc+1
          lda  [objptr],y
          sta  inline
          iny
          iny
          lda  [objptr],y
          sta  inline+2


* assume external, fixed later.
          lda  reloc+3
          and  #$00ff
          sta  reference

          lda  :op
          bit  #$10
          beq  :disp
          sec
          ror  ext
:disp
          and  #$00f0
          lsr
          lsr
          lsr
          tax
          lda  :size,x
          sta  size
          lda  :shift,x
          sta  shift
          jsr  (:table,x)
          jcs  :dump

          ~QADrawChar #'$'
          ~QAPrByteL offset
          _QADrawSpace
          jsr  print_ref
          ~QATabToCol #30

          ~QAPrNibble size
          _QADrawSpace
          pea  0
          pei  shift
          pea  #%0_10_0_0000_0000_0000
          pea  2
          _QADrawDec
*          ~QAPrByte shift
          lda  msg
          beq  :dump
          pea  #^*
          pha
          ~QATabToCol #40
          _QADrawString

:dump
          ~QATabtoCol #50

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
          bne  :cr

* extended shift
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
:cr
          _QADrawCR
          ldy  :y
          brl  ]loop


:table
          dw   :0,:1,:2,:3,:4,:5,:6,:7
          dw   :8,:9,:a,:b,:c,:d,:e,relocf

:size     dw   1,1,3,3,1,0,0,0,2,2,2,2,0,0,0,0
:shift    dw   0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0


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


inline1   mac
          stz  inline+1
          stz  inline+2
          eom

inline2   mac
          sec
          lda  inline
          sbc  #$8000
          sta  inline
          lda  #0
          sbc  #0
          sta  inline+2
          eom

inline3   mac
          sec
          lda  inline
          sbc  #$8000
          sta  inline
          lda  inline+2
          and  #$00ff
          sbc  #0
          sta  inline+2
          eom

inline4   mac
          sec
          lda  inline
          sbc  #$8000
          sta  inline
          lda  inline+2
          sbc  #0
          sta  inline+2
          eom



* $0f - 1 byte relocation
* $1f - 1 byte relocation (external)
:0
:1
          inline1
          clc
          rts

* $2f - 3 byte relocation
:2
          inline3           ; can't actually be 3 bytes
          lda  inline
          sta  reference
          clc
          rts

* $3f - 3 byte relocation (external)
:3
          inline3
          clc
          rts

* $4f - 1 byte reloc w/ 8 bit shift
* eg: mx %11 / ldx  #>internal
* address is split
:4
          lda  inline
          and  #$00ff
          eor  #$0080
          xba
          tsb  reference
          stz  inline
          stz  inline+2
          clc
          rts

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
          inline2
          lda  inline
          sta  reference
          clc
          rts

* $9f - 2 byte relocation (external)
:9
          inline2
          clc
          rts

* $af - ddb
:a
          lda  inline
          xba
          eor  #$8000
          sta  reference
          lda  #:as
          sta  msg
          clc               ; abnormal
          rts
:as       str  '[ddb]'

* $bf - ddb (external
:b
          lda  inline
          xba
          eor  #$8000
          sta  inline
          stz  inline+2
          lda  #:bs
          sta  msg
          clc
          rts
:bs       str  '[ddb, external]'

* $cf - ds \
:c

          ~QADrawStr #:ds

          lda  reloc+3
          and  #$00ff
          pha
          _QAPrByte

          sec
          rts
:ds       str  'DS \,'


* $df - ???
:d
          pla
          brl  :bad_reloc

* $ef - err \
:e

          ~QADrawStr #:err

          ~QAPrByteL reloc+1
          sec
          rts

:err      str  'ERR \,'
          rts

* $ff - extended shift
relocf
          stz  ext
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
          lda  #16
          sta  shift
          lda  #1
          sta  size

          lda  reloc+5
          eor  #$8000
          sta  reference
          clc
          rts

:4
          lda  #16
          sta  shift
          lda  #1
          sta  size

          inline1

          sec
          ror  ext
          clc
          rts


* $ff d1 - 8-bit, 2-byte shift
:1
          lda  #8
          sta  shift
          lda  #2
          sta  size

          lda  reloc+5
          eor  #$8000
          sta  reference
          clc
          rts

:5
          lda  #8
          sta  shift
          lda  #2
          sta  size

          inline2
          sec
          ror  ext
          clc
          rts


* $ff d3 - 8-bit, 1-byte shift
:3
          lda  #8
          sta  shift
          lda  #1
          sta  size

          lda  reloc+5
          eor  #$8000
          sta  reference
          clc
          rts

:7
          lda  #8
          sta  shift
          lda  #1
          sta  size

          inline1
          sec
          ror  ext
          clc
          rts



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
          bit  #$80
          beq  :ent
:ext
*          _QADrawSpace
*          _QADrawSpace

* ext are $8000, exd is not.
* only 256 externals allowed so they can't overflow...

          pea  0
          lda  :value
          and  #$00ff
          pha
          pea  #%0_10_0_0000_0000_0000
          pea  7
          _QADrawDec

          lda  :value
          bpl  :exd
          lda  #:extstr
          bra  :prname
:exd
          lda  #:exdstr
          bra  :prname
:ent
          _QADrawSpace
          _QADrawSpace
          ~QADrawChar #'$'
          lda  :value
          jsr  PrWord_8000
          lda  #:entstr
          bra  :prname

:equ      ~QADrawHex :value;#%0_10_1_1000_0000_0000;#7
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


print_name
          debug 'print_name'


* a = external name
          tay               ; save in case of failure...
          asl
          tax
          lda  name_index,x

          bne  :ok
          pea  0
          phy
          pea  0
          pea  0
          _QADrawDec


          pha
          pea 0
          _SetTrace
          pla

          rts

:ok
	  and #$7fff
          clc
          adc  names
          sta  nptr
          lda  #0
          adc  names+2
          sta  nptr+2

          lda  #0
          sep  #$20
          lda  [nptr]
          and  #$1f
          cmp  #15
          php
          bcc  :copy
          lda  #15
:copy
          sta  :name
          tay
]loop     lda  [nptr],y
          sta  :name,y
          dey
          bne  ]loop

          plp
          bcc  :print
          lda  #'.'
          sta  :name+15
          sta  :name+14
          sta  :name+13
:print
          rep  #$20
          ~QADrawStr #:name

          rts

:name     ds   32

scan_names
          debug 'scan_names'


          ldx  #256*2-2
]loop     stz  name_index,x
          dex
          dex
          bpl  ]loop

          ldy  #0

]loop     lda  [ptr],y
          iny
          and  #$ff         ; extended shift byte 5 will never be 0 so this works
          beq  :endr
          iny
          iny
          iny
          bra  ]loop

:endr
          tya
          clc
          adc  ptr
          sta  names
          lda  #0
          adc  ptr+2
          sta  names+2

* now build up a table
          ldy  #0
]loop     lda  [names],y
          and  #$00ff
          beq  :end
          sty  r0
          bit  #$80
          beq  :no

          and  #$1f
          clc
          adc  r0
          tay
          iny
          lda  [names],y
          and  #$00ff
          asl
          tax
          lda  r0
          ora #$8000
          sta  name_index,x
          iny
          iny
          iny
          bra  ]loop

:no       and  #$1f
          clc
          adc  r0
          adc  #4 ; length + 3 value bytes
          tay
          bra  ]loop

:end      


	rts



name_index ds  256*2



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
