local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T = new_set()

-- =============================================================================
-- UI.new()
-- =============================================================================

T["UI.new()"] = new_set()

T["UI.new()"]["creates instance with _hidden = true"] = function()
	local UI = require("floaterm.ui")
	local ui = UI.new()

	eq(type(ui), "table")
	eq(ui:hidden(), true)
end

T["UI.new()"]["creates instance via call syntax"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	eq(type(ui), "table")
	eq(ui:hidden(), true)
end

-- =============================================================================
-- UI:hidden() and UI:is_valid()
-- =============================================================================

T["state methods"] = new_set()

T["state methods"]["hidden() returns true initially"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	eq(ui:hidden(), true)
end

T["state methods"]["is_valid() returns false when no window exists"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	eq(ui:is_valid(), false)
end

-- =============================================================================
-- UI:show() and UI:hide()
-- =============================================================================

T["show/hide"] = new_set()

T["show/hide"]["show() does not open window when hidden and force=false"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local bufnr = vim.api.nvim_create_buf(false, true)
	ui:show(bufnr, {}, false)

	eq(ui:hidden(), true)
	eq(ui:is_valid(), false)

	vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["show/hide"]["show() opens window when force=true"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local bufnr = vim.api.nvim_create_buf(false, true)
	ui:show(bufnr, {}, true)

	eq(ui:hidden(), false)
	eq(ui:is_valid(), true)

	ui:hide()
	vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["show/hide"]["hide() sets hidden state and closes window"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local bufnr = vim.api.nvim_create_buf(false, true)
	ui:show(bufnr, {}, true)

	eq(ui:hidden(), false)

	ui:hide()

	eq(ui:hidden(), true)
	eq(ui:is_valid(), false)

	vim.api.nvim_buf_delete(bufnr, { force = true })
end

T["show/hide"]["hide() is idempotent"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	-- hide() when already hidden should not error
	ui:hide()
	ui:hide()

	eq(ui:hidden(), true)
end

-- =============================================================================
-- UI:get_config()
-- =============================================================================

T["get_config()"] = new_set()

T["get_config()"]["calculates percentage dimensions correctly"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local config = ui:get_config({ width = 0.5, height = 0.5 })

	-- Width should be half of vim.o.columns
	local expected_width = math.floor(vim.o.columns * 0.5)
	local expected_height = math.floor(vim.o.lines * 0.5)

	eq(config.width, expected_width)
	eq(config.height, expected_height)
	eq(config.relative, "editor")
	eq(config.style, "minimal")
end

T["get_config()"]["uses fixed dimensions when >= 1"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local config = ui:get_config({ width = 80, height = 24 })

	eq(config.width, 80)
	eq(config.height, 24)
end

T["get_config()"]["falls back to rounded border when empty"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local old_winborder = vim.o.winborder
	vim.o.winborder = ""

	local config = ui:get_config({})

	eq(config.border, "rounded")

	vim.o.winborder = old_winborder
end

T["get_config()"]["falls back to rounded border when none"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local config = ui:get_config({ border = "none" })

	eq(config.border, "rounded")
end

T["get_config()"]["preserves custom border"] = function()
	local UI = require("floaterm.ui")
	local ui = UI()

	local config = ui:get_config({ border = "single" })

	eq(config.border, "single")
end

return T
