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

	ui:_subscribe_events()

	return ui
end

---@private
function M:_subscribe_events()
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			if not self:is_valid() then
				return
			end
			self:update()
		end,
	})
end

local function get_size()
	local win_width, win_height = vim.o.columns, vim.o.lines

	local width = math.floor(win_width * 0.8)
	local height = math.floor(win_height * 0.8)
	local row = math.floor((win_height - height) / 2)
	local col = math.floor((win_width - width) / 2)

	return width, height, row, col
end

---@private
---@param opts? vim.api.keyset.win_config
function M:get_config(opts)
	local width, height, row, col = get_size()

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
---@param opts? vim.api.keyset.win_config
---@param force? boolean
function M:show(bufnr, opts, force)
	if self._hidden and not force then
		return
	end

	if not self._hidden and self:is_valid() then
		if bufnr ~= self:bufnr() then
			vim.api.nvim_win_set_buf(self.winnr, bufnr)
		end
		self:update(opts)
		self._hidden = false
		return
	end

	local config = self:get_config(opts)
	self.winnr = vim.api.nvim_open_win(bufnr, true, config)

	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = "" .. self.winnr,
		once = true,
		callback = function()
			self.win = nil
		end,
	})

	self._hidden = false
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

---@param opts? vim.api.keyset.win_config
function M:update(opts)
	local config = self:get_config(opts)
	vim.api.nvim_win_set_config(self.winnr, config)
end

return M
