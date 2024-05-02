#include "trap.h"

int main() {

    io_write(AM_GPIO_WRITE, 0x07);

    AM_GPIO_READ_T gpio2 = io_read(AM_GPIO_READ);

    for(volatile int i=0;i<1000000;i++);
    io_write(AM_GPIO_WRITE, gpio2.value);
    return 0;
}