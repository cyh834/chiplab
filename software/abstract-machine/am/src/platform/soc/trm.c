#include <am.h>
#include <soc.h>
#include <klib-macros.h>
#include <klib.h>

extern char _heap_start;

int main(const char *args);

Area heap = RANGE(&_heap_start, RAM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  io_write(AM_UART_TX, ch);
}

void halt(int code) {
  soc_trap(code);

  // should not reach here
  while (1);
}

void _trm_init() {

  ioe_init();
  init_mm();
  int ret = main(mainargs);
  halt(ret);
}