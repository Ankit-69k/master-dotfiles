local M = {}
local previous

local function read(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local text = file:read("*a")
	file:close()
	return text
end

function M.reload(force)
	local root = vim.g.rice_dir
	local name = vim.trim(read(root .. "/generated/ACTIVE_THEME") or "")
	if not name:match("^[%w_-]+$") then
		return false
	end
	local text = read(root .. "/themes/" .. name .. "/colors.conf")
	if not text then
		return false
	end
	local signature = name .. "\n" .. text
	if not force and signature == previous and vim.g.colors_name == "rice" then
		return true
	end
	local c = {}
	for line in text:gmatch("[^\r\n]+") do
		local key, value = line:match("^%s*([%w_]+)%s*=%s*#?(%x+)%s*$")
		if key and #value == 6 then
			c[key] = "#" .. value
		end
	end
	-- Ignore incomplete writes while the theme is being changed.
	for _, key in ipairs({
		"background",
		"foreground",
		"accent",
		"red",
		"green",
		"yellow",
		"blue",
		"magenta",
		"cyan",
		"orange",
	}) do
		if not c[key] then
			return false
		end
	end
	c.background_alt = c.background_alt or c.background
	c.background_dark = c.background_dark or c.background
	c.foreground_alt = c.foreground_alt or c.foreground
	c.comment = c.comment or c.foreground_alt
	c.selection = c.selection or c.background_alt
	vim.o.background = "dark"
	vim.cmd("highlight clear")
	vim.g.colors_name = "rice"
	vim.g.rice_theme = name
	local groups = {
		Normal = { fg = c.foreground, bg = c.background },
		NormalFloat = { fg = c.foreground, bg = c.background_dark },
		FloatBorder = { fg = c.accent, bg = c.background_dark },
		FloatTitle = { fg = c.accent, bold = true },
		Comment = { fg = c.comment, italic = true },
		Constant = { fg = c.orange },
		String = { fg = c.green },
		Number = { fg = c.orange },
		Boolean = { fg = c.orange },
		Identifier = { fg = c.foreground },
		Function = { fg = c.blue },
		Statement = { fg = c.magenta },
		Keyword = { fg = c.magenta },
		Operator = { fg = c.cyan },
		PreProc = { fg = c.cyan },
		Type = { fg = c.yellow },
		Special = { fg = c.orange },
		Delimiter = { fg = c.foreground_alt },
		Error = { fg = c.red },
		Todo = { fg = c.background, bg = c.yellow, bold = true },
		LineNr = { fg = c.comment },
		CursorLineNr = { fg = c.accent, bold = true },
		CursorLine = { bg = c.background_alt },
		SignColumn = { bg = c.background },
		Visual = { bg = c.selection },
		Search = { fg = c.background, bg = c.yellow },
		IncSearch = { fg = c.background, bg = c.orange },
		CurSearch = { fg = c.background, bg = c.accent },
		MatchParen = { fg = c.accent, bg = c.selection, bold = true },
		Pmenu = { fg = c.foreground, bg = c.background_alt },
		PmenuSel = { fg = c.background, bg = c.accent },
		PmenuSbar = { bg = c.background_alt },
		PmenuThumb = { bg = c.selection },
		StatusLine = { fg = c.foreground, bg = c.background_alt },
		StatusLineNC = { fg = c.comment, bg = c.background_dark },
		TabLine = { fg = c.foreground_alt, bg = c.background_alt },
		TabLineSel = { fg = c.background, bg = c.accent },
		TabLineFill = { bg = c.background_dark },
		WinSeparator = { fg = c.selection },
		Directory = { fg = c.blue },
		Title = { fg = c.accent, bold = true },
		NonText = { fg = c.comment },
		Folded = { fg = c.comment, bg = c.background_alt },
		DiffAdd = { fg = c.green, bg = c.background_alt },
		DiffChange = { fg = c.blue, bg = c.background_alt },
		DiffDelete = { fg = c.red, bg = c.background_alt },
		DiffText = { fg = c.yellow, bg = c.selection },
	}
	for group, color in pairs({ Error = c.red, Warn = c.yellow, Info = c.blue, Hint = c.cyan, Ok = c.green }) do
		groups["Diagnostic" .. group] = { fg = color }
		groups["DiagnosticUnderline" .. group] = { sp = color, undercurl = true }
	end
	for group, color in pairs({ Add = c.green, Change = c.blue, Delete = c.red }) do
		groups["GitSigns" .. group] = { fg = color }
	end
	for group, target in pairs({
		["@variable"] = "Identifier",
		["@variable.builtin"] = "Special",
		["@variable.parameter"] = "Identifier",
		["@property"] = "Identifier",
		["@function"] = "Function",
		["@function.builtin"] = "Special",
		["@constructor"] = "Type",
		["@type"] = "Type",
		["@keyword"] = "Keyword",
		["@string"] = "String",
		["@number"] = "Number",
		["@boolean"] = "Boolean",
		["@comment"] = "Comment",
		["@operator"] = "Operator",
		["@punctuation"] = "Delimiter",
		["@tag"] = "Keyword",
		["@tag.attribute"] = "Function",
		["@tag.delimiter"] = "Delimiter",
		TelescopeBorder = "FloatBorder",
		TelescopeNormal = "NormalFloat",
		TelescopeSelection = "Visual",
		TelescopeMatching = "Special",
		BlinkCmpMenu = "Pmenu",
		BlinkCmpMenuBorder = "FloatBorder",
		BlinkCmpDoc = "NormalFloat",
		BlinkCmpDocBorder = "FloatBorder",
		OilDir = "Directory",
		WhichKey = "Function",
		WhichKeyGroup = "Keyword",
	}) do
		groups[group] = { link = target }
	end
	for group, opts in pairs(groups) do
		vim.api.nvim_set_hl(0, group, opts)
	end
	for i = 0, 15 do
		vim.g["terminal_color_" .. i] = c["color" .. i] or c.foreground
	end
	previous = signature
	vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "rice", modeline = false })
	return true
end

function M.setup()
	M.reload(true)
	vim.api.nvim_create_user_command("RiceThemeReload", function()
		M.reload(true)
	end, { desc = "Reload the selected rice theme" })
	local group = vim.api.nvim_create_augroup("RiceTheme", { clear = true })
	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		callback = function()
			M.reload()
		end,
	})
	-- Poll the tiny selector/palette files; this also works when a selector writes
	-- in place or replaces a file, and updates Neovim without requiring focus.
	local timer = assert(vim.uv.new_timer())
	timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			if not vim.v.exiting or vim.v.exiting == vim.NIL then
				M.reload()
			end
		end)
	)
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		once = true,
		callback = function()
			timer:stop()
			timer:close()
		end,
	})
end

return M
