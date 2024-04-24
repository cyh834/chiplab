.section entry, "ax"
.globl _start
.type _start, @function


_start:
_cpu_init:
  addi.w $ra, $r0, 0
  addi.w $tp, $r0, 0
  addi.w $sp, $r0, 0
  addi.w $a0, $r0, 0
  addi.w $a1, $r0, 0
  addi.w $a2, $r0, 0
  addi.w $a3, $r0, 0
  addi.w $a4, $r0, 0
  addi.w $a5, $r0, 0
  addi.w $a6, $r0, 0
  addi.w $a7, $r0, 0
  addi.w $t0, $r0, 0
  addi.w $t1, $r0, 0
  addi.w $t2, $r0, 0
  addi.w $t3, $r0, 0
  addi.w $t4, $r0, 0
  addi.w $t5, $r0, 0
  addi.w $t6, $r0, 0
  addi.w $t7, $r0, 0
  addi.w $t8, $r0, 0
  addi.w $x , $r0, 0
  addi.w $fp, $r0, 0
  addi.w $s0, $r0, 0
  addi.w $s1, $r0, 0
  addi.w $s2, $r0, 0
  addi.w $s3, $r0, 0
  addi.w $s4, $r0, 0
  addi.w $s5, $r0, 0
  addi.w $s6, $r0, 0
  addi.w $s7, $r0, 0
  addi.w $s8, $r0, 0
  pcaddu12i $t0, 0
  ld.w $t0, $t0, 0
  pcaddu12i $t1, 0
  ld.w $t1, $t1, 0

__main:
  move $fp, $zero
  la.local $sp, _stack_pointer
  bl main
  syscall 0x11