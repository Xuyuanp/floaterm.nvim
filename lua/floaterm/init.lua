local M = {}

function M.setup(opts)
	opts = opts or {}

	if not _G.Floaterm then
		_G.Floaterm = require("floaterm.term").new() --[[@as Floaterm]]
	end
end

setmetatable(M, {
	__index = function(_, key)
		return function(...)
			return Floaterm[key](Floaterm, ...)
		end
	end,
})

return M
