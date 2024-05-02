ENTRY(_start)

MEMORY {
  STACK : ORIGIN = 0x0f000000, LENGTH = 8K 
  ROM   : ORIGIN = 0x30000000, LENGTH = 256M
  RAM   : ORIGIN = 0xa0000000, LENGTH = 64M
}

SECTIONS {
  . = ORIGIN(ROM);
  .fsbl : {
    *(entry)
    *(.text._trm_init)
    *(.text.fsbl)
    *(.text.putch_num)
    . = ALIGN(0x10);
  } > ROM

  _ssbl_start = .;
  .ssbl : {
    _ssbl_load_start = .;
    *(.text.ssbl)
    . = ALIGN(0x10);
    _ssbl_load_end = .;
  } > RAM AT> ROM

  /*
  .bootloader : {
    *(entry)
    *(.text._trm_init)
    *(.text.putch_num)
    *(.text.bootloader)
    . = ALIGN(0x10);
  }> ROM
  */
  p_start = LOADADDR(.text);
  .text : {
    p_load_start = .;
    *(.text*)
    . = ALIGN(0x10);
  }> RAM AT> ROM
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
    *(.srodata*)
    . = ALIGN(0x10);
  }> RAM AT> ROM

  .data :{
    /*VMA*/
    /*data_start = .;*/
    *(.data*)
    *(.sdata*)
    /*data_end = .;*/
    . = ALIGN(0x10);
    p_load_end = .;
  }> RAM AT> ROM
  /*LMA*/
  /*data_load_start = LOADADDR(.data);*/

  edata = .;
  _data = .;
  .bss : {
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(0x10);
    _bss_end = .;
  }> RAM
  /*_stack_top = ORIGIN(STACK) + LENGTH(STACK)- 0x1000;
  . = _stack_top + 0x1000;
  _stack_pointer = . ;  ORIGIN(STACK) + LENGTH(STACK) ;*/
  _heap_start = _bss_end;
  _ram_start = ORIGIN(RAM);
  _ram_size = LENGTH(RAM);

  end = .;
  _end = .;
}