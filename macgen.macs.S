
utool     mac
          ldx  #]1*256+1
          jsl  $E10008
          <<<

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

~QAGetCmdLine MAC
          psl  ]1
          psw  ]2
_QAGetCmdLine mac           ;_QAGetCmdLine(@strptr,maxlen)
          utool $1B
          <<<

_QADrawErrStr mac
_QADrawErrString mac        ;_QADrawErrString(@strptr)
          utool $52
          <<<

~QAErrorMsg MAC
          psw  ]1
_QAErrorMsg mac             ;_QAErrorMsg(ErrorCode)
          utool $34
          <<<


_SetTrace mac
 ldx #$11ff
 jsl $e10000
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
