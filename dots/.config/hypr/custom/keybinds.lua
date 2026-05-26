-- Custom keybinds migrated from keybinds.conf
hl.unbind("SUPER + L")
hl.unbind("SUPER + SHIFT + L")

hl.bind("SUPER + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"), { description = "Session: Lock" })

--##! User
hl.bind(
	"CTRL + SUPER + Slash",
	hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"),
	{ description = "Edit shell config" }
)

hl.bind(
	"CTRL + SUPER + ALT + Slash",
	hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
	{ description = "Edit extra keybinds" }
)

--##! Window
-- Focusing
hl.bind("ALT + h", hl.dsp.focus({ direction = "l" }))
hl.bind("ALT + l", hl.dsp.focus({ direction = "r" }))
hl.bind("ALT + k", hl.dsp.focus({ direction = "u" }))
hl.bind("ALT + j", hl.dsp.focus({ direction = "d" }))

hl.bind("ALT + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind("ALT + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind("ALT + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind("ALT + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

hl.bind(
	"SUPER + SHIFT + h",
	hl.dsp.workspace.move({ monitor = "l" }),
	{ description = "Move workspace to monitor left" }
)

hl.bind(
	"SUPER + SHIFT + l",
	hl.dsp.workspace.move({ monitor = "r" }),
	{ description = "Move workspace to monitor right" }
)

hl.bind("SUPER + SHIFT + k", hl.dsp.workspace.move({ monitor = "u" }), { description = "Move workspace to monitor up" })

hl.bind(
	"SUPER + SHIFT + j",
	hl.dsp.workspace.move({ monitor = "d" }),
	{ description = "Move workspace to monitor down" }
)
--##! Workspace
-- Switching using raw keycodes
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("ALT + code:" .. numberkey[i], hl.dsp.focus({ workspace = i }))
end

for i = 1, 4 do
	local arrowkey = { "Left", "Right", "Up", "Down" }
	local focusdir = { "l", "r", "u", "d" }
	hl.bind("ALT + SHIFT + " .. arrowkey[i], hl.dsp.window.move({ direction = focusdir[i] }))
end

--#/# bind = SUPER+ALT, Hash,, -- Send to workspace -- (1, 2, 3,...)
--# We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("ALT + SHIFT + code:" .. numberkey[i], hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Remove Super+Shift+L logout/suspend bind from base config
-- hl.unbind("SUPER + SHIFT + L")
