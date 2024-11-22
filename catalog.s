
          cas  se
          xc
          xc
          mx   %00

          rel
          tbx

utool     mac
          ldx  #]1*256+1
          jsl  $E10008
          <<<

_QAReadDir mac              ;_QAReadDir(@pathname,@doroutine,flags)
          utool $39
          eom
_QAInitWildCard mac         ;_QAInitWildcard(@wcstr,ft,aux/4,ftmask,auxmask/4)
          utool $3a
          eom
_QAPrByte mac               ;_QAPrByte(byteval)
          utool $0B
          <<<
_QAPrByteL mac              ;_QAPrByteL(hexval)
          utool $0C
          <<<
_QADrawCR mac               ;_QADrawCR()
          utool $63
          <<<
_QADrawStringL MAC          ;_QADrawStrL(@string/class.1)
          utool $69
          <<<
_QATabtoCol mac             ;_QATabtoCol(columnnum)
          utool $33
          <<<
_QADrawChar mac             ;_QADrawChar(char)
          utool $09
          <<<
_QADrawCharX mac            ;_QADrawCharX(char,count)
          utool $5D
          <<<
_QADrawString mac           ;_QADrawString(@strptr)
          utool $0A
          <<<
_QADrawDec mac              ;_QADrawDec(longint/4,flags,fieldsize)
          utool $0D
          <<<
_QAConvertTyp2Txt mac       ;_QAConvertTyp2Txt(filetype,@typestr)
          utool $37
          <<<
_QADrawHex mac              ;_QADrawHex(hexval/4,flags,fieldsize)
          utool $5A
          <<<
_QADateTime mac             ;_QADateTime(@Date,flags)
          utool $62
          <<<
_QADrawSpace mac            ;_QADrawSpace()
          utool $64
          <<<

main
          dum  0
]ptr      ds   4
          dend

          phk
          plb


          sta  myID
          stx  ]ptr+2
          sty  ]ptr

          jsr  cmdline

          psl  #header
          _QADrawString

          psl  #path
:hook     psl  #hook
          psw  #0           ; no recurse, no wildcard check
          _QAReadDir

          lda  #0
          clc
          rtl

cmdline
* check the commandline for a path.
          ldy  #8

          lda  #0
          sta  path
          sep  #$20
* skip past cmd name
]loop     lda  []ptr],y
          beq  :default
          iny
          cmp  #' '+1
          bcs  ]loop

* skip past white space...
]loop     lda  []ptr],y
          beq  :default
          iny
          cmp  #' '+1
          bcc  ]loop

* now copy to path...
          ldx  #0
          dey
]loop     lda  []ptr],y
          beq  :eop
          iny
          cmp  #' '+1
          bcc  :eop
          sta  path+2,x
          inx
          bra  ]loop

:eop      stx  path
          rep  #$30
          clc
          rts

:default
          rep  #$30
          lda  #1
          sta  path
          lda  #'0:'
          sta  path+2

          sec
          rts


header    str  'Name             Type Blocks  Modified         Created           Length Auxtype'0d0d
*path0     strl '0'
path      ds   256+2
myID      ds   2

* GetDirEntryRecGS offsets.
          dum  0
pCount    ds   2
refNum    ds   2
flags     ds   2
base      ds   2
displacement ds 2
name      ds   4
entryNum  ds   2
fileType  ds   2
eof       ds   4
blockCount ds  4
createDateTime ds 8
modDateDate ds 8
access    ds   2
auxType   ds   4
fileSysID ds   2
optionList ds  4
resourceEOF ds 8
resourceBlocks ds 8
          dend

hook

          mx   %00
          dum  1
]ptr      ds   4
]dcb      ds   4
]y        ds   2
          dend

          phb
          phk
          plb
          phd

          phy
          phx
          pha
          pha               ; tmp
          pha
          tsc
          tcd


* name... but truncate if > 18 chars
          do   0
          ldy  #name+2
          lda  []dcb],y
          pha
          dey
          dey
          lda  []dcb],y
          inc
          inc
          pha
          _QADrawStringL
          else

          ldy  #name
          lda  []dcb],y
          clc
          adc  #2
          sta  ]ptr

          iny
          iny
          lda  []dcb],y
          adc  #0
          sta  ]ptr+2

          lda  []ptr]
          cmp  #17+1
          bcc  :name

          lda  #17
          sta  path
          ldx  #8           ; copy 16 chars
          ldy  #2
]loop     lda  []ptr],y
          sta  path,y
          iny
          iny
          dex
          bne  ]loop

          lda  #'..'
          sta  path+2+14
          sta  path+2+15

          psl  #path
          bra  :qdsl



:name     pei  ]ptr+2
          pei  ]ptr
:qdsl     _QADrawStringL
          fin



* file type
          pea  18
          _QATabtoCol

          ldy  #fileType
          lda  []dcb],y
          pha
          psl  #:typeStr
          _QAConvertTyp2Txt

          psl  #:typeStr
          _QADrawString

          _QADrawSpace

* blocks
          ldy  #blockCount+2
          lda  []dcb],y
          pha
          dey
          dey
          lda  []dcb],y
          pha
          pea  %0_10_0_0000_0000_0000 ; flags - unsigned, left justified.
          pea  6            ; field size
          _QADrawDec

          _QADrawSpace
          _QADrawSpace

* dates
          clc
          lda  ]dcb
          adc  #modDateDate
          tax
          lda  ]dcb+2
          adc  #0
          pha
          phx
          pea  %0011        ; date, time
          _QADateTime

          _QADrawSpace
          _QADrawSpace

          clc
          lda  ]dcb
          adc  #createDateTime
          tax
          lda  ]dcb+2
          adc  #0
          pha
          phx
          pea  %0011        ; date, time
          _QADateTime

          _QADrawSpace
* file size
          ldy  #eof+2
          lda  []dcb],y
          pha
          dey
          dey
          lda  []dcb],y
          pha

          pea  #%0_10_0_1_000_0000_0000 ; left justified, $
          pea  8            ; field size
          _QADrawHex

* aux type...
          _QADrawSpace

* L= (f8), R=(04),A=(06)

          ldy  #fileType
          lda  []dcb],y
          ldx  #:leq
          cmp  #$f8
          beq  :at
          ldx  #:aeq
          cmp  #$06
          beq  :at
          ldx  #:req
          cmp  #$04
          beq  :at
          ldx  #:spsp
:at
          pea  ^:leq
          phx
          _QADrawString

          pea  0
          ldy  #auxType
          lda  []dcb],y
          pha

          pea  #%0_10_1_1_000_0000_0000 ; left justified, leading 0s, $
          pea  5            ; field size
          _QADrawHex



          _QADrawCR



:return
          pla
          pla
          pla
          pla
          pla

          pld
          plb
          clc
          rtl


:leq      str  'L='
:aeq      str  'A='
:req      str  'R='
:spsp     str  '  '

:typeStr  ds   4



          sav  catalog.l
