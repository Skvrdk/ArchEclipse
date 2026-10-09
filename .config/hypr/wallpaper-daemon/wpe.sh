#!/bin/bash
# Wallpaper Engine wallpapers through linux-wallpaperengine.
#   wpe.sh sync              mirror each Steam workshop wallpaper as "Title [id].jpg" into ~/.config/wallpapers/wallpaper-engine
#                            (the wallpaper panel lists that folder; hyprpaper.sh hands such files to `run`)
#   wpe.sh run MONITOR FILE  start the wallpaper behind FILE (its id is in the name)
steam=/run/media/pisun/Game/Steam/steamapps # shortcut: this machine's Steam library, change it for another one
dir=$HOME/.config/wallpapers/wallpaper-engine
case ${1:-} in
sync)
    mkdir -p "$dir"
    for p in "$steam"/workshop/content/431960/*/; do
        id=$(basename "$p")
        compgen -G "$dir/*\[$id\].jpg" >/dev/null && continue
        title=$(jq -r '.title // empty' "$p/project.json" 2>/dev/null | tr -d '/\\:*?"<>|[]' | cut -c1-60)
        src=$(ls "$p"preview.* 2>/dev/null | head -1)
        [ -n "$src" ] && magick "$src[0]" "$dir/${title:-wallpaper} [$id].jpg"
    done ;;
run)
    id=$(sed -E 's/.*\[([0-9]+)\]\.[a-z]+$/\1/' <<<"$3")
    [ -d "$steam/workshop/content/431960/$id" ] || exit 1
    pgrep -af "linux-wallpaperengine.*--bg .*/$id\$" >/dev/null && exit 0 # already showing it (workspace switches call this again)
    pkill -x mpvpaper; pkill -x papertoy; pkill -x linux-wallpaper
    setsid linux-wallpaperengine --silent --fps 30 --assets-dir "$steam/common/wallpaper_engine/assets" \
        --screen-root "$2" --bg "$steam/workshop/content/431960/$id" >/dev/null 2>&1 &
    "$HOME/.config/hypr/theme/scripts/wal-theme.sh" "$3" >/dev/null 2>&1 ;;
esac
