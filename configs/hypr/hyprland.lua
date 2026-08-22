----------------
--  MONITORS  --
----------------
-- hl.monitor({
--     output = "DP-1",
--     mode = "3440x1440@180",
--     position = "0x0",
--     scale = 1
-- })
hl.monitor({
    output = "DP-2",
    mode = "1920x1080@75",
    position = "-1920x0",
    scale = 1
})

hl.monitor({
    output = "DP-1",
    mode = "5120x1440@120",
    position = "0x0",
    scale = 1,
})
-- hl.monitor({
--     output = "DP-1",
--     mode = "3440x1440@180",
--     position = "840x-1440",
--     scale = 1
-- })

-------------------
--  MY PROGRAMS  --
-------------------

local terminal = "kitty"
local fileManager = "nemo"
local menu = "rofi -show drun"
local mainMod = "SUPER"

-----------------
--  AUTOSTART  --
-----------------

local function restart_waybar()
    hl.exec_cmd("pkill waybar; waybar")
    hl.exec_cmd("~/.config/hypr/new_wallpaper_changer.sh")
end

hl.on("hyprland.start", function()
    restart_waybar()
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("mako -c ~/.config/mako/config")
    hl.exec_cmd("pidof hypridle || hypridle")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("wl-paste -t text --watch clipman store --no-persist")
    hl.exec_cmd("xrandr --output DP-1 --primary")
    hl.exec_cmd("blueman-applet")
end)

-- Preserve old `exec =` behavior: restart Waybar after config reloads too.
hl.on("config.reloaded", function()
    restart_waybar()
end)

hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target")
end)

-----------------------------
--  ENVIRONMENT VARIABLES  --
-----------------------------

hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
-- hl.env("QT_QPA_PLATFORMTHEME", "qt5ct") -- change to qt6ct if you have that
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-------------------
--  LOOK & FEEL  --
-------------------

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 6,
        border_size = 2,
        col = {
            active_border = "rgba(2880d7fd)",
            inactive_border = "rgba(171d2599)"
        },
        layout = "dwindle",
        resize_on_border = true,
        allow_tearing = false
    },
    decoration = {
        rounding = 8,
        blur = {
            enabled = true,
            size = 3,
            passes = 2,
            vibrancy = 0.1696
        },
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)"
        }
    },
    animations = {
        enabled = true
    },
    dwindle = {
        preserve_split = true
    },
    master = {
        new_status = "master",
        orientation = "center",
        slave_count_for_center_master = 2,
        mfact = 0.5,
        center_master_fallback = "left",
        smart_resizing = true
    },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.5,
        direction = "right",
        focus_fit_method = 1
    },
    misc = {
        force_default_wallpaper = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        initial_workspace_tracking = false
    }
})

----------------
-- LAYER RULES
----------------

hl.layer_rule({
    match = {
        namespace = "logout_dialog"
    },
    blur = true
})
hl.layer_rule({
    match = {
        namespace = "waybar"
    },
    blur = true
})
hl.layer_rule({
    match = {
        namespace = "rofi"
    },
    blur = true
})

----------------
--  ANIMATIONS --
----------------

hl.curve("wind", {
    type = "bezier",
    points = {{0.05, 0.9}, {0.1, 1.05}}
})

hl.curve("winIn", {
    type = "bezier",
    points = {{0.1, 1.1}, {0.1, 1.1}}
})

hl.curve("winOut", {
    type = "bezier",
    points = {{0.3, -0.3}, {0, 1}}
})

hl.curve("liner", {
    type = "bezier",
    points = {{1, 1}, {1, 1}}
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 6,
    bezier = "wind",
    style = "slide"
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 6,
    bezier = "winIn",
    style = "slide"
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5,
    bezier = "winOut",
    style = "slide"
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 5,
    bezier = "wind",
    style = "slide"
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 1,
    bezier = "liner"
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 30,
    bezier = "liner",
    style = "loop"
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 10,
    bezier = "default"
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "wind"
})

-------------
--  INPUT  --
-------------

hl.config({
    input = {
        kb_layout = "us,bg(phonetic)",
        kb_variant = "",
        kb_model = "",
        kb_options = "grp:win_space_toggle",
        kb_rules = "",
        follow_mouse = 1,
        accel_profile = "flat",
        sensitivity = 0.2,

        touchpad = {
            natural_scroll = true
        }
    }
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5
})

