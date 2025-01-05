local M = {}

function M.setup(opts)
	opts = opts or {}

	_G.Floaterm = _G.Floaterm or require("floaterm.term").new() --[[@as Floaterm]]
end

function M.toggle()
	Floaterm:toggle()
end

function M.open(opts)
	Floaterm:open(opts)
end

function M.next_session(cycle)
	Floaterm:next_session(cycle)
end

function M.prev_session(cycle)
	Floaterm:prev_session(cycle)
end

return M
