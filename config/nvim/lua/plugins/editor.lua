return {
	{ "folke/which-key.nvim", opts = {} },
	{ "echasnovski/mini.pairs", version = false, opts = {} },
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = { theme = "auto", icons_enabled = false, component_separators = "|", section_separators = "" },
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			on_attach = function(buf)
				local gs = require("gitsigns")
				local function map(key, fn, desc)
					vim.keymap.set("n", key, fn, { buffer = buf, desc = desc })
				end
				map("]h", function()
					gs.nav_hunk("next")
				end, "Next Git hunk")
				map("[h", function()
					gs.nav_hunk("prev")
				end, "Previous Git hunk")
				map("<leader>hp", gs.preview_hunk, "Preview hunk")
				map("<leader>hs", gs.stage_hunk, "Stage hunk")
				map("<leader>hb", gs.blame_line, "Blame line")
			end,
		},
	},
}
