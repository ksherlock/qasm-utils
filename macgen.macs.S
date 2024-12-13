
utool     mac
          ldx  #]1*256+1
          jsl  $E10008
          <<<

prodos16  mac
          jsl  $e100a8
          dw   ]1
          dl   ]2
          <<<

_create   mac
          prodos16 $01;]1
          <<<

_destroy  mac
          prodos16 $02;]1
          <<<

_open     mac
          prodos16 $10;]1
          <<<

_close    mac
          prodos16 $14;]1
          <<<

_write    mac
          prodos16 $13;]1
          <<<

debug     mac
          brl  eom
          dw   $7771
          str  ]1
eom       eom

~QADrawString MAC
~QADrawStr MAC
          phl  ]1
_QADrawString mac           ;_QADrawString(@strptr)
_QADrawStr mac
          utool $0A
          <<<

_QADrawCR mac               ;_QADrawCR()
          utool $63
          <<<

_QAPrByteL mac              ;_QAPrByteL(hexval)
          utool $0C
          <<<

_QALoadFile mac             ;_QALoadfile(@filename,filepos/4,length/4,@typelist,userid,address/4,memattrib):filehandle/4
          utool $18
          <<<

~QAReadDir MAC
          phl  ]1
          phl  ]2
          phw  ]3
_QAReadDir mac              ;_QAReadDir(@pathname,@doroutine,flags)
          utool $39
          <<<


~QAGetCmdLine MAC
          phl  ]1
          phw  ]2
_QAGetCmdLine mac           ;_QAGetCmdLine(@strptr,maxlen)
          utool $1B
          <<<

~QADrawErrStr MAC
~QADrawErrString MAC
          phl  ]1
_QADrawErrStr mac
_QADrawErrString mac        ;_QADrawErrString(@strptr)
          utool $52
          <<<

~QAErrorMsg MAC
          phw  ]1
_QAErrorMsg mac             ;_QAErrorMsg(ErrorCode)
          utool $34
          <<<


~QADrawChar MAC
          phw  ]1
_QADrawChar mac             ;_QADrawChar(char)
          utool $09
          <<<

_QADrawSpace mac            ;_QADrawSpace()
          utool $64
          <<<


~QADrawDec MAC
          phl  ]1
          phw  ]2
          phw  ]3
_QADrawDec mac              ;_QADrawDec(longint/4,flags,fieldsize)
          utool $0D
          <<<




_SetTrace mac
          ldx  #$11ff
          jsl  $e10000
          eom


sev       mac
          sep  #$40
          eom


phw       mac
          if   #=]1
          pea  ]1
          else
          if   <=]1
          pei  ]1
          else
          lda  ]1
          pha
          fin
          fin
          eom

phl       mac
          if   #=]1
          pea  ^]1
          pea  ]1
          else
          if   <=]1
          pei  ]1+2
          pei  ]1
          else
          lda  ]1+2
          pha
          lda  ]1
          pha
          fin
          fin
          eom


lc        mac
          cmp  #'Z'+1
          bcs  ok
          cmp  #'A'
          bcc  ok
          ora  #$20
ok        eom
