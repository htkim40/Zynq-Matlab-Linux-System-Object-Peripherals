#include <unistd.h>
#include <stdint.h> 
#include <stdio.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>


#define BAUDRATE B19200
#define MODEMDEVICE "/dev/ttyS1" 
#define _POSIX_SOURCE 1 /* POSIX COMPLIANT SOURCE */

#ifndef __LINUX_RS232_HELPER__
#define __LINUX_RS232_HELPER__
int open_uart_RS232();
int close_uart_RS232();
//int read_uart_rs232(int fd, int buf_len,char *buf );
void write_uart_rs232(int fd, int char_len, char *msg[]);
#endif