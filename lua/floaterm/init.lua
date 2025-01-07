local M = {}

---@class floaterm.Config
local default = {
	session = {},
	ui = {
		auto_hide_tabs = true,
		icons = {
			active = "",
			inactive = "",
			urgent = "󰐾",
		},
		window = {
			width = 0.8,
			height = 0.8,
			border = "rounded",
		},
	},
}

function M.setup(opts)
	opts = opts or {}
	M.global = vim.tbl_deep_extend("force", vim.deepcopy(default), opts)
end

setmetatable(M, {
	__index = function(_, key)
		if key == "new" then
			return function(opts)
				return require("floaterm.term").new(opts)
			end
		end

		if not _G.Floaterm then
			_G.Floaterm = require("floaterm.term").new(M.global or default)
		end
		return function(...)
			return Floaterm[key](Floaterm, ...)
		end
	end,
})

return M
