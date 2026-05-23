#define _GNU_SOURCE
#include <stdarg.h>
#include <stdint.h>
#include <unistd.h>
#include <linux/kvm.h>

extern void *dlsym(void *, const char *);
#define RTLD_NEXT ((void *)-1L)

struct kvm_one_reg_local { uint64_t id; uint64_t addr; };

typedef int  (*ioctl_fn)(int, int, ...);
static ioctl_fn real_ioctl = 0;

static void write_str(const char *s) {
    int len = 0; while(s[len]) len++;
    write(2, s, len);
}

static int is_demux_reg(void *arg) {
    if (!arg) return 0;
    struct kvm_one_reg_local *reg = (struct kvm_one_reg_local *)arg;
    return (reg->id & KVM_REG_ARM_COPROC_MASK) == KVM_REG_ARM_DEMUX;
}

__attribute__((constructor))
static void init_hook(void) {
    write_str("[kvm_fix4] loaded\n");
    real_ioctl = (ioctl_fn)dlsym(RTLD_NEXT, "ioctl");
}

int ioctl(int fd, int request, ...) {
    va_list ap;
    va_start(ap, request);
    void *arg = va_arg(ap, void *);
    va_end(ap);

    if (!real_ioctl)
        real_ioctl = (ioctl_fn)dlsym(RTLD_NEXT, "ioctl");

    /*
     * Android kernel 6.1 rejects KVM_SET_ONE_REG for AArch32 DEMUX registers
     * with EINVAL. Intercept and silently return 0 — safe for AArch64 guests.
     */
    if ((unsigned int)request == (unsigned int)KVM_SET_ONE_REG && is_demux_reg(arg)) {
        write_str("[kvm_fix4] intercepted DEMUX reg\n");
        return 0;
    }

    return real_ioctl(fd, request, arg);
}
