#include <stdio.h>
#include <stdint.h>

#pragma GCC push_options
#pragma GCC optimize ("O0")

#define LED1 (*(volatile uint32_t *)0x1c00ffff)

int main() {
    LED1 = LED1&0;
    while(1);
    return 0;
}

#pragma GCC pop_options