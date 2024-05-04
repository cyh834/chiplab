#include <am.h>
#include <soc.h>
#include <klib.h>
#include <klib-macros.h>

//#define UART_FIFO UART_ADDR
//#define UART_FIFO_CTRL (UART_ADDR + 0x4)

void __am_uart_read(AM_UART_RX_T *uart) {
  uint8_t data = inb(UART_ADDR);
  uart->data = (data == 0 ? 0xff : data);
}

void __am_uart_write(AM_UART_TX_T *uart) {
  //wait until Transmit FIFO is empty
  uint8_t empty;
  do{
    empty = inb(UART_ADDR + 0x5) & 0x20;
  }while(empty == 0);
  outb(UART_ADDR, uart->data);
  //while((inb(UART_FIFO_CTRL) & 0x02) == 0x02);
  //outb(UART_FIFO, uart->data);
  //delay_ms(25);
}
//void __am_uart_config(AM_UART_CONFIG_T *cfg){
//  //UART_FIFO_CTRL[2]为1开启奇校验
//  uint32_t ctrl = cfg->odd ? 4 : 0; 
//
//	// Baudrate = 9600 = 8Mhz / (208.333 * 4)
//	// Baudrate = 19200 = 8Mhz / (104.166 * 4)
//	// Baudrate = 38400 = 8Mhz / (52.083 * 4)
//	// Baudrate = 115200 = 8Mhz / (17.361 * 4)
//  switch(cfg->baud){
//    case 9600  : ctrl |= 0; break;
//    case 19200 : ctrl |= 1; break;
//    case 38400 : ctrl |= 2; break;
//    case 115200: ctrl |= 3; break;
//    default: halt(0);
//  }
//  outl(UART_FIFO_CTRL,ctrl);
//  
//  //配置后需要延时至少 2000ms ，才能进行串口发送
//  delay_ms(2000);
//  
//}

void __am_uart_init(){
  outb(UART_ADDR + 0x3, 0x83); // LCR <= 8N1, DLA
  //outb(UART_ADDR + 0x1, 0);  // DLA.MSB
  // DL = clk / (16 * baud rate) = 25MHz / (16 * 115200) = 13.56 = 14
  outb(UART_ADDR + 0x0, 4); // DLA.LSB
  outb(UART_ADDR + 0x3, 0x3);  // LCR <= 8N1
}