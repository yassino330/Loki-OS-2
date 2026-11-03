/*
 * LokiOS PID 1 bootstrap.
 *
 * This is deliberately a small, auditable starting point, not yet a complete
 * init system. It establishes the early userspace mount contract and launches
 * the LokiOS system supervisor once that component exists.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/reboot.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static int ensure_dir(const char *path) {
    if (mkdir(path, 0755) == 0 || errno == EEXIST) return 0;
    perror(path);
    return -1;
}
static int mount_virtual(const char *src, const char *dst, const char *type,
                         unsigned long flags) {
    if (ensure_dir(dst) < 0) return -1;
    if (mount(src, dst, type, flags, NULL) == 0 || errno == EBUSY) return 0;
    fprintf(stderr, "LokiOS init: mount %s on %s: %s\n", type, dst, strerror(errno));
    return -1;
}
int main(void) {
    if (getpid() != 1) {
        fprintf(stderr, "LokiOS init must run as PID 1\n");
        return 1;
    }
    mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL);
    if (mount_virtual("proc", "/proc", "proc", MS_NOSUID | MS_NOEXEC | MS_NODEV) ||
        mount_virtual("sysfs", "/sys", "sysfs", MS_NOSUID | MS_NOEXEC | MS_NODEV) ||
        mount_virtual("devtmpfs", "/dev", "devtmpfs", MS_NOSUID) ||
        mount_virtual("tmpfs", "/run", "tmpfs", MS_NOSUID | MS_NODEV)) {
        fprintf(stderr, "LokiOS init: early mount setup failed; entering recovery shell\n");
        execl("/bin/sh", "sh", NULL);
        reboot(RB_POWER_OFF);
        return 1;
    }
    execl("/sbin/lokios-supervisor", "lokios-supervisor", NULL);
    fprintf(stderr, "LokiOS init: supervisor unavailable: %s\n", strerror(errno));
    execl("/bin/sh", "sh", NULL);
    reboot(RB_POWER_OFF);
    return 1;
}
