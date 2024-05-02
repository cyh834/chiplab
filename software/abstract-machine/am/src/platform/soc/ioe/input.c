#include <am.h>
#include <soc.h>
#include <klib.h>
#include <klib-macros.h>

//#define KEYDOWN_MASK 0x8000

//按键扫描码转AM定义的键盘码
#define PS2(scancode,key) [scancode] = AM_KEY_##key
static uint8_t ps2_keys_1B[0xff] = {
PS2(0x00,NONE),
PS2(0x76,ESCAPE),PS2(0x05,F1),PS2(0x06,F2),PS2(0x04,F3),PS2(0x0C,F4),PS2(0x03,F5),
PS2(0x0B,F6),PS2(0x83,F7),PS2(0x0A,F8),PS2(0x01,F9),PS2(0x09,F10),PS2(0x78,F11),
PS2(0x07,F12),PS2(0x0E,GRAVE),PS2(0x16,1),PS2(0x1E,2),PS2(0x26,3),PS2(0x25,4),
PS2(0x2E,5),PS2(0x36,6),PS2(0x3D,7),PS2(0x3E,8),PS2(0x46,9),PS2(0x45,0),
PS2(0x4E,MINUS),PS2(0x55,EQUALS),PS2(0x66,BACKSPACE),PS2(0x0D,TAB),PS2(0x15,Q),
PS2(0x1D,W),PS2(0x24,E),PS2(0x2D,R),PS2(0x2C,T),PS2(0x35,Y),PS2(0x3C,U),
PS2(0x43,I),PS2(0x44,O),PS2(0x4D,P),PS2(0x54,LEFTBRACKET),PS2(0x5B,RIGHTBRACKET),
PS2(0x5D,BACKSLASH),PS2(0x58,CAPSLOCK),PS2(0x1C,A),PS2(0x1B,S),PS2(0x23,D),
PS2(0x2B,F),PS2(0x34,G),PS2(0x33,H),PS2(0x3B,J),PS2(0x42,K),PS2(0x4B,L),
PS2(0x4C,SEMICOLON),PS2(0x52,APOSTROPHE),PS2(0x5A,RETURN),PS2(0x12,LSHIFT),
PS2(0x1A,Z),PS2(0x22,X),PS2(0x21,C),PS2(0x2A,V),PS2(0x32,B),PS2(0x31,N),
PS2(0x3A,M),PS2(0x41,COMMA),PS2(0x49,PERIOD),PS2(0x4A,SLASH),PS2(0x59,RSHIFT),
PS2(0x14,LCTRL),PS2(0x11,LALT),PS2(0x29,SPACE)
};
  
static uint8_t ps2_keys_E0[0xff] = {
PS2(0x2F,APPLICATION),PS2(0x11,RALT),PS2(0x14,RCTRL),PS2(0x75,UP),
PS2(0x72,DOWN),PS2(0x6B,LEFT),PS2(0x74,RIGHT),PS2(0x70,INSERT),PS2(0x71,DELETE),
PS2(0x6C,HOME),PS2(0x69,END),PS2(0x7D,PAGEUP),PS2(0x7A,PAGEDOWN)
};


void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t k=inb(KBD_ADDR);
  int extcode=0;
  if(k==0xE0){//拓展码
    k=inl(KBD_ADDR);
    extcode=1;
  }
  if(k==0xF0){//断码
    k=inl(KBD_ADDR);
    kbd->keydown = false;
  }
  else{
    kbd->keydown = true;
  }
  kbd->keycode = extcode ? ps2_keys_E0[k] : ps2_keys_1B[k];
}

void __am_input_init(){
}