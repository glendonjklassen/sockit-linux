#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define LW_BRIDGE_BASE 0xFF200000UL
#define MAP_SPAN       0x1000UL
#define LED_OFFSET     0x0000UL
#define KEY_OFFSET     0x0010UL

int main(void) {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        fprintf(stderr, "open(/dev/mem) failed: %s\n", strerror(errno));
        return 1;
    }

    /*
     * Map the lightweight HPS-to-FPGA bridge window into userspace.
     * The bridge base is 0xFF200000 on Cyclone V SoC systems.
     */
    void *map = mmap(NULL, MAP_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, LW_BRIDGE_BASE);
    close(fd);

    if (map == MAP_FAILED) {
        fprintf(stderr, "mmap failed: %s\n", strerror(errno));
        return 1;
    }

    /*
     * These offsets come from the Platform Designer system:
     *   LED PIO -> 0x0000
     *   KEY PIO -> 0x0010
     *
     * From software, "talking to the FPGA" is just reading and writing
     * memory-mapped registers in this bridge window.
     */
    volatile uint32_t *led_reg = (volatile uint32_t *)((uint8_t *)map + LED_OFFSET);
    volatile uint32_t *key_reg = (volatile uint32_t *)((uint8_t *)map + KEY_OFFSET);

    puts("Writing LED patterns through the HPS-to-FPGA lightweight bridge.");
    puts("Press KEY[1:0] on the FPGA side to see the sampled value.");

    for (uint32_t value = 0; value < 16; ++value) {
        /* Drive LED[3:0] through the FPGA PIO register. */
        *led_reg = value;
        usleep(200000);
        /* Read back the current KEY[1:0] sample from the FPGA PIO register. */
        printf("LED=0x%X  KEY=0x%X\n", value & 0xF, *key_reg & 0x3);
        fflush(stdout);
    }

    munmap(map, MAP_SPAN);
    return 0;
}
