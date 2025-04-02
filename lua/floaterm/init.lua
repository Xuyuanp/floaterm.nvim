local M = {}

---@class floaterm.Config
local default = {
	session = {},
	ui = {
		auto_hide_tabs = true,
		title_pos = "center", -- "center" | "left" | "right"
		icons = {
			active = "",
			inactive = "",
			urgent = "󰐾",
		},
		window = {
			width = 0.8,
			height = 0.8,
			border = nil, -- use winborder by default, if winborder is empty, 'none' or 'shadow', use 'rounded'
		},
	},
}

function M.setup(opts)
	opts = opts or {}
	M.global = vim.tbl_deep_extend("force", vim.deepcopy(default), opts)

	vim.api.nvim_set_hl(0, "FloatermIconActive", { link = "FloatTitle", default = true })
	vim.api.nvim_set_hl(0, "FloatermIconInactive", { link = "FloatBorder", default = true })
	-- maybe Error or DiagnosticError is better, but NormalFloat is good enough
	vim.api.nvim_set_hl(0, "FloatermIconUrgent", { link = "NormalFloat", default = true })
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
