

attrBank  equ  $0001
attrAddr  equ  $0002
attrPage  equ  $0004
attrNoSpec equ $0008
attrNoCross equ $0010
attrFixed equ  $4000
attrLocked equ $8000

readEnable equ $0001
writeEnable equ $0002

FLAG_INSTR equ 1
FLAG_MAC  equ  2
FLAG_EOM  equ  3
FLAG_PMC  equ  4
FLAG_PUT  equ  5


node_size equ  36
name_size equ  32

* direct page
          dum  0

line_rtn  dw   0

myID      dw   0


table     dl   0
index     dw   0

line      dl   0

line_start dw 0
line_end dw 0



ptr       dl   0


r0        dw   0
r1        dw   0
r2        dw   0


fhandle   dl   0
fsize     dl   0
fptr      dl   0

          err  *>256
          dend
