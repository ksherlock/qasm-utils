          lst  off

          xc
          xc
          mx   %00
          rel
          cas  se

          use  macgen.equ
          use  macgen.macs

          use  4:mem.macs
          use  4:int.macs
          use  4:util.macs


          ent  find_entry
          ent  insert_entry
          ent  update_entry
          ent  emplace_entry
          ent  name,flags


          ent  process_file
          ent  process_dir
          ent  buffer

          ext  process_src
          ext  process_mac_dir

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
          tdc
          sta  direct_page

          stx  cmdline+2
          sty  cmdline


          jsr  init


          jsr  getopt
          bcs  :exit



* pass 1 - scan infile for macros
* pass 2 - scan macrofiles for


          do   0
          pha
          pea  #1
          _SetTrace
          pla
          fin

          jsr  process_src

          do   0
          pha
          pea  #0
          _SetTrace
          pla
          fin


          jsr  dump
          lda  #0
:exit
          pha
          jsr  cleanup
          pla
          cmp  #1
          rtl


dump


          do   0
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
          lda  [table],y
          and  #$00ff
          bne  :ply         ; built-in
* bit 15 indicates it's used
* bit 14 indicate it's defined.

*          asl
*          bmi :ply ; built-in


*          tya
*   lda 1,s
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
          debug 'find_entry'
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
          debug 'insert_entry'
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
          mx   %00

          ldy  index
          iny
          iny
          lda  [table],y
          ora  flags
          sta  flags
          sta  [table],y
          rts

emplace_entry
* update an entry following an unsuccessful lookup

          mx   %00

          inc  hash_count
          ldy  index

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

**********


loadfile
* loads the file, updates fhandle, fptr, fsize



          pha
          pha               ; space
          phl  #input
          phl  #0           ; pos
          phl  #-1          ; eof
          phl  #txttypes    ; ftypes
          phw  myID
          phl  #0           ; address
          phw  #attrLocked.attrFixed.attrNoSpec
          _QALoadFile
          plx
          stx  fhandle
          plx
          stx  fhandle+2
          bcs  :err

          lda  [fhandle]
          sta  fptr
          ldy  #2
          lda  [fhandle],y
          sta  fptr+2

          ldy  #8           ; GetHandleSize
          lda  [fhandle],y
          sta  fsize
          iny
          iny
          lda  [fhandle],y
          sta  fsize+2

          clc
          rts
:err
          pha
          pha               ; save

          phl  #input
          _QADrawErrString
          phl  #:cosp
          _QADrawErrString
          _QAErrorMsg


          pla
          sec
          rts

:cosp     str  ': '



txttypes  db   $02,$04,$B0


call_line_rtn mac
*          per  end-1  ; qasm bug
          sep  #$20
          sty  line_start
          tyx               ; save
loop      lda  [fptr],y
          iny
          and  #$7f
          cmp  #$0d
          bne  loop
          sty  line_end
          txy               ;restore
          pea  end-1
          pei  line_rtn
          rts
end       rep  #$20
          ldy  line_end
          eom

process_file
* load

          jsr  loadfile
          bcc  :ok
          rts
:ok

          lda  fsize+2
          beq  :small



:large

]loop0
          ldy  #0
]loop
          call_line_rtn
          bpl  ]loop        ; since this is >= $01_0000, can't have eof in first $7fff bytes

* adjust ptrs, jump to small if possible...
          tya
          clc
          adc  fptr
          sta  fptr
          lda  #0
          adc  fptr+2
          sta  fptr+2

          lda  fsize
          sec
          phy
          sbc  1,s
          sta  fsize
          ply               ; restore

          lda  fsize+2
          sbc  #0
          sta  fsize+2
          bne  ]loop0

:small
          ldy  #0
]loop     call_line_rtn
          cpy  fsize
          bcc  ]loop


          phl  fhandle
          _DisposeHandle
          rts



process_dir


          ~QAReadDir #input;#:hook;#0
* bcs :err

* clc
          rts


:4        strl '4:'


:hook

* GetDirEntryRecGS offsets.
          dum  0
:pCount   ds   2
:refNum   ds   2
:flags    ds   2
:base     ds   2
:displacement ds 2
:name     ds   4
:entryNum ds   2
:fileType ds   2
:eof      ds   4
:blockCount ds 4
:createDateTime ds 8
:modDateDate ds 8
:access   ds   2
:auxType  ds   4
:fileSysID ds  2
:optionList ds 4
:resourceEOF ds 8
:resourceBlocks ds 8
          dend


          mx   %00
*          dum  1
*]ptr      ds   4
*]dcb      ds   4
*]y        ds   2
*          dend

          phb
          phk
          plb
          phd


          pha
          lda  direct_page
          tcd
          pla
          sta  dcb
          stx  dcb+2

*          tya ; $8000 indicates directory


          ldy  #:fileType
          lda  [dcb],y
          cmp  #$04
          beq  :txt
          cmp  #$b0
          beq  :txt
          bra  :return

:txt
* copy name over...


          ldy  #:name
          lda  [dcb],y
          clc
          adc  #2
          sta  ptr
          iny
          iny
          lda  [dcb],y
          adc  #0
          sta  ptr+2

          lda  [ptr]
          cmp  #MAX_PATH
          bcs  :return


          sep  #$20
          tax
          tay
          iny

          sta  input
]loop
          lda  [ptr],y
          sta  input+1,x
          dey
          dex
          bne  ]loop

          rep  #$20
          jsr  process_file

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







**********


getopt
          lda  #0
          ldy  #8

          php
          sep  #$20
          stz  input

* skip over name
]loop     lda  [cmdline],y
          beq  :err
          iny
          cmp  #' '+1
          bcs  ]loop

*skip over whitespace
]loop
          lda  [cmdline],y
          beq  :err
          iny
          cmp  #' '+1
          bcc  ]loop

* arg1 - input path...
* todo - quoting?

          ldx  #1
          sta  input+1
]loop
          lda  [cmdline],y
          beq  :eol
          iny
          cmp  #' '+1
          bcc  :1
          sta  input+1,x
          inx
          bra  ]loop
:1        txa
          sta  input

* only ws after...
]loop     lda  [cmdline],y
          beq  :rts
          iny
          cmp  #' '+1
          bcc  ]loop
* bra :err

:err
          plp
          jmp  help

:eol
          txa
          sta  input

:rts      plp
          clc
          rts

help
          mx   %00
          ~QADrawErrStr #:msg
          sec
          lda  #1
          rts
:msg      str  'Usage: macgen srcfile.s',0d


* globals


direct_page dw 0            ; must be global...

hash_handle dl 0
hash_count dw  0

node
hash      dw   0
flags     dw   0
name      ds   name_size
* err (*-node)-node_size



input     ds   1+MAX_PATH
buffer    ds   1024






          sav  macgen.1.l
