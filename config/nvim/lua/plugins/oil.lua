return {
  "stevearc/oil.nvim",
  config = function()
    local oil = require("oil")
    oil.setup({
      default_file_explorer = false,
      view_options = {
          show_hidden = true,
        },
    })
    vim.keymap.set("n", "-", oil.toggle_float, { desc = "Toggle Oil file explorer" })
  end,
}
