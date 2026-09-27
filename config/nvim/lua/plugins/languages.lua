return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = { preset = "default" },
			completion = { documentation = { auto_show = true } },
			signature = { enabled = true },
			fuzzy = { implementation = "lua" },
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			local languages = require("config.languages")
			vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
			local servers = vim.tbl_keys(languages.servers)
			table.sort(servers)
			for name, config in pairs(languages.servers) do
				vim.lsp.config(name, config)
			end
			require("mason-lspconfig").setup({ ensure_installed = servers, automatic_enable = servers })
			require("mason-tool-installer").setup({
				ensure_installed = languages.tools,
				integrations = { ["mason-lspconfig"] = false, ["mason-null-ls"] = false, ["mason-nvim-dap"] = false },
			})
			vim.diagnostic.config({ virtual_text = false, severity_sort = true, float = { border = "rounded" } })
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("RiceLsp", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.name == "ruff" then
						client.server_capabilities.hoverProvider = false
					end
					local function map(key, action, desc)
						vim.keymap.set("n", key, action, { buffer = event.buf, desc = desc })
					end
					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("gr", vim.lsp.buf.references, "References")
					map("gI", vim.lsp.buf.implementation, "Go to implementation")
					map("gy", vim.lsp.buf.type_definition, "Go to type definition")
					map("K", vim.lsp.buf.hover, "Documentation")
					map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
				end,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = function()
			return {
				formatters_by_ft = require("config.languages").formatters,
				format_on_save = function(buf)
					if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
						return
					end
					return { timeout_ms = 2000, lsp_format = "fallback" }
				end,
			}
		end,
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = { "n", "v" },
				desc = "Format",
			},
			{
				"<leader>uf",
				function()
					vim.g.disable_autoformat = not vim.g.disable_autoformat
					vim.notify("Format on save: " .. (vim.g.disable_autoformat and "off" or "on"))
				end,
				desc = "Toggle format on save",
			},
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			ts.setup({})
			vim.treesitter.language.register("json", "jsonc")
			vim.treesitter.language.register("yaml", "yaml.docker-compose")
			local function install()
				if vim.fn.executable("tree-sitter") == 1 then
					ts.install(require("config.languages").parsers)
				end
			end
			install()
			vim.api.nvim_create_autocmd("User", {
				pattern = "MasonToolsUpdateCompleted",
				callback = install,
			})
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("RiceTreesitter", { clear = true }),
				callback = function(event)
					-- A parser may still be downloading on first launch.
					pcall(vim.treesitter.start, event.buf)
				end,
			})
		end,
	},
	{ "windwp/nvim-ts-autotag", opts = {} },
}
