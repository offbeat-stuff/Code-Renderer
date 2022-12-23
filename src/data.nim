const foreground* = "#edeff0"
const background* = "#0c0e0f"

# ansi 16 colors
const baseColors* = @["#1c252c", "#df5b61", "#78b892", "#de8f78", "#6791c9","#bc83e3", "#67afc1", "#d9d7d6"]
const brightColors* = @["#484e5b", "#f16269", "#8cd7aa", "#e9967e", "#79aaeb","#c488ec", "#7acfe4", "#e5e5e5"]

# path to font
const fontFile* = "/usr/share/fonts/TTF/Fira Code Regular Nerd Font Complete Mono.ttf"

const fontSize* = 20
# how much text is added after every frame, measured in chars, not unicode
const textSkip* = 2
# padding in pixels
const padding* = 10
const frameRate* = 30

const batCmd* = "bat --language=nim --theme base16 -f -pp -"