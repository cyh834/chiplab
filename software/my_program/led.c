#include <stdio.h>
#include <stdint.h>
#include <unistd.h> // For usleep()

#define LED1 (*(uint32_t *)(0x1c00ffff)) //此处修改内存地址

int main() {
    uint32_t *led = &LED1;


    // Read initial state (optional, assuming it's not critical)
    uint32_t initial_state = *led;

	*led=*led|1;

    // Restore initial state (optional)
    *led = initial_state;

    return 0;
}
