---@class FloatermUI
---@field private term_id FloatermId
---@field private winnr? number
---@field private _hidden boolean
local M = {}

---@param term_id FloatermId
---@return FloatermUI
function M.new(term_id)
	local ui = setmetatable({
		term_id = term_id,
		_hidden = true,
	}, { __index = M })

	return ui
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

---@class FloatermWinConfig: vim.api.keyset.win_config
---@field width number fixed width or percentage of the window
---@field height number fixed width or percentage of the window

---@private
---@param opts FloatermWinConfig
function M:get_config(opts)
	local width, height, row, col = get_size(opts)

	return vim.tbl_deep_extend("force", {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = "rounded",
	}, opts or {})
end

---@private
---@return number?
function M:bufnr()
	return self.winnr and vim.api.nvim_win_get_buf(self.winnr)
end

---@param bufnr number
---@param opts? FloatermWinConfig
---@param force? boolean
function M:show(bufnr, opts, force)
	if self._hidden and not force then
		return
	end

	self._hidden = false

	local config = self:get_config(opts or {})
	if self:is_valid() then
		if bufnr ~= self:bufnr() then
			vim.api.nvim_win_set_buf(self.winnr, bufnr)
		end
		vim.api.nvim_win_set_config(self.winnr, config)
		return
	end

	self.winnr = vim.api.nvim_open_win(bufnr, true, config)

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = "" .. self.winnr,
		once = true,
		callback = function()
			self.win = nil
		end,
	})
end

---@return boolean
function M:hidden()
	return self._hidden
end

function M:is_valid()
	return self.winnr and vim.api.nvim_win_is_valid(self.winnr)
end

function M:hide()
	if self._hidden then
		return
	end
	self._hidden = true

	pcall(vim.api.nvim_win_hide, self.winnr)
	self.winnr = nil
end

return M
