local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set()

-- =============================================================================
-- Session:get_win_opts()
-- =============================================================================

T["Session:get_win_opts()"] = new_set()

T["Session:get_win_opts()"]["returns empty table by default"] = function()
	local Session = require("floaterm.session")
	local session = Session(1, 100, {})

	local opts = session:get_win_opts()
	eq(type(opts), "table")
	eq(vim.tbl_count(opts), 0)

	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

T["Session:get_win_opts()"]["returns stored win_opts"] = function()
	local Session = require("floaterm.session")
	local session = Session(1, 100, {
		win_opts = { winblend = 10, winhighlight = "Normal:MyHi" },
	})

	local opts = session:get_win_opts()
	eq(opts.winblend, 10)
	eq(opts.winhighlight, "Normal:MyHi")

	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

-- =============================================================================
-- UI:show() with win_opts
-- =============================================================================

T["UI:show() win_opts"] = new_set()

T["UI:show() win_opts"]["applies default win_opts"] = function()
	local UI = require("floaterm.ui")
	-- Create UI with default winblend = 20
	local ui = UI({ winblend = 20 })
	local bufnr = vim.api.nvim_create_buf(false, true)

	ui:show(bufnr, {}, true)

	-- Check if window option was applied
	eq(vim.wo[ui.winnr].winblend, 20)

	ui:hide()
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["UI:show() win_opts"]["applies session override"] = function()
	local UI = require("floaterm.ui")
	-- Default winblend = 20
	local ui = UI({ winblend = 20 })
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- Session overrides with winblend = 50
	ui:show(bufnr, {
		session_win_opts = { winblend = 50 },
	}, true)

	eq(vim.wo[ui.winnr].winblend, 50)

	ui:hide()
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["UI:show() win_opts"]["resets to default when no override"] = function()
	local UI = require("floaterm.ui")
	local ui = UI({ winblend = 10 })
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- 1. Apply override
	ui:show(bufnr, {
		session_win_opts = { winblend = 50 },
	}, true)
	eq(vim.wo[ui.winnr].winblend, 50)

	-- 2. Show again without override (simulate switching to session without opts)
	-- Pass empty table to simulate no session opts
	ui:show(bufnr, {
		session_win_opts = {},
	}, true)
	eq(vim.wo[ui.winnr].winblend, 10) -- Should revert to default

	ui:hide()
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

return T
