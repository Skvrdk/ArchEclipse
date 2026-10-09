-- Same pointer speed as KDE (kcminputrc: PointerAcceleration=-0.400 for this mouse).
for _, name in ipairs({ "compx-wireless-mouse-8k-dongle-l", "compx-wireless-mouse-8k-dongle-l-mouse" }) do
    hl.device({ name = name, sensitivity = -0.4 })
end