------------------
--  KEYBINDINGS --
------------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("pkill waybar; hyprctl reload"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({
    action = "toggle"
}))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({
    mode = "fullscreen",
    action = "toggle"
}))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle

-- Lock and turn DPMS off after 1 second.
hl.bind(mainMod .. " + L", function()
    hl.exec_cmd("hyprlock")
    hl.timer(function()
        hl.dispatch(hl.dsp.dpms({
            action = "disable"
        }))
    end, {
        timeout = 1000,
        type = "oneshot"
    })
end)

-- Move focus with mainMod + arrow keys.
hl.bind(mainMod .. " + left", hl.dsp.focus({
    direction = "l"
}))
hl.bind(mainMod .. " + right", hl.dsp.focus({
    direction = "r"
}))
hl.bind(mainMod .. " + up", hl.dsp.focus({
    direction = "u"
}))
hl.bind(mainMod .. " + down", hl.dsp.focus({
    direction = "d"
}))

-- Resize windows.
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({
    x = 10,
    y = 0,
    relative = true
}), {
    repeating = true
})
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({
    x = -10,
    y = 0,
    relative = true
}), {
    repeating = true
})
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({
    x = 0,
    y = -10,
    relative = true
}), {
    repeating = true
})
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({
    x = 0,
    y = 10,
    relative = true
}), {
    repeating = true
})

-- Switch workspaces with mainMod + [0-9], and move windows with SHIFT.
for i = 1, 10 do
    local key = tostring(i % 10) -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({
        workspace = i
    }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({
        workspace = i
    }))
end

-- Swap windows
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.swap({
    direction = "l"
}))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.swap({
    direction = "r"
}))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.swap({
    direction = "u"
}))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.swap({
    direction = "d"
}))

-- Example special workspace (scratchpad).
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({
    workspace = "special:magic"
}))

-- Scroll through existing workspaces with mainMod + scroll.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({
    workspace = "e+1"
}))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({
    workspace = "e-1"
}))

-- Move/resize windows with mainMod + LMB/RMB and dragging.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true
})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {
    mouse = true
})

-- Audio controls.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), {
    repeating = true
})

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), {
    repeating = true
})

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), {
    locked = true
})
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), {
    locked = true
})
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), {
    locked = true
})

-- Screenshot / clipboard / color picker controls.
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd([[grim -g "$(slurp)" -t jpeg -q 100]]))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(
    [[sh -c 'grim -g "$(slurp)" -t png - | tesseract stdin stdout -l eng+bul | wl-copy --type text/plain && notify-send "OCR" "Text copied to clipboard"']]))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("clipman pick -t wofi"))
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("wl-copy -c"))

------------------------------
--  WINDOWS AND WORKSPACES  --
------------------------------

hl.window_rule({
    match = {
        class = ".*"
    },
    suppress_event = "maximize"
})
hl.window_rule({
    match = {
        title = "^Calculator$"
    },
    float = true
})
hl.window_rule({
    match = {
        title = "^Picture-in-Picture$"
    },
    float = true
})
hl.window_rule({
    match = {
        title = "^Picture in picture$"
    },
    float = true
})
hl.window_rule({
    match = {
        title = "^Timeshift-gtk$"
    },
    float = true
})
hl.window_rule({
    match = {
        class = "^brave-nngceckbapebfimnlniiiahkandclblb-Default$"
    },
    float = true
})
hl.window_rule({
    match = {
        title = "^YouTube Music$"
    },
    tile = true
})
hl.window_rule({
    match = {
        class = "^rofi.*$"
    },
    opacity = "0.7 0.7"
})
hl.window_rule({
    match = {
        class = "^spotify.*$"
    },
    opacity = "0.8 0.8"
})
hl.window_rule({
    match = {
        class = "^org.gnome.Nautilus.*$"
    },
    opacity = "0.7 0.7"
})
hl.window_rule({
    match = {
        class = "^nemo*$"
    },
    opacity = "0.8 0.8"
})
hl.workspace_rule({
    workspace = "10",
    monitor = "DP-2",
    default = true
})
