#ifndef SERIAL_H
#define SERIAL_H


_Static_assert(sizeof(unsigned char) == 1,"");
_Static_assert(sizeof(unsigned short) == 2,"");
_Static_assert(sizeof(unsigned int) == 4,"");

extern unsigned char _in8(unsigned short port);
extern unsigned short _in16(unsigned short port);
extern unsigned int _in32(unsigned short port);
extern void _out8(unsigned short port, unsigned char value);
extern void _out16(unsigned short port, unsigned short value);
extern void _out32(unsigned short port, unsigned int value);

#endif // SERIAL_H
