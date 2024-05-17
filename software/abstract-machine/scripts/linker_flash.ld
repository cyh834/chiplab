ENTRY(_start)

MEMORY {
  ROM (rxa) : ORIGIN = 0x1c000000, LENGTH = 256M
  RAM (rwxa) : ORIGIN = 0x60000000, LENGTH = 512K
}

SECTIONS {
  . = ORIGIN(ROM);
  .text : {
    *(entry)
    *(.text*)
    . = ALIGN(0x10);
  } > ROM
  etext = .;
  _etext = .;

  .rodata : {
    *(.rodata*)
    . = ALIGN(0x10);
    *(.srodata*)
    . = ALIGN(0x10);
  } > ROM

  p_start = LOADADDR(.data);
  .data :{
    /*VMA*/
    p_load_start = .;
    *(.data*)
    . = ALIGN(0x10);
    *(.sdata*)
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