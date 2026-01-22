local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local _, new_set = _G.test_helper()

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
end

T["Session.new()"]["creates session via call syntax"] = function()
	local Session = require("floaterm.session")
	local session = Session(2, 101, {})

	eq(session.id, 2)
	eq(session.term_id, 101)
end

T["Session.new()"]["stores name from options"] = function()
	local Session = require("floaterm.session")
	local session = Session(3, 102, { name = "test-session" })

	eq(session.name, "test-session")
end

T["Session.new()"]["stores options"] = function()
	local Session = require("floaterm.session")
	local opts = { cmd = { "echo", "hello" }, name = "echo-test" }
	local session = Session(4, 103, opts)

	eq(session.opts.cmd[1], "echo")
	eq(session.opts.cmd[2], "hello")
	eq(session.opts.name, "echo-test")
end

-- =============================================================================
-- Session:is_valid()
-- =============================================================================

T["is_valid()"] = new_set()

T["is_valid()"]["returns true for valid buffer"] = function()
	local Session = require("floaterm.session")
	local session = Session(5, 104, {})

	eq(session:is_valid(), true)
end

T["is_valid()"]["returns false after buffer is deleted"] = function()
	local Session = require("floaterm.session")
	local session = Session(6, 105, {})

	vim.api.nvim_buf_delete(session.bufnr, { force = true })

	eq(session:is_valid(), false)
end

-- =============================================================================
-- Session:send()
-- =============================================================================

T["send()"] = new_set()

T["send()"]["does nothing when job not initialized"] = function()
	local Session = require("floaterm.session")
	local session = Session(1, 100, {})

	-- Should not error even without job
	session:send("test")
end

-- =============================================================================
-- Session:get_win_opts()
-- =============================================================================

T["get_win_opts()"] = new_set()

T["get_win_opts()"]["returns empty table by default"] = function()
	local Session = require("floaterm.session")
	local session = Session(1, 100, {})

	local opts = session:get_win_opts()
	eq(type(opts), "table")
	eq(vim.tbl_count(opts), 0)
end

T["get_win_opts()"]["returns stored win_opts"] = function()
	local Session = require("floaterm.session")
	local session = Session(1, 100, {
		win_opts = { winblend = 10, winhighlight = "Normal:MyHi" },
	})

	local opts = session:get_win_opts()
	eq(opts.winblend, 10)
	eq(opts.winhighlight, "Normal:MyHi")
end

return T
