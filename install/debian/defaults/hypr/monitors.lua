-- Default display for this Debian ARM distribution's Parallels Retina VM.

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "Virtual-1", mode = "2560x1600@59.99", position = "auto", scale = omarchy_monitor_scale })

-- Configure a different monitor by replacing the rule above with a mode
-- advertised by: hyprctl monitors all
