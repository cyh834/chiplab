#ifndef DEVICE_H__
#define DEVICE_H__

// SRAM
#define SRAM_BASE 0x1c000000
#define SRAM_SIZE 0x40000
#define SRAM_BEGIN SRAM_BASE
#define SRAM_END (SRAM_BASE + SRAM_SIZE)

// GPIO
#define GPIO_BASE 0x1fd10000
#define GPIO_SIZE 0x10


#endif