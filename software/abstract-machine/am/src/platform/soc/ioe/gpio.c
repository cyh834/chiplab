#include <am.h>
#include <soc.h>
#include <klib.h>
#include <klib-macros.h>

void __am_gpio_read(AM_GPIO_READ_T *gpio) {
    gpio->value = inl(GPIO_ADDR+0x4);
}

void __am_gpio_write(AM_GPIO_WRITE_T *gpio) {
    outl(GPIO_ADDR, gpio->value);
}