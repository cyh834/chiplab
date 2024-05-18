#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
static unsigned long int next = 1;

int rand(void) {
  // RAND_MAX assumed to be 32767
  next = next * 1103515245 + 12345;
  return (unsigned int)(next/65536) % 32768;
}

void srand(unsigned int seed) {
  next = seed;
}

int abs(int x) {
  return (x < 0 ? -x : x);
}

int atoi(const char* nptr) {
  int x = 0;
  while (*nptr == ' ') { nptr ++; }
  while (*nptr >= '0' && *nptr <= '9') {
    x = x * 10 + *nptr - '0';
    nptr ++;
  }
  return x;
}

static void *pf = NULL;

void init_mm(){
  pf = (void *)heap.start;
  printf("heap: [%p, %p]\n", pf, heap.end);
}

void *malloc(size_t size) {
  void *ret = pf;
  pf += size;

  if((uint32_t)pf > (uint32_t)heap.end){
    printf("0x%x 0x%x 0x%x\n", size, (uint32_t)pf, (uint32_t)heap.end);
    assert(0);
  }
  return ret;

  //#if !(defined(__ISA_NATIVE__) && defined(__NATIVE_USE_KLIB__))
  //  panic("Not implemented");
  //#endif
  //return NULL;
}

void free(void *ptr) {
}

#endif
