hl.config({
	input = {
		kb_options = "ctrl:nocaps",
	},
})

-- MONITOR CONFIG
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

hl.config({
	general = {
		gaps_in = 1,
		gaps_out = 3,
		gaps_workspaces = 10,
		col = {
			active_border = "rgba(ffffffff)",
			inactive_border = "rgba(1c1c1a33)",
		},
	},
	misc = {
		background_color = "rgba(141312FF)",
	},
})
