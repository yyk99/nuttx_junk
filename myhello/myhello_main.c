#include <nuttx/config.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <nuttx/ioexpander/gpio.h>

/* Blinks the XIAO ESP32C6 user LED (GPIO15, active low) via /dev/gpio0.
 * Usage: myhello [count]   (default 10 blinks)
 */

int main(int argc, FAR char *argv[])
{
    int count = argc > 1 ? atoi(argv[1]) : 10;
    int fd = open("/dev/gpio0", O_RDWR);
    int i;

    printf("Hello from myhello! Blinking LED %d times\n", count);

    if (fd < 0) {
        printf("Cannot open /dev/gpio0 (is CONFIG_DEV_GPIO enabled?)\n");
        return 1;
    }

    for (i = 0; i < count; i++) {
        ioctl(fd, GPIOC_WRITE, 0); /* LED on (active low) */
        usleep(500000);
        ioctl(fd, GPIOC_WRITE, 1); /* LED off */
        usleep(500000);
    }

    close(fd);
    return 0;
}
