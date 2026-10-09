#!/bin/bash
# Wallpaper Engine wallpapers through linux-wallpaperengine.
#   wpe.sh sync              mirror each Steam workshop wallpaper as "Title [id].jpg" into ~/.config/wallpapers/wallpaper-engine/<type>
#                            (scene|video: the wallpaper panel makes one category per folder; hyprpaper.sh hands such files to `run`)
#   wpe.sh run MONITOR FILE  start the wallpaper behind FILE (its id is in the name)
steam=/run/media/pisun/Game/Steam/steamapps # shortcut: this machine's Steam library, change it for another one
dir=$HOME/.config/wallpapers/wallpaper-engine
case ${1:-} in
sync)
    mkdir -p "$dir"
    for p in "$steam"/workshop/content/431960/*/; do
        id=$(basename "$p")
        compgen -G "$dir/*/*\[$id\].jpg" >/dev/null && continue
        title=$(jq -r '.title // empty' "$p/project.json" 2>/dev/null | tr -d '/\\:*?"<>|[]&' | cut -c1-60)
        src=$(ls "$p"preview.* 2>/dev/null | head -1)
        type=$(jq -r '.type // "other" | ascii_downcase' "$p/project.json" 2>/dev/null)
        case $type in scene|video) ;; *) continue ;; esac # web crashes linux-wallpaperengine, presets (no type) have nothing to show
        mkdir -p "$dir/$type"
        [ -n "$src" ] && magick "$src[0]" "$dir/$type/${title:-wallpaper} [$id].jpg"
    done ;;
run)
    id=$(sed -E 's/.*\[([0-9]+)\]\.[a-z]+$/\1/' <<<"$3")
    [ -d "$steam/workshop/content/431960/$id" ] || exit 1
    pgrep -af "linux-wallpaperengine.*--bg .*/$id\$" >/dev/null && { pkill -x papertoy; pkill -x mpvpaper; exit 0; } # already showing it (workspace switches call this again)
    old=$(pgrep -x linux-wallpaper)
    setsid linux-wallpaperengine --silent --no-audio-processing --fps 30 --assets-dir "$steam/common/wallpaper_engine/assets" \
        --screen-root "$2" --bg "$steam/workshop/content/431960/$id" >/dev/null 2>&1 &
    # Keep whatever is showing until the new wallpaper has its layer and first frame, so a switch never flashes the static one.
    sleep 0.3; new=$(pgrep -nx linux-wallpaper)
    for _ in $(seq 80); do hyprctl layers | grep -q "linux-wallpaperengine, pid: $new" && break; sleep 0.25; done
    sleep 1 # the new layer is black for ~0.3 s before its first frame; keep the old one until then
    kill $old 2>/dev/null; pkill -x mpvpaper; pkill -x papertoy
    "$HOME/.config/hypr/theme/scripts/wal-theme.sh" "$3" >/dev/null 2>&1 ;;
esac
