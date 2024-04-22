#include <stdio.h>
#include <stdint.h>

#pragma GCC push_options
#pragma GCC optimize ("O0")

#define LED1 (*(volatile uint32_t *)0x1c00ffff)

int main() {

    int k=0;
    for(int i=0; i<1000000; i++){
        k+=i;
    }
    LED1 = LED1&k;
    while(1);
    return 0;
}

#pragma GCC pop_options