

unsigned char _in8(unsigned short port) {
  unsigned char value;
  asm volatile("inb %1, %0" : "=a"(value) : "Nd"(port));
  return value;
}

unsigned short _in16(unsigned short port) {
  unsigned short value;
  asm volatile("inw %1, %0" : "=a"(value) : "Nd"(port));
  return value;
}

unsigned int _in32(unsigned short port) {
  unsigned int value;
  asm volatile("inl %1, %0" : "=a"(value) : "Nd"(port));
  return value;
}

void _out8(unsigned short port, unsigned char value) {
  asm volatile("outb %0, %1" ::"a"(value), "Nd"(port));
}

void _out16(unsigned short port, unsigned short value) {
  asm volatile("outw %0, %1" ::"a"(value), "Nd"(port));
}

void _out32(unsigned short port, unsigned int value) {
  asm volatile("outl %0, %1" ::"a"(value), "Nd"(port));
}
