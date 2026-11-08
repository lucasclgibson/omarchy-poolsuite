-- Poolsuite keybindings. Save as ~/.config/hypr/poolsuite.lua and add
--   require("hypr.poolsuite")
-- to ~/.config/hypr/hyprland.lua.

-- Play key (F8 on a Mac keyboard): pauses another app if one is playing,
-- otherwise plays/pauses Poolsuite, starting it if it's off.
o.rebind("XF86AudioPlay", "Play (starts Poolsuite when nothing else plays)", "poolsuite media-key", { locked = true })

-- Super+F8: always Poolsuite (start it, or play/pause). On Mac keyboards in
-- media-key mode F8 arrives as XF86AudioPlay, so bind both.
o.bind("SUPER + XF86AudioPlay", "Poolsuite play/pause", "poolsuite toggle", { locked = true })
o.bind("SUPER + F8", "Poolsuite play/pause", "poolsuite toggle", { locked = true })

-- Super+Alt+P: open the bar player.
o.bind("SUPER + ALT + P", "Poolsuite player", "poolsuite")
