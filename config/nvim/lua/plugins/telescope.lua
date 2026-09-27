return {
	"nvim-telescope/telescope.nvim",

	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	config = function()
		require("telescope").setup({
			defaults = { file_ignore_patterns = { "node_modules/", "%.git/", "target/", "%.venv/" } },
		})
		local telescope = require("telescope.builtin")

		vim.keymap.set("n", "<leader>ff", telescope.find_files, {
			desc = "Find files",
		})

		vim.keymap.set("n", "<leader>fg", telescope.live_grep, {
			desc = "Find text",
		})

		vim.keymap.set("n", "<leader>fb", telescope.buffers, {
			desc = "Find buffers",
		})
	end,
}
