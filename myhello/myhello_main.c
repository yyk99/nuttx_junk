#include <nuttx/config.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <nuttx/ioexpander/gpio.h>

/* Blinks the board user LED via CONFIG_MYHELLO_GPIO_DEVPATH (XIAO ESP32C6: GPIO15, active
 * low; Nucleo-F767ZI: LD1 on PB0, active high).
 * Usage: myhello [count]   (default 10 blinks)
 */

#ifdef CONFIG_MYHELLO_LED_ACTIVE_LOW
#define LED_ON  0
#define LED_OFF 1
#else
#define LED_ON  1
#define LED_OFF 0
#endif

int main(int argc, FAR char *argv[])
{
    int count = argc > 1 ? atoi(argv[1]) : 10;
    int fd = open(CONFIG_MYHELLO_GPIO_DEVPATH, O_RDWR);
    int i;

    printf("Hello from myhello! Blinking LED %d times\n", count);

    if (fd < 0) {
        printf("Cannot open %s (is CONFIG_DEV_GPIO enabled?)\n",
               CONFIG_MYHELLO_GPIO_DEVPATH);
        return 1;
    }

    for (i = 0; i < count; i++) {
        if (ioctl(fd, GPIOC_WRITE, LED_ON) < 0) {
            printf("GPIOC_WRITE failed (not an output pin?)\n");
            close(fd);
            return 1;
        }
        usleep(500000);
        ioctl(fd, GPIOC_WRITE, LED_OFF);
        usleep(500000);
    }

    close(fd);
    return 0;
}
