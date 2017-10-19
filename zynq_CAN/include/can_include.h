#include <unistd.h>
#include <stdint.h> 
#include <sys/param.h>


#ifndef __LINUX_CAN_HELPER__
#define __LINUX_CAN_HELPER__

int getCANSocket(const char *devName, uint32_t nfilters, uint32_t *ids, uint32_t *masks);
int sendCANData(int s, uint32_t id, uint8_t len, uint8_t *data);
int recvCANData(int skt, double timeout, uint32_t *id, uint8_t *len, uint8_t *data);
int getRecvTimestamp(int skt, double *timestamp);
void closeCANSocket(int s);

#endif /* __LINUX_CAN_HELPER__ */