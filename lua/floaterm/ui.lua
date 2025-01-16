---@class floaterm.UI
---@field private term_id floaterm.terminal.Id
---@field private winnr? integer
---@field private _hidden boolean
local UI = {}
UI.__index = UI

---@return floaterm.UI
function UI.new()
	local self = setmetatable({
		_hidden = true,
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

	return vim.tbl_deep_extend("force", opts or {}, {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
	})
end

---@private
---@return integer?
function UI:bufnr()
	return self.winnr and vim.api.nvim_win_get_buf(self.winnr)
end

---@param bufnr integer
---@param opts? floaterm.ui.WinConfig
---@param force? boolean
function UI:show(bufnr, opts, force)
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
			self.winnr = nil
		end,
	})
end

---@return boolean
function UI:hidden()
	return self._hidden
end

function UI:is_valid()
	return self.winnr and vim.api.nvim_win_is_valid(self.winnr)
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
---@overload fun(): floaterm.UI
local cls = setmetatable(UI, {
	__call = function(_)
		return UI.new()
	end,
})
return cls
