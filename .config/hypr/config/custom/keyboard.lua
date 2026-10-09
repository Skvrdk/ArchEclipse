hl.config({
    input = {
        kb_layout = "us,ru",
        kb_variant = ",",
        -- Match binds by the first (us) layout, so they also work while the ru layout is active.
        resolve_binds_by_sym = 0,
    },
})
