#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>

#define BAUDRATE B19200
#define MODEMDEVICE "/dev/ttyPS1" 
#define _POSIX_SOURCE 1 /* POSIX COMPLIANT SOURCE */
#define FALSE 0
#define TRUE 1

volatile int STOP = FALSE; /*Will be used in test only */



int open_uart_RS232()
{
     int fd; 
     struct termios oldtio, newtio; 
     //char buf[255]; 

     fd = open(MODEMDEVICE, O_RDWR|O_NOCTTY);
     if (fd <0){perror(MODEMDEVICE); exit(-1);} 

     tcgetattr(fd, &oldtio); /* save current port settings */

     bzero(&newtio, sizeof(newtio));
     newtio.c_cflag = BAUDRATE | CRTSCTS | CS8 |CLOCAL |CREAD;
     newtio.c_iflag = IGNPAR | ICRNL;
     newtio.c_oflag = 0; 

     /* set input mode (canonical, no echo, ...) */ 
     newtio.c_lflag = ICANON; 
     
     newtio.c_cc[VINTR]    = 0;     /* Ctrl-c */ 
     newtio.c_cc[VQUIT]    = 0;     /* Ctrl-\ */
     newtio.c_cc[VERASE]   = 0;     /* del */
     newtio.c_cc[VKILL]    = 0;     /* @ */
     newtio.c_cc[VEOF]     = 4;     /* Ctrl-d */
     newtio.c_cc[VTIME]    = 0;     /* inter-character timer unused */
     newtio.c_cc[VMIN]     = 0;     /* blocking read until 1 character arrives */
     newtio.c_cc[VSWTC]    = 0;     /* '\0' */
     newtio.c_cc[VSTART]   = 0;     /* Ctrl-q */ 
     newtio.c_cc[VSTOP]    = 0;     /* Ctrl-s */
     newtio.c_cc[VSUSP]    = 0;     /* Ctrl-z */
     newtio.c_cc[VEOL]     = 0;     /* '\0' */
     newtio.c_cc[VREPRINT] = 0;     /* Ctrl-r */
     newtio.c_cc[VDISCARD] = 0;     /* Ctrl-u */
     newtio.c_cc[VWERASE]  = 0;     /* Ctrl-w */
     newtio.c_cc[VLNEXT]   = 0;     /* Ctrl-v */
     newtio.c_cc[VEOL2]    = 0;     /* '\0' */
  
     tcflush(fd, TCIFLUSH); /*discards data written to fd, but not read
                             *TCIFLUSH : data received but not read
                             *TCOFLUSH : data written but not transmitted 
                             *TCIOFLUSH : data received but not read and
                             *data written but not transmitted */
     tcsetattr(fd,TCSANOW, &newtio); /* set fd to have parameters from newtio
                                      *TCSANOW : set it immediately
                                      *TCSADRAIN : set after all data is transmitted 
                                      *TCSAFLUSH : set after all data is transmitted,
                                      *and all input so far are received */
    return fd;
};

void close_uart_RS232(int fd)
{
    if (fd!=0)
    {
    fd = close(fd);
    }   
};

// int read_uart_rs232(int fd, int buf_len, char *buf )
// {
//     int res; 
//     res = read (fd, buf, buf_len);
//     //buf[res] = 0;
//     return res;
// };

void write_uart_rs232(int fd, int char_len, char *msg[])
{
   
   if (char_len > 0) //do nothing if no characters to send
   {
       char *tx_msg =  msg[1]; // must be done otherwise passes a c literal
       write(fd, msg, char_len);
   }
};