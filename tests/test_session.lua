local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T = new_set()

-- =============================================================================
-- Session.new()
-- =============================================================================

T["Session.new()"] = new_set()

T["Session.new()"]["creates session with correct fields"] = function()
	local Session = require("floaterm.session")
	local session = Session.new(1, 100, {})

	eq(session.id, 1)
	eq(session.term_id, 100)
	eq(type(session.bufnr), "number")
	eq(vim.api.nvim_buf_is_valid(session.bufnr), true)

	-- Cleanup
	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

T["Session.new()"]["creates session via call syntax"] = function()
	local Session = require("floaterm.session")
	local session = Session(2, 101, {})

	eq(session.id, 2)
	eq(session.term_id, 101)

	-- Cleanup
	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

T["Session.new()"]["stores name from options"] = function()
	local Session = require("floaterm.session")
	local session = Session(3, 102, { name = "test-session" })

	eq(session.name, "test-session")

	-- Cleanup
	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

T["Session.new()"]["stores options"] = function()
	local Session = require("floaterm.session")
	local opts = { cmd = { "echo", "hello" }, name = "echo-test" }
	local session = Session(4, 103, opts)

	eq(session.opts.cmd[1], "echo")
	eq(session.opts.cmd[2], "hello")
	eq(session.opts.name, "echo-test")

	-- Cleanup
	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

-- =============================================================================
-- Session:is_valid()
-- =============================================================================

T["is_valid()"] = new_set()

T["is_valid()"]["returns true for valid buffer"] = function()
	local Session = require("floaterm.session")
	local session = Session(5, 104, {})

	eq(session:is_valid(), true)

	-- Cleanup
	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

T["is_valid()"]["returns false after buffer is deleted"] = function()
	local Session = require("floaterm.session")
	local session = Session(6, 105, {})

	vim.api.nvim_buf_delete(session.bufnr, { force = true })

	eq(session:is_valid(), false)
end

-- =============================================================================
-- Session:call()
-- =============================================================================

T["call()"] = new_set()

T["call()"]["executes function in buffer context"] = function()
	local Session = require("floaterm.session")
	local session = Session(7, 106, {})

	local captured_bufnr = nil
	session:call(function()
		captured_bufnr = vim.api.nvim_get_current_buf()
	end)

	eq(captured_bufnr, session.bufnr)

	-- Cleanup
	vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

return T
