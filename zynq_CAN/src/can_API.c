#include <unistd.h>
#include <stdint.h>
#include <stdio.h>     
#include <stdlib.h>
#include <string.h>
#include <net/if.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <sys/param.h>
#include <poll.h>
#include <time.h>
#include "can_include.h"


/*******************************************************************************
 * @brief timespec_normalize
*******************************************************************************/
static inline void timespec_normalize(struct timespec *ts)
{
	// normalize
	while(ts->tv_nsec >= 1000*1000*1000){
		ts->tv_sec++;
		ts->tv_nsec -= 1000*1000*1000;
	}
}

/*******************************************************************************
 * @brief dbl_to_timespec
*******************************************************************************/
static inline void dbl_to_timespec(struct timespec *ts, double sec)
{
	// convert to nanoseconds
	ts->tv_sec = (__time_t)(sec);
	ts->tv_nsec = (__syscall_slong_t)((sec*1.0E9) - ((double)ts->tv_sec*1.0E9));

	//Normalize
	timespec_normalize(ts);
}
/*******************************************************************************
 * @brief getCANSocket
*******************************************************************************/
int getCANSocket(const char *devName, uint32_t nfilters, uint32_t *ids, uint32_t *masks)
{
	struct sockaddr_can addr;
	struct canfd_frame frame;
	struct ifreq ifr;
	struct can_filter *rfilter;
	int i;
	int skt;
		
	skt = socket(PF_CAN, SOCK_RAW, CAN_RAW);
	if ( skt < 0 ) {
		perror("Failed to create CAN socket");
		return -errno;
	} 

	strncpy(ifr.ifr_name, devName, sizeof(ifr.ifr_name));

	if (ioctl(skt, SIOCGIFINDEX, &ifr) < 0) {
		perror("Failed to find CAN device");
		return -errno;
	}
	addr.can_family = AF_CAN;
	addr.can_ifindex = ifr.ifr_ifindex;

	if (nfilters > 0) {
		rfilter = malloc(sizeof(struct can_filter)*nfilters);
		if (!rfilter) {
			printf("Error: Failed to allocate filter memory\n");
			return -ENOMEM;
		}
		for (i = 0; i < nfilters; i++){
			rfilter[i].can_id = (canid_t)ids[i];
			rfilter[i].can_mask = (canid_t)masks[i];
		}
		setsockopt(skt, SOL_CAN_RAW, CAN_RAW_FILTER, rfilter, nfilters * sizeof(struct can_filter));
	}
	
	if (bind(skt, (struct sockaddr *)&addr, sizeof(addr))) {
		perror("CAN bind");
		return -errno;
	}
	
	return skt;
}

/*******************************************************************************
 * @brief sendCANData
*******************************************************************************/
int sendCANData(int skt, uint32_t id, uint8_t len, uint8_t *data)
{
    /* Send CAN frame */
    struct canfd_frame frame;
    int i;
	ssize_t nbytes;

    frame.can_id = (canid_t)id;
    frame.len = len;
    memcpy(frame.data, data, (size_t)len);
	
	nbytes = write(skt, &frame, CAN_MTU);
    if (nbytes != CAN_MTU) {
		if (nbytes < 0) {
			perror("CAN write");
			return -errno;
		} else {
			printf("ERROR: Incorrect number of bytes sent: %d\n", nbytes);
			return -ECOMM;
		}
	}
	return 0;
}

/*******************************************************************************
 * @brief recvCANData
*******************************************************************************/
int recvCANData(int skt, double timeout, uint32_t *id, uint8_t *len, uint8_t *data)
{
    /* Get CAN frame */
	int status;
	struct timespec ts;
	struct timespec *pTS;
	static fd_set rdfs;
	
    static struct iovec iov;
	static struct msghdr msg;
	static struct canfd_frame frame;
	static char ctrlmsg[CMSG_SPACE(sizeof(struct timeval)) + CMSG_SPACE(sizeof(__u32))];
	static struct sockaddr_can addr;
	
	ssize_t nbytes;

	/* These settings are static and can be held out of the hot path */
	iov.iov_base  = &frame;
	msg.msg_name  = &addr;
	msg.msg_iov	= &iov;
	msg.msg_iovlen = 1;
	msg.msg_control = &ctrlmsg;
	
	if (timeout >= 0.0){
		dbl_to_timespec(&ts, timeout);
		pTS = &ts;
	} else {
		pTS = NULL;
	}
	
	FD_ZERO(&rdfs);
	FD_SET(skt, &rdfs);
	
	status = pselect (skt+1, &rdfs, NULL, NULL, pTS, NULL);
	if( status < 0){
        perror("CAN pselect error");
		return -errno;
	}
	
	if (status) {
		/* These settings may be modified by recvmsg() */
        iov.iov_len = sizeof(frame);
        msg.msg_namelen = sizeof(addr);
        msg.msg_controllen = sizeof(ctrlmsg);
        msg.msg_flags = 0;
		
		nbytes = read(skt, &frame, CANFD_MTU);
		if (nbytes < 0) {
			perror("CAN recvmsg error");
			return -errno;
        } else {
			*id = frame.can_id;
			*len = frame.len;
			memcpy(data, frame.data, frame.len);
		}
	} else {
		return -ETIMEDOUT;
	}
	return 0;
}

/*******************************************************************************
 * @brief getRecvTimestamp
*******************************************************************************/
int getRecvTimestamp(int skt, double *timestamp)
{
	int status;
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	status = ioctl(skt, SIOCGSTAMP, &tv);
	if (!status){
		*timestamp = (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
	}
	return status;
}

/*******************************************************************************
 * @brief closeCANSocket
*******************************************************************************/
void closeCANSocket(int skt)
{
	if (skt != 0) {
		close(skt);
	}
}