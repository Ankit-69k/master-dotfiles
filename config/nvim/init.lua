-- Resolve symlinks so this also works with `nvim -u /path/to/init.lua`.
local source = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fs.dirname(vim.uv.fs_realpath(source) or source)
vim.opt.rtp:prepend(config_dir)
vim.g.rice_dir = vim.env.RICE_DIR or vim.fs.dirname(vim.fs.dirname(config_dir))

-- Neo-tree handles directories instead of Neovim's built-in explorer.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.theme").setup()
require("config.lazy")
require("config.theme").reload(true)
