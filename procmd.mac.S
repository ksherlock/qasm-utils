


ldax	mac
	lda ]1
	if #=]1
	ldx ^]1
	else
	ldx ]1+2
	fin
	<<<
stax	mac
	sta ]1
	stx ]1+2
	<<<

plax	mac
	pla
	plx
	<<<

phxa	mac
	phx
	pha
	<<<

Tool	mac
	tll ]1
	<<<

utool	mac
	ldx #]1*256+1
	jsl $E10008
	<<<


~DisposeHandle MAC
 PSL ]1
 Tool $1002
 <<<


_QALoadFile        mac                     ;_QALoadfile(@filename,filepos/4,length/4,@typelist,userid,address/4,memattrib):filehandle/4
                   utool  $18
                   <<<
_QAGetCmdLine      mac                     ;_QAGetCmdLine(@strptr,maxlen)
                   utool  $1B
                   <<<
_QADrawErrChar     mac                     ;_QADrawErrChar(char)
                   utool  $51
                   <<<
_QADrawErrString   mac                     ;_QADrawErrString(@strptr)
                   utool  $52
                   <<<


LONGM	MAC
LONGACC	MAC	;Assumes native mode
	IF	MX&2	;If A is now short
	REP	%00100000
	FIN
	<<<

LONGX	MAC
LONGXY	MAC	;Assumes native mode
	IF	MX&1	;If X is now short
	REP	%00010000
	FIN
	<<<

LONG	MAC
LONGAX	MAC	;Assumes native mode
LONGMX	MAC	;Assumes native mode
	IF	MX	;If not now in full 16
	REP	%00110000
	FIN
	<<<

SHORTM	MAC
SHORTACC	MAC	;Assumes native mode
	IF	MX&2	;If A is now short,
	ELSE	; ignore
	SEP	%00100000
	FIN
	<<<

SHORTX	MAC
SHORTXY	MAC	;Assumes native mode
	IF	MX&1	;If X is now short,
	ELSE		; ignore
	SEP	%00010000
	FIN
	<<<

SHORT	MAC
SHORTAX	MAC	;Assumes native mode
SHORTMX	MAC	;Assumes native mode
	IF	MX!%11	;If not now in full 8
	SEP	%00110000
	FIN
	<<<