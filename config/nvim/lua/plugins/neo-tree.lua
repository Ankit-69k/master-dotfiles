return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			filesystem = {
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_hidden = false,
				},
				hijack_netrw_behavior = "open_default",
				follow_current_file = {
					enabled = true,
					leave_dirs_open = true,
				},
			},
		})

		vim.api.nvim_create_autocmd("VimEnter", {
			group = vim.api.nvim_create_augroup("RiceExplorer", { clear = true }),
			once = true,
			callback = function()
				-- Let the dashboard finish opening before adding the sidebar.
				vim.schedule(function()
					local directory_start = vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
					require("neo-tree.command").execute({
						action = "show",
						source = "filesystem",
						position = "left",
						-- Directory buffers are handled by Neo-tree's directory hook.
						reveal = vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) == 1,
					})
					if directory_start then
						-- Alpha skips directory arguments, so open it in the editor pane explicitly.
						local editor_win
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "neo-tree"
								and vim.api.nvim_win_get_config(win).relative == "" then
								editor_win = win
								break
							end
						end
						if editor_win then
							vim.api.nvim_set_current_win(editor_win)
						else
							vim.cmd("botright vnew")
						end
						require("alpha").start(false)
					end
				end)
			end,
		})
		vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>", { desc = "Show file tree" })
		vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", { desc = "Show buffer tree" })
	end,
}
