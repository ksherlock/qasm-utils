          lst  off

          xc
          xc
          mx   %00
          rel
          cas  se

          use macgen.equ
          use macgen.macs

          use  4:mem.macs
          use  4:int.macs
          use  4:util.macs


          ent find_entry
          ent insert_entry
          ent update_entry
          ent emplace_entry
          ent name,flags

          ext process_src

_HexDump  mac
          ldx  #$0fff
          jsl  $e10000
          <<<







*
* TODO
* - merlin macgen also processes put/use (and asm for linker....)
* - merlin macgen also checks CAS SE...
* - should read each line into line buffer, then process that...


* macgen infile outfile macrofile...
* scans infile for undefined macros, then copies from macrofile... to outfile
* if no macrofile specified, searches 4: (multi-pass to handle dependencies...)

start

          phk
          plb

          sta  myID
          jsr  init



* pass 1 - scan infile for macros
* pass 2 - scan macrofiles for


	jsr process_src

          jsr  dump
          jsr  cleanup
          lda  #0
          rtl



dump


	do 0
          pei  table+2
          pei  table
          pea  $ffff
          _HexDump
        fin

          ldy  #0


]loop
          lda  [table],y
          beq  :next


          phy               ; save

          iny
          iny
          lda [table],y
          and #$00ff
          bne :ply ; built-in
* bit 15 indicates it's used
* bit 14 indicate it's defined.

*          asl
*          bmi :ply ; built-in


*          tya
*	  lda 1,s
*          clc
*          adc  #4
	  iny
	  iny
	  tya
	  clc
          adc  table
          tax
          lda  #0
          adc  table+2
          pha
          phx
          _QADrawString

          _QADrawCR

:ply
          ply               ; restore


:next
          tya
          clc
          adc  #node_size
          tay
          bcs  :eol
          cmp  #-node_size
          bcc  ]loop
:eol
          rts


cleanup
          ~DisposeHandle hash_handle
          rts

ins       mac
          lda  ]1
          sta  name
          lda  ]1+2
          sta  name+2
          jsr  insert_entry
          eom


init
* allocate a hash table.
* insert all mnemonics and pseudo-ops into the the hash table
* MAC, PMC, <<<, >>> are special since we need them later.



          ~NewHandle #$10000;myID;attrFixed.attrLocked.attrNoSpec;0
          pla
          sta  hash_handle
          sta  ptr
          pla
          sta  hash_handle+2
          sta  ptr+2

          ldy  #2
          lda  [ptr]
          sta  table
          lda  [ptr],y
          sta  table+2

* clear table
          lda  #0
          ldy  #0
]loop     sta  [table],y
          iny
          iny
          bne  ]loop

* populate with standard mnemonics.
* this also lets us easily identify PMC/MAC/EOM


          lda  #FLAG_MAC
          sta  flags

          ins  :mac
* ins :mac2
          inc  flags
          ins  :eom
          ins  :eom2
          inc  flags
          ins  :pmc
          ins  :pmc2
          inc  flags
          ins  :put
          ins  :use

          lda  #FLAG_INSTR
          sta  flags


          ldx  #0
]loop     lda  :single,x    ; n.b. - str.
          beq  :fin1
          sta  name
          inx
          inx
          phx
          jsr  insert_entry
          plx
          bra  ]loop
:fin1


          lda  #2           ; length
          sta  name
          ldx  #0
]loop     lda  :double,x    ; n.b. - asc
          beq  :fin2
          sta  name+1
          inx
          inx
          phx
          jsr  insert_entry
          plx
          bra  ]loop
:fin2

          lda  #3           ; length
          sta  name
          ldx  #0
]loop     lda  :triple,x
          beq  :fin3
          sta  name+1
          inx
          lda  :triple,x
          sta  name+2
          inx
          inx
          phx
          jsr  insert_entry
          plx
          bra  ]loop
:fin3

          lda  #4           ; length
          sta  name
          ldx  #0
]loop     lda  :quad,x
          beq  :fin4
          sta  name+1
          inx
          inx
          lda  :quad,x
          sta  name+3
          inx
          inx
          phx
          jsr  insert_entry
          plx
          bra  ]loop
:fin4

          lda  #5           ; length
          sta  name
          ldx  #0
]loop     lda  :quince,x
          beq  :fin5
          sta  name+1
          inx
          lda  :quince,x
          sta  name+2
          inx
          inx
          lda  :quince,x
          sta  name+4
          inx
          inx
          phx
          jsr  insert_entry
          plx
          bra  ]loop
