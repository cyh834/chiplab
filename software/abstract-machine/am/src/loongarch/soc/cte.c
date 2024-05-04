#include <am.h>
#include <loongarch/loongarch32r.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    //uintptr_t ecode = 0;
    if(c->estat & 0x4){
      ev.event = EVENT_IRQ_TIMER;
    }
    else if(c->estat & 0x7){
      ev.event = EVENT_IRQ_UART0;
    }
    else{
      ev.event = EVENT_ERROR;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrwr %0, 0xc" : : "r"(__am_asm_trap));  // 0xc = eentry

  //$r12 = t0
  asm volatile("li.w $r12, 0");
  asm volatile("csrwr $r12, 0x4");

  //0x4 = ecfg
  //CSR.ECFG.LIE=0x1fff
  //局部中断使能位，高有效。这些局部中断使能位与 CSR.ESTAT 中 IS 域记录的 13 个中断源一一对应，每一位控制一个中断源。
  asm volatile("li.w $r12, 0x4");
  asm volatile("csrxchg $r12, $r12, 0x4");

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  return NULL;
}

void yield() {
  asm volatile("li.w $a7, -1; syscall 0");
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
        
        
  //0x0 = crmd
  //CSR.CRMD.IE=1
  //当前全局中断使能，高有效。当触发例外时，硬件将该域的值置为 0，以确保陷入后屏蔽中断。例外处理程序决定重新开启中断响应时，需显式地将该位置 1。
  asm volatile("li.w $r12, 0x4");
  asm volatile("csrxchg $r12, $r12, 0x0");

}
