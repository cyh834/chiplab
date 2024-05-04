#include "trap.h"

int main(){
    volatile uint32_t state = 0x0;
    while(1){
        printf("hello world!\r\n");
        io_write(AM_GPIO_WRITE, state);
        state = (state == 0) ? 0x3f : 0x0;
        for(volatile int i=0;i<1000000;i++);
    }
    return 0;
}