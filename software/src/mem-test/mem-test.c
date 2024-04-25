#include <stdio.h>
#include <loongarch32r.h>
#include <device.h>

int main() {
    //前面存放代码段什么的，不能覆盖
    for(int i = SRAM_BEGIN+0x20000; i < SRAM_END; i += 4) {
        outl(i, i);
    }
    for(int i = SRAM_BEGIN+0x20000; i < SRAM_END; i += 4) {
        int in = inl(i);
        if(in != i) {
            return -1;
        }
    }
    return 0;
}
