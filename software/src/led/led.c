#include <stdio.h>
#include <stdint.h>
#include <loongarch32r.h>
#include <device.h>

int main() {

    outl(LED_ADDR, 0x3f);
    return 0;
}
