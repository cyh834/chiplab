ENTRY(_start)
OUTPUT_FORMAT(elf32-loongarch);

MEMORY {
  ROM (rxa) : ORIGIN = 0x1c000000, LENGTH = 256M
  RAM (rwxa) : ORIGIN = 0x1b000000, LENGTH = 512K
}

SECTIONS {
  . = ORIGIN(ROM);
  .bl : {
    *(entry)
    *(.text._trm_init)
    . = ALIGN(0x10);
  } > ROM

  .text : {
    *(.text*)
    . = ALIGN(0x10);
  }> ROM
  etext = .;
  _etext = .;

  .rodata : {
    *(.rodata*)
    . = ALIGN(0x10);
    *(.srodata*)
    . = ALIGN(0x10);
  }> ROM

  p_start = .;
  .data :{
    p_load_start = .;
    /*VMA*/
    *(.data*)
    . = ALIGN(0x10);
    *(.sdata*)
    . = ALIGN(0x10);

  }> RAM AT> ROM

  edata = .;
  _data = .;

  .got : {
    *(.got.plt) 
    . = ALIGN(0x10);
    *(.got) 
    . = ALIGN(0x10);
    p_load_end = .;
  }> RAM AT> ROM

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
  _heap_end = ORIGIN(RAM) + LENGTH(RAM);
  _ram_end = ORIGIN(RAM) + LENGTH(RAM);

}