#include <stdio.h>
#include <stdint.h>

#define LED1 (*(volatile uint32_t *)0x1c00ffff)

int main() {

    LED1 = LED1&0;
    while(1);
    return 0;
}
