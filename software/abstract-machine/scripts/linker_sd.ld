ENTRY(_start)

MEMORY {
  ROM (rxa) : ORIGIN = 0x1c000000, LENGTH = 512K
  RAM (rwxa) : ORIGIN = 0x20000000, LENGTH = 512M
}

SECTIONS {
  . = ORIGIN(ROM);
  .fsbl : {
    *(entry)
    *(.text._trm_init)
    *(.text.fsbl)
    . = ALIGN(0x10);
  } > ROM

  _ssbl_start = .;
  .ssbl : {
    _ssbl_load_start = .;
    *(.text.ssbl)
    *(.text._init_bss)
    . = ALIGN(0x10);
    _ssbl_load_end = .;
  } > RAM AT> ROM

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
    . = ALIGN(0x10);
    *(.srodata*)
    . = ALIGN(0x10);
  }> RAM AT> ROM

  .data :{
    /*VMA*/
    *(.data*)
    . = ALIGN(0x10);
    *(.sdata*)
    . = ALIGN(0x10);
    *(.got.plt) 
    . = ALIGN(0x10);
    *(.got) 
    . = ALIGN(0x10);
    p_load_end = .;
  }> RAM AT> ROM

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

  _ram_start = .;

  _stack_top = ALIGN(0x1000);
  . = _stack_top + 0x8000;
  _stack_pointer = .;
  end = .;
  _end = .;

  _heap_start = ALIGN(0x1000);

}