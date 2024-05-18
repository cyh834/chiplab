ENTRY(_start)
OUTPUT_FORMAT(elf32-loongarch);

MEMORY {
  RAM (rwxa) : ORIGIN = 0x1c000000, LENGTH = 512K
}

SECTIONS {
  . = ORIGIN(RAM);
  .text : {
    *(entry)
    *(.text*)
  } 
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  }
  .data : {
    *(.data*)
    *(.sdata*)
  } 
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  }

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
