-- Hyprland 0.55+ uses Lua. Home Manager appends the web-app rules.
local scale = 1.5
local laptopMonitor = "eDP-1"
local terminal = "ghostty"
local fileManager = "thunar"
local menu = "wofi --show drun"
local mainMod = "SUPER"

hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-1", mode = "2880x1920@120", position = "0x0", scale = scale })
hl.monitor({ output = laptopMonitor, mode = "preferred", position = "auto", scale = 1 })

hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm-app -u vicinae-server.scope -- vicinae server")
    hl.exec_cmd("uwsm-app -u waybar.scope -- systemd-cat -t waybar waybar")
    hl.exec_cmd("uwsm-app -u mako.scope -- mako")
end)

-- Treat the internal panel as disconnected when the lid is closed,
-- including when starting or reloading Hyprland while docked.
hl.on("config.reloaded", function()
    hl.exec_cmd([[for f in /proc/acpi/button/lid/*/state; do
        [ -f "$f" ] || continue
        if grep -qi closed "$f"; then
            hyprctl eval 'hl.monitor({ output = "]] .. laptopMonitor .. [[", disabled = true })'
        fi
    done]])
end)
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = laptopMonitor, disabled = true })
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = laptopMonitor, mode = "preferred", position = "auto", scale = 1 })
end, { locked = true })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GDK_SCALE", tostring(scale))

hl.config({
    -- Render XWayland apps at native density; ~/.Xresources sets Xft.dpi.
    xwayland = { force_zero_scaling = true },
    general = {
        gaps_in = 5,
        gaps_out = { top = 10, right = 20, bottom = 20, left = 20 },
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(60a5faee)", "rgba(3b82f6ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = false,
            size = 7,
            passes = 2,
            vibrancy = 0.12,
        },
    },
    animations = { enabled = false },
    dwindle = {
        preserve_split = true,
        force_split = 2, -- Split to the right or bottom.
    },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        focus_on_activate = false,
    },
    debug = { disable_logs = false },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
hl.animation({ leaf = "specialWorkspace", enabled = false })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-- Window management and workspace navigation.
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

for key, direction in pairs({ H = "left", L = "right", K = "up", J = "down" }) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = true }))
end
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + bracketleft", hl.dsp.group.prev())
hl.bind(mainMod .. " + bracketright", hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + bracketleft", hl.dsp.group.move_window({ forward = false }))
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.group.move_window({ forward = true }))

-- Application and system bindings.
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("uwsm-app -- " .. terminal))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("uwsm-app -- google-chrome-stable"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("uwsm-app -- " .. fileManager))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("uwsm-app -- obsidian"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("restart-app waybar"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("spotify"))
hl.bind("Print", hl.dsp.exec_cmd("grimblast --freeze save area - | satty --filename - --output-filename ~/Screenshots/satty-$(date +%Y%m%d-%H%M%S).png --early-exit --copy-command wl-copy"))

for key, command in pairs({
    XF86AudioRaiseVolume = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
    XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    XF86AudioMicMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
    XF86MonBrightnessUp = "brightnessctl -e4 -n2 set 5%+",
    XF86MonBrightnessDown = "brightnessctl -e4 -n2 set 5%-",
}) do
    hl.bind(key, hl.dsp.exec_cmd(command), { locked = true, repeating = true })
end
for key, command in pairs({
    XF86AudioNext = "playerctl next",
    XF86AudioPause = "playerctl play-pause",
    XF86AudioPlay = "playerctl play-pause",
    XF86AudioPrev = "playerctl previous",
}) do
    hl.bind(key, hl.dsp.exec_cmd(command), { locked = true })
end

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.layer_rule({ name = "vicinae-blur", match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0, dim_around = true })
hl.layer_rule({ name = "vicinae-no-animation", match = { namespace = "vicinae" }, no_anim = true })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "notifications" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.2 })

-- Floating TUI windows launched from Waybar.
for _, app in ipairs({ "wiremix", "bluetui", "impala" }) do
    hl.window_rule({
        name = "windowrule-tui-" .. app,
        match = { title = "tui:" .. app },
        float = true,
        center = true,
        size = { "monitor_w*0.65", "monitor_h*0.50" },
    })
end
hl.window_rule({
    name = "bitwarden-popup",
    match = { initial_title = "_crx_nngceckbapebfimnlniiiahkandclblb" },
    float = true,
})

-- The old workspace defaultgroup option is now a window rule.
for _, workspace in ipairs({ "8", "9" }) do
    hl.window_rule({ name = "default-group-" .. workspace, match = { workspace = workspace }, group = "set" })
end
hl.window_rule({
    name = "spotify",
    match = { class = "spotify" },
    workspace = "special:spotify silent",
    float = true,
    size = { "monitor_w*0.7", "monitor_h*0.7" },
    center = true,
    no_anim = true,
})
hl.window_rule({ name = "discord", match = { class = "discord" }, workspace = "9", group = "set" })
hl.window_rule({ name = "slack", match = { class = "Slack" }, workspace = "9", group = "set" })
hl.window_rule({ name = "todoist", match = { class = "Todoist" }, workspace = "8", group = "set" })
hl.window_rule({ name = "datagrip", match = { class = "jetbrains-datagrip" }, workspace = "6" })
