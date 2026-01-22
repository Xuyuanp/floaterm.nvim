local eq, neq = MiniTest.expect.equality, MiniTest.expect.no_equality

local T = MiniTest.new_set()

local _, new_set = _G.test_helper()

-- Helper to create a minimal config
local function make_config()
	return {
		session = {},
		ui = {
			auto_hide_tabs = true,
			title_pos = "center",
			icons = {
				active = "",
				inactive = "",
				urgent = "󰐾",
			},
			window = {
				width = 0.8,
				height = 0.8,
				border = nil,
			},
		},
	}
end

-- =============================================================================
-- Terminal.new()
-- =============================================================================

T["Terminal.new()"] = new_set()

T["Terminal.new()"]["creates terminal with unique id"] = function()
	-- Reset the global counter for predictable tests
	vim.g.floaterm_next_id = 1

	local Terminal = require("floaterm.term")
	local term1 = Terminal.new(make_config())
	local term2 = Terminal.new(make_config())

	eq(type(term1.id), "number")
	eq(type(term2.id), "number")
	neq(term1.id, term2.id)
end

T["Terminal.new()"]["creates terminal via call syntax"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	eq(type(term.id), "number")
end

T["Terminal.new()"]["initializes with empty sessions"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	local session_ids = term:list_sessions_ids()
	eq(#session_ids, 0)
end

-- =============================================================================
-- Terminal:list_sessions_ids()
-- =============================================================================

T["list_sessions_ids()"] = new_set()

T["list_sessions_ids()"]["returns empty table initially"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	local ids = term:list_sessions_ids()
	eq(type(ids), "table")
	eq(#ids, 0)
end

-- =============================================================================
-- Terminal:current_session_id()
-- =============================================================================

T["current_session_id()"] = new_set()

T["current_session_id()"]["returns nil when no session exists"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	eq(term:current_session_id(), nil)
end

-- =============================================================================
-- Terminal:hidden()
-- =============================================================================

T["hidden()"] = new_set()

T["hidden()"]["returns true initially"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	eq(term:hidden(), true)
end

-- =============================================================================
-- Terminal:toggle()
-- =============================================================================

T["toggle()"] = new_set()

T["toggle()"]["opens terminal when hidden"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	eq(term:hidden(), true)

	term:toggle()

	eq(term:hidden(), false)
end

T["toggle()"]["hides terminal when visible"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:toggle()
	eq(term:hidden(), false)

	term:toggle()
	eq(term:hidden(), true)
end

-- =============================================================================
-- Terminal:_format_sessions()
-- =============================================================================

T["_format_sessions()"] = new_set()

T["_format_sessions()"]["returns empty string with single session and auto_hide_tabs"] = function()
	local Terminal = require("floaterm.term")
	local config = make_config()
	config.ui.auto_hide_tabs = true
	local term = Terminal(config)

	-- Open to create a session
	term:open()

	local formatted = term:_format_sessions()
	eq(formatted, "")
end

T["_format_sessions()"]["returns icons with auto_hide_tabs disabled"] = function()
	local Terminal = require("floaterm.term")
	local config = make_config()
	config.ui.auto_hide_tabs = false
	local term = Terminal(config)

	-- Open to create a session
	term:open()

	local formatted = term:_format_sessions()
	eq(type(formatted), "table")
	eq(#formatted > 0, true)
end

-- =============================================================================
-- Terminal:open()
-- =============================================================================

T["open()"] = new_set()

T["open()"]["creates new session"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	eq(#term:list_sessions_ids(), 0)

	term:open()

	eq(#term:list_sessions_ids(), 1)
	neq(term:current_session_id(), nil)
end

T["open()"]["reuses existing session by default"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local first_id = term:current_session_id()

	term:hide()
	term:open()
	local second_id = term:current_session_id()

	eq(first_id, second_id)
	eq(#term:list_sessions_ids(), 1)
end

T["open()"]["creates new session when force_new is true"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local first_id = term:current_session_id()

	term:open({ force_new = true })
	local second_id = term:current_session_id()

	neq(first_id, second_id)
	eq(#term:list_sessions_ids(), 2)
end

T["open()"]["reuses named session if exists"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open({ session = { name = "test-session" } })
	local first_id = term:current_session_id()

	term:open({ force_new = true })
	local second_id = term:current_session_id()

	term:open({ session = { name = "test-session" } })
	local third_id = term:current_session_id()

	-- third_id should be same as first_id (named session)
	eq(first_id, third_id)
	neq(first_id, second_id)
	eq(#term:list_sessions_ids(), 2)
end

-- =============================================================================
-- Terminal:_neighbor_session()
-- =============================================================================

T["_neighbor_session()"] = new_set()

T["_neighbor_session()"]["finds next session"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local id1 = term:current_session_id()
	term:open({ force_new = true })
	local id2 = term:current_session_id()
	term:open({ force_new = true })
	local id3 = term:current_session_id()

	-- From id1, next should be id2
	local next_from_1 = term:_next_session(id1, false)
	eq(next_from_1, id2)

	-- From id2, next should be id3
	local next_from_2 = term:_next_session(id2, false)
	eq(next_from_2, id3)

	-- From id3, next should be nil (no cycle)
	local next_from_3 = term:_next_session(id3, false)
	eq(next_from_3, nil)
end

T["_neighbor_session()"]["finds prev session"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local id1 = term:current_session_id()
	term:open({ force_new = true })
	local id2 = term:current_session_id()
	term:open({ force_new = true })
	local id3 = term:current_session_id()

	-- From id3, prev should be id2
	local prev_from_3 = term:_prev_session(id3, false)
	eq(prev_from_3, id2)

	-- From id2, prev should be id1
	local prev_from_2 = term:_prev_session(id2, false)
	eq(prev_from_2, id1)

	-- From id1, prev should be nil (no cycle)
	local prev_from_1 = term:_prev_session(id1, false)
	eq(prev_from_1, nil)
end

T["_neighbor_session()"]["cycles when cycle=true"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local id1 = term:current_session_id()
	term:open({ force_new = true })
	local id2 = term:current_session_id()

	-- From id2, next with cycle should be id1
	local next_from_2 = term:_next_session(id2, true)
	eq(next_from_2, id1)

	-- From id1, prev with cycle should be id2
	local prev_from_1 = term:_prev_session(id1, true)
	eq(prev_from_1, id2)
end

-- =============================================================================
-- Terminal:send()
-- =============================================================================

T["send()"] = new_set()

T["send()"]["notifies when no current session"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	local notified = false
	local original_notify = vim.notify
	---@diagnostic disable-next-line: duplicate-set-field
	vim.notify = function(msg, level)
		if msg == "No current session" and level == vim.log.levels.WARN then
			notified = true
		end
	end

	term:send("test")

	vim.notify = original_notify
	eq(notified, true)
end

T["send()"]["notifies when session id not found"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	local notified = false
	local original_notify = vim.notify
	---@diagnostic disable-next-line: duplicate-set-field
	vim.notify = function(msg, level)
		if msg == "Session not found: id=999" and level == vim.log.levels.WARN then
			notified = true
		end
	end

	term:send("test", { id = 999 })

	vim.notify = original_notify
	eq(notified, true)
end

T["send()"]["notifies when session name not found"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	local notified = false
	local original_notify = vim.notify
	---@diagnostic disable-next-line: duplicate-set-field
	vim.notify = function(msg, level)
		if msg == "Session not found: name=nonexistent" and level == vim.log.levels.WARN then
			notified = true
		end
	end

	term:send("test", { name = "nonexistent" })

	vim.notify = original_notify
	eq(notified, true)
end

T["send()"]["finds session by id"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local id1 = term:current_session_id()
	term:open({ force_new = true })
	local id2 = term:current_session_id()
	neq(id1, id2)

	-- Current is id2, send to id1 should switch
	term:send("test", { id = id1, focus = true })
	eq(term:current_session_id(), id1)
end

T["send()"]["finds session by name"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open({ session = { name = "named-session" } })
	local id1 = term:current_session_id()
	term:open({ force_new = true })
	local id2 = term:current_session_id()
	neq(id1, id2)

	-- Current is id2, send to named-session should switch to id1
	term:send("test", { name = "named-session", focus = true })
	eq(term:current_session_id(), id1)
end

T["send()"]["id takes priority over name"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open({ session = { name = "session-a" } })
	local id1 = term:current_session_id()
	term:open({ force_new = true, session = { name = "session-b" } })
	local id2 = term:current_session_id()
	neq(id1, id2)

	-- Send with both id and name - id should win
	term:send("test", { id = id1, name = "session-b", focus = true })
	eq(term:current_session_id(), id1)
end

T["send()"]["auto-opens when hidden"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	term:hide()
	eq(term:hidden(), true)

	term:send("test", { focus = true })
	eq(term:hidden(), false)
end

T["send()"]["sends to current session when no opts"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local current_id = term:current_session_id()

	-- Should not change current session
	term:send("test")
	eq(term:current_session_id(), current_id)
end

T["send()"]["does not switch session without focus"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	local id1 = term:current_session_id()
	term:open({ force_new = true })
	local id2 = term:current_session_id()
	neq(id1, id2)

	-- Send to id1 without focus - should NOT switch current session
	term:send("test", { id = id1 })
	eq(term:current_session_id(), id2)

	-- Send to id1 with focus=false - should NOT switch current session
	term:send("test", { id = id1, focus = false })
	eq(term:current_session_id(), id2)
end

T["send()"]["stays hidden without focus"] = function()
	local Terminal = require("floaterm.term")
	local term = Terminal(make_config())

	term:open()
	term:hide()
	eq(term:hidden(), true)

	-- Send without focus - should stay hidden
	term:send("test")
	eq(term:hidden(), true)

	-- Send with focus=false - should stay hidden
	term:send("test", { focus = false })
	eq(term:hidden(), true)
end

return T
