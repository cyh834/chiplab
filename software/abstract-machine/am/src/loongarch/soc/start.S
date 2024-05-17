.section entry, "ax"
.globl _start
.type _start, @function

#define concat_temp(x, y) x ## y
#define concat(x, y) concat_temp(x, y)
#define MAP(c, f) c(f)

#define REGS(f) \
      f( 1) f( 2)       f( 4) f( 5) f( 6) f( 7) f( 8) f( 9) \
f(10) f(11) f(12) f(13) f(14) f(15) f(16) f(17) f(18) f(19) \
f(20) f(21) f(22) f(23) f(24) f(25) f(26) f(27) f(28) f(29) \
f(30) f(31)

#define INIT(n) li.w $concat(r, n), 0x0; 

#define CRMD            0x0
#define PRMD            0x1
#define ECTL            0x4
#define ESTAT           0x5
#define ERA             0x6
#define BADV            0x7
#define EENTRY          0xc
#define TLBIDX          0x10
#define TLBEHI          0x11
#define TLBELO0         0x12
#define TLBELO1         0x13
#define ASID            0x18
#define PGDL            0x19
#define PGDH            0x1a
#define PGD             0x1b
#define CPUID           0x20
#define SAVE0           0x30
#define SAVE1           0x31
#define SAVE2           0x32
#define SAVE3           0x33
#define TID             0x40
#define TCFG            0x41
#define TVAL            0x42
#define CNTC            0x43
#define TICLR           0x44
#define LLBCTL          0x60
#define TLBRENTRY       0x88
#define DMW0            0x180
#define DMW1            0x181
#define BRK             0x100
#define DISABLE_CACHE   0x101

_start:
  #init csr
  li.w $t0, 0x0
##li.w $t1, 0xa8        # DA = 1, enable icache & dcache
  li.w $t1, 0x8         # DA = 1,
  li.w $t2, 0xa0000     #ASIDBITS = 10
  csrwr $t1, CRMD  
  csrwr $t0, PRMD  
  csrwr $t0, ECTL  
  csrwr $t0, ESTAT 
  csrwr $t0, ERA   
  csrwr $t0, BADV  
  csrwr $t0, EENTRY
  csrwr $t0, TLBIDX
  csrwr $t0, TLBEHI
  csrwr $t0, TLBELO0
  csrwr $t0, TLBELO1
  csrwr $t2, ASID  
  csrwr $t0, PGDL  
  csrwr $t0, PGDH  
  csrwr $t0, PGD   
  csrwr $t0, CPUID 
  csrwr $t0, SAVE0 
  csrwr $t0, SAVE1 
  csrwr $t0, SAVE2 
  csrwr $t0, SAVE3 
  csrwr $t0, TID   
  csrwr $t0, TCFG  
  csrwr $t0, TVAL  
  csrwr $t0, CNTC  
  csrwr $t0, TICLR 
  csrwr $t0, LLBCTL
  csrwr $t0, TLBRENTRY
  csrwr $t0, DMW0  
  csrwr $t0, DMW1  
  csrwr $t0, BRK  
  csrwr $t0, DISABLE_CACHE
  
  #init gpr
  MAP(REGS, INIT)

  move $fp, $zero
  la.local $sp, _stack_pointer

boot:
  la.local $t0, p_start
  la.local $t1, p_load_start
  la.local $t2, p_load_end

loop:
  beq $t1, $t2, _trm_init
  ld.w $t3,$t0, 0
  st.w $t3,$t1, 0
  addi.w $t0,$t0,4
  addi.w $t1,$t1,4
  bl loop