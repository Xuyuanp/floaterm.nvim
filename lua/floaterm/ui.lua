---@class floaterm.UI
---@field private term_id floaterm.terminal.Id
---@field private winnr? integer
---@field private _hidden boolean
---@field private default_win_opts table<string, any>
local UI = {}
UI.__index = UI

---@param default_win_opts? table<string, any>
---@return floaterm.UI
function UI.new(default_win_opts)
	local self = setmetatable({
		_hidden = true,
		default_win_opts = default_win_opts or {},
	}, UI)

	return self
end

local function get_size(opts)
	local win_width, win_height = vim.o.columns, vim.o.lines

	local width = opts.width or 0.8
	if width < 1 then
		width = math.floor(win_width * width)
	end
	local height = opts.height or 0.8
	if height < 1 then
		height = math.floor(win_height * height)
	end

	local row = math.floor((win_height - height) / 2)
	local col = math.floor((win_width - width) / 2)

	return width, height, row, col
end

---@class floaterm.ui.WinConfig: vim.api.keyset.win_config
---@field width? number fixed width or percentage of the window
---@field height? number fixed width or percentage of the window

---@private
---@param opts floaterm.ui.WinConfig
function UI:get_config(opts)
	local width, height, row, col = get_size(opts)

	local border = opts.border or vim.o.winborder
	if
		border == ""
		or border == "none"
		or border == "shadow" -- shadow is not supported
	then
		border = "rounded"
	end

	return vim.tbl_deep_extend("force", opts or {}, {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = border,
	})
end

---@private
---@return integer?
function UI:bufnr()
	return self.winnr and vim.api.nvim_win_get_buf(self.winnr)
end

---@private
---@param session_win_opts table<string, any>
function UI:_apply_win_opts(session_win_opts)
	if not self.winnr then
		return
	end

	local merged = vim.tbl_deep_extend("force", self.default_win_opts, session_win_opts)
	for opt, value in pairs(merged) do
		pcall(function()
			vim.wo[self.winnr][opt] = value
		end)
	end
end

---@class floaterm.ui.ShowOpts
---@field config? floaterm.ui.WinConfig
---@field session_win_opts? table<string, any>

---@param bufnr integer
---@param opts? floaterm.ui.ShowOpts
---@param force? boolean
function UI:show(bufnr, opts, force)
	if self._hidden and not force then
		return
	end

	self._hidden = false

	opts = opts or {}
	local config = self:get_config(opts.config or {})
	if self:is_valid() then
		if bufnr ~= self:bufnr() then
			vim.api.nvim_win_set_buf(self.winnr, bufnr)
		end
		vim.api.nvim_win_set_config(self.winnr, config)
		self:_apply_win_opts(opts.session_win_opts or {})
		return
	end

	self.winnr = vim.api.nvim_open_win(bufnr, true, config)
	self:_apply_win_opts(opts.session_win_opts or {})

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = "" .. self.winnr,
		once = true,
		callback = function()
			self.winnr = nil
		end,
	})
end

---@return boolean
function UI:hidden()
	return self._hidden
end

---@return boolean
function UI:is_valid()
	return self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr)
end

function UI:hide()
	if self._hidden then
		return
	end
	self._hidden = true

	pcall(vim.api.nvim_win_hide, self.winnr)
	self.winnr = nil
end

---@type floaterm.UI
---@overload fun(default_win_opts?: table<string, any>): floaterm.UI
local cls = setmetatable(UI, {
	__call = function(_, ...)
		return UI.new(...)
	end,
})
return cls
