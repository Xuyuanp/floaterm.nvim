---@alias floaterm.session.Id integer

---@class floaterm.Session
---@field id floaterm.session.Id
---@field term_id floaterm.terminal.Id
---@field bufnr integer
---@field exit_code? integer
---@field opts floaterm.session.Opts
local M = {}

---@class floaterm.session.Opts
---@field cmd? string|string[]

---@param id floaterm.session.Id
---@param term_id floaterm.terminal.Id
---@param opts? floaterm.session.Opts
---@return floaterm.Session
function M.new(id, term_id, opts)
	local bufnr = vim.api.nvim_create_buf(false, true)

	local sess = setmetatable({
		id = id,
		term_id = term_id,
		bufnr = bufnr,
		opts = opts or {},
	}, { __index = M })

	sess:_subscribe_events()

	return sess
end

---@private
---@param fn fun()
function M:call(fn)
	vim.api.nvim_buf_call(self.bufnr, fn)
end

function M:prompt()
	self:call(function()
		self:_prompt()
	end)
end

---@private
function M:_prompt()
	vim.cmd.startinsert()
end

---@private
function M:_init()
	if vim.bo.buftype == "terminal" then
		return
	end
	local job_id = vim.fn.jobstart(self.opts.cmd or { vim.o.shell }, {
		term = true,
		env = {
			TERM = vim.env.TERM,
		},
		on_exit = function(_, code)
			self:_on_exit(code)
		end,
	})
	vim.b.floaterm = true
	vim.b.floaterm_id = self.term_id
	vim.b.floaterm_session_id = self.id
	vim.b.floaterm_job_id = job_id
	vim.bo.filetype = "floaterm"
end

---@private
function M:_subscribe_events()
	-- timeline:
	-- when the job exit successfully, the terminal buffer will be wiped out firstly, then on_exit will be called
	-- otherwise, on_exit is called firstly and prompt user to the close buffer
	vim.api.nvim_create_autocmd({ "BufWipeout" }, {
		buffer = self.bufnr,
		nested = true,
		callback = function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "FloatermSessionClose",
				data = {
					id = self.id,
					term_id = self.term_id,
					bufnr = self.bufnr,
					code = self.exit_code,
				},
			})
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
		buffer = self.bufnr,
		once = true,
		callback = function()
			self:_init()
		end,
	})
	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		buffer = self.bufnr,
		callback = function()
			self:_prompt()
		end,
	})
end

---@private
---@param code integer
function M:_on_exit(code)
	if not self:is_valid() then
		return
	end

	self.exit_code = code

	vim.api.nvim_exec_autocmds("User", {
		pattern = "FloatermSessionError",
		data = {
			id = self.id,
			term_id = self.term_id,
			bufnr = self.bufnr,
			exit_code = self.exit_code,
		},
	})
end

---@return boolean
function M:is_valid()
	return self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr)
end

return M
