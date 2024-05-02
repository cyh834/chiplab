#include "trap.h"

#define SPI_MASTER_BASE 0x10001000L
#define FLASH_ADDR_BEGIN 0x30000000L
#define FLASH_ADDR_end   0x3fffffffL

#define SPI_RX0     *(volatile uint32_t *)(SPI_MASTER_BASE + 0x0 )
#define SPI_RX1     *(volatile uint32_t *)(SPI_MASTER_BASE + 0x4 )
#define SPI_TX0     *(volatile uint32_t *)(SPI_MASTER_BASE + 0x0 )
#define SPI_TX1     *(volatile uint32_t *)(SPI_MASTER_BASE + 0x4 )
#define SPI_CTRL    *(volatile uint32_t *)(SPI_MASTER_BASE + 0x10)
#define SPI_DIVIDER *(volatile uint32_t *)(SPI_MASTER_BASE + 0x14)
#define SPI_SS      *(volatile uint32_t *)(SPI_MASTER_BASE + 0x18)
#define CTRL_GO_BSY (1 << 8)
/*CTRL
  ASS:1
  IE:0
  LSB:0    先传输高位
  Tx_NEG:0 SCLK上升沿输出
  Rx_NEG:0 SCLK上升沿输入
  CHAR_LEN:0x10  16bits

Bit#    31:14     13    12  11    10      9         8       7         6:0 
Access  R         R/W   R/W R/W   R/W     R/W       R/W     R         R/W 
Name    Reserved  ASS   IE  LSB   Tx_NEG  Rx_NEG    GO_BSY  Reserved  CHAR_LEN
                  1     0   0     1       0         1       0         100_0000 
*/
char hex[16]={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
void putch_num(uint32_t num){
    char ans[8];
    for(int i=0;i<8;i++){
      ans[i]=hex[num&0xf];
      num >>=4;
    }
    for(int i=7;i>=0;i--){
      putch(ans[i]);
    }
    putch('\n');
 
}

uint32_t flash_read(uint32_t addr){
  SPI_TX0 = 00;
  SPI_TX1 = (0x03000000) | (addr&0xfffffc);

  SPI_DIVIDER = 0x0;
  SPI_SS = 0x1;

  SPI_CTRL = 0x2440;
  SPI_CTRL = 0x2440 | CTRL_GO_BSY;
  while(SPI_CTRL&CTRL_GO_BSY);

  uint32_t data = SPI_RX0;
  data = ((data & 0xff) << 24) | ((data & 0xff00) << 8) | ((data & 0xff0000) >> 8) | ((data & 0xff000000) >> 24);
  putch_num(data);
  return data;
}

uint32_t flash_xip_read(uint64_t addr){
  uint32_t data = *(volatile uint32_t *)addr;
  putch_num(data);
  return data;
}

int main() {
  uint32_t addr = 0x30000000;
  for(int i=0;i<10;i++){
    flash_read(addr+i*4);
  }
  //SPI_DIVIDER = 0x1;
  //SPI_SS = 0x80;

  //for(int i=0;i<0x20;i++){
  //  SPI_TX0= i;
  //  SPI_CTRL = 0x2f10;

  //  while(SPI_CTRL&0x100);
  //  uint32_t num = SPI_RX0;
  //  putch_num(num);
  //}  
  //return 0;
}