:fin5


          rts


:mac      str  'mac'
*:mac2 str 'macro'
:eom      str  'eom'
:eom2     str  '<<<'
:pmc      str  'pmc'
:pmc2     str  '>>>'
:put      str  'put'
:use      str  'use'

:single   str  '='
          dw   0
:double
          asc  'da'
          asc  'db'
          asc  'dl'
          asc  'do'
          asc  'ds'
          asc  'dw'
          asc  'if'
          asc  'mx'
          asc  'tr'
          asc  'xc'
          dw   0
:triple
          asc  'adc'
          asc  'and'
          asc  'asl'
          asc  'bcc'
          asc  'blt'
          asc  'bcs'
          asc  'bge'
          asc  'beq'
          asc  'bit'
          asc  'bmi'
          asc  'bne'
          asc  'bpl'
          asc  'bra'
          asc  'brk'
          asc  'brl'
          asc  'bvc'
          asc  'bvs'
          asc  'clc'
          asc  'cld'
          asc  'cli'
          asc  'clv'
          asc  'cmp'
          asc  'cop'
          asc  'cpx'
          asc  'cpy'
          asc  'dec'
          asc  'dex'
          asc  'dey'
          asc  'eor'
          asc  'inc'
          asc  'inx'
          asc  'iny'
          asc  'jmp'
          asc  'jml'
          asc  'jsr'
          asc  'jsl'
          asc  'lda'
          asc  'ldx'
          asc  'ldy'
          asc  'lsr'
          asc  'mvn'
          asc  'mvp'
          asc  'nop'
          asc  'ora'
          asc  'pea'
          asc  'pei'
          asc  'per'
          asc  'pha'
          asc  'phb'
          asc  'phd'
          asc  'phk'
          asc  'php'
          asc  'phx'
          asc  'phy'
          asc  'pla'
          asc  'plb'
          asc  'pld'
          asc  'plp'
          asc  'plx'
          asc  'ply'
          asc  'rep'
          asc  'rol'
          asc  'ror'
          asc  'rti'
          asc  'rtl'
          asc  'rts'
          asc  'sbc'
          asc  'sec'
          asc  'sed'
          asc  'sei'
          asc  'sep'
          asc  'sta'
          asc  'stp'
          asc  'stx'
          asc  'sty'
          asc  'stz'
          asc  'tax'
          asc  'tay'
          asc  'tcd'
          asc  'tcs'
          asc  'tdc'
          asc  'trb'
          asc  'tsb'
          asc  'tsc'
          asc  'tsx'
          asc  'txa'
          asc  'txs'
          asc  'txy'
          asc  'tya'
          asc  'tyx'
          asc  'wai'
          asc  'wdm'
          asc  'xba'
          asc  'xce'
*
*'bfl '
*'btr '
          asc  'bge'
          asc  'blt'
* asc 'dea'
* asc 'ina'
          asc  'swa'
          asc  'tas'
          asc  'tad'
          asc  'tsa'
          asc  'tda'
*
          asc  '--^'
* asc '<<<' ; special
* asc '>>>' ; special
          asc  'adr'
          asc  'asc'
          asc  'ast'
          asc  'bel'
          asc  'byt'
          asc  'cas'
          asc  'chk'
          asc  'crc'
          asc  'cyc'
          asc  'dat'
          asc  'dby'
          asc  'dci'
          asc  'ddb'
          asc  'den'
          asc  'dfb'
          asc  'dfs'
          asc  'dsk'
          asc  'dum'
          asc  'dup'
          asc  'els'
          asc  'enc'
          asc  'end'
          asc  'ent'
* asc 'eom' ; special
          asc  'equ'
          asc  'err'
          asc  'evl'
          asc  'exd'
          asc  'exp'
          asc  'ext'
          asc  'fin'
          asc  'flo'
          asc  'fls'
          asc  'hex'
          asc  'inv'
          asc  'kbd'
          asc  'lib'
          asc  'lst'
          asc  'lup'
* asc 'mac' ; special
          asc  'mtx'
          asc  'obj'
          asc  'org'
          asc  'pag'
          asc  'pau'
          asc  'pek'
* asc 'put' ; special
          asc  'rel'
          asc  'rev'
          asc  'rnd'
          asc  'sav'
          asc  'skp'
          asc  'str'
          asc  'sym'
          asc  'tbx'
          asc  'ttl'
          asc  'typ'
* asc 'use' ; special
          asc  'usr'
          asc  'var'
          asc  'xc-'
          dw   0

:quad
          asc  'adcl'
          asc  'andl'
          asc  'cmpl'
          asc  'eorl'
          asc  'jmpl'
          asc  'ldal'
          asc  'oral'
          asc  'sbcl'
          asc  'stal'
*
          asc  'adrl'
          asc  'strl'
          asc  'dend'
          asc  'else'
          asc  'xref'
          dw   0

:quince
          asc  'lstdo'
          dw   00



*
* this uses open hashing with a 64k bank; that gives ~ 1820 possible entries.
*
*


get_bucket
* 1820 buckets, 36 bytes each
* (hash % 1820) * 36
* uses r0

          lda  hash
          cmp  #1820
          bcc  :ok
          ~UDivide hash;#1820
          pla               ; quotient
          pla               ; remainder
:ok
* n * 36 = n * 9 * 4 == (n * 8) + n) * 4
          sta  r0
          asl
          asl
          asl
          clc
          adc  r0
          asl
          asl
          rts


* returns carry clear if node name matches, carry set otherwise.
cmp_entry
          php
          phy               ; save
          tya
          clc
          adc  #4           ; skip hash and flags
          adc  table
          sta  ptr
          lda  #0
          adc  table+2
          sta  ptr+2

          lda  [ptr]        ; length + first char
          cmp  name
          bne  :no

          and  #$00ff       ; count
          tax
          sep  #$20

          ldy  #0
]loop
          lda  [ptr],y
          cmp  name,y
          bne  :no
          iny
          dex
          beq  :yes
          bra  ]loop

:no       ply
          plp
          sec
          rts

:yes      ply
          plp
          clc
          rts
          mx   %00




* returns carry clear if entry found, carry set if missing.
* updates index to pointer to entry (which will be empty if not found)
find_entry
          jsr  hash_node
          jsr  get_bucket
          tay
:loop     lda  [table],y
          beq  :no
          cmp  hash
          bne  :advance
* now do a string compare...
          jsr  cmp_entry
          bcc  :yes

:advance
          tya
          clc
          adc  #node_size
          tay
          bcs  :ov
          cmp  #-node_size
          bcc  :loop
:ov
          ldy  #0
          bra  :loop


:no
          sty  index
          sec
          rts

:yes
          sty  index
          clc
          rts

*insert_entry_mx
*          php
*          rep  #$30         
*          jsr  insert_entry
*          bcc  :cc
*          plp
*          sec
*          rts
*:cc       plp
*          clc
*          rts
*          mx   %00

insert_entry
          mx   %00

          jsr  find_entry
          bcc  :dupe

* not found, so insert...

          inc  hash_count

          ldx  #0
]loop     lda  node,x
          sta  [table],y
          iny
          iny
          inx
          inx
          cpx  #node_size
          bcc  ]loop
* ldy index
          clc
          rts

:dupe
          iny
          iny
          lda  [table],y
          ora  flags
          sta  flags
          sta  [table],y
* dey
* dey
          sec
          rts


update_entry
* update an entry following a successful lookup
	mx %00

	ldy index
	iny
	iny
	lda [table],y
	ora flags
	sta flags
	sta [table],y
	rts

emplace_entry
* update an entry following an unsuccessful lookup

	mx %00

	inc hash_count
	ldy index

          ldx  #0
]loop     lda  node,x
          sta  [table],y
          iny
          iny
          inx
          inx
          cpx  #node_size
          bcc  ]loop
          clc
          rts



* hash[i+1] = (hash[i] * 33) ^ str[i+1]
* n.b. - string is a pstring, hashed backwards.
hash_node
          mx   %00
          ldy  #5381
          lda  name
          and  #$ff
          tax
]loop
          sty  hash
          tya
          asl
          asl
          asl
          asl
          asl
          clc
          adc  hash
          sta  hash
          lda  name,x
          and  #$00ff
          eor  hash
          tay
          dex
          bne  ]loop

          cpy  #0
          bne  :exit
          ldy  #5381
:exit
          sty  hash
          rts



* globals


hash_handle dl 0
hash_count dw  0

node
hash      dw   0
flags     dw   0
name      ds   name_size
* err (*-node)-node_size

          sav  macgen.1.l
