// LD_PRELOAD shim: papertoy never sets an exclusive zone (default 0), so the bar's reserved area pushes it down. Right after set_anchor
// we also send set_exclusive_zone(-1) = "cover the whole output".
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>
#include <wayland-client.h>

void wl_proxy_marshal_array(struct wl_proxy *p, uint32_t opcode, union wl_argument *args) {
    static void (*real)(struct wl_proxy *, uint32_t, union wl_argument *);
    if (!real) real = dlsym(RTLD_NEXT, "wl_proxy_marshal_array");
    real(p, opcode, args);
    if (opcode == 1 && !strcmp(wl_proxy_get_class(p), "zwlr_layer_surface_v1")) {
        union wl_argument zone = { .i = -1 };
        real(p, 2, &zone);
    }
}
