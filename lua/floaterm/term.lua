local Session = require("floaterm.session")
local UI = require("floaterm.ui")

---@alias floaterm.terminal.Id integer

---@class floaterm.Terminal
---@field id floaterm.terminal.Id
---@field private config floaterm.Config
---@field private ui floaterm.UI
---@field private current_session? floaterm.Session
---@field private sessions table<floaterm.session.Id, floaterm.Session>
---@field private _next_session_id floaterm.session.Id
local Terminal = {}
Terminal.__index = Terminal

---@return floaterm.terminal.Id
local function gen_term_id()
	local term_id = vim.g.floaterm_next_id or 1
	vim.g.floaterm_next_id = term_id + 1
	return term_id
end

---@param config floaterm.Config
---@return floaterm.Terminal
function Terminal.new(config)
	local id = gen_term_id()
	local self = setmetatable({
		id = id,
		config = config,
		sessions = {},
		ui = UI(),
		_next_session_id = 1,
	}, Terminal)

	self:_subscribe_events()

	return self
end

---@private
function Terminal:_subscribe_events()
	vim.api.nvim_create_autocmd("User", {
		pattern = "FloatermSessionClose",
		callback = function(args)
			if args.data.term_id ~= self.id then
				return
			end
			local session_id = args.data.id
			self:_on_session_closed(session_id)
		end,
	})
	vim.api.nvim_create_autocmd("User", {
		pattern = "FloatermSessionError",
		callback = function(args)
			if args.data.term_id ~= self.id then
				return
			end
			local session_id = args.data.id
			local code = args.data.code
			self:_on_session_error(session_id, code)
		end,
	})
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			if self:hidden() then
				return
			end
			self:update()
		end,
	})
end

---@private
---@return floaterm.session.Id
function Terminal:_new_session_id()
	local sid = self._next_session_id
	self._next_session_id = sid + 1
	return sid
end

---@private
---@param opts? floaterm.session.Opts
function Terminal:_create_session(opts)
	local sid = self:_new_session_id()
	local session = Session(sid, self.id, vim.tbl_deep_extend("force", self.config.session, opts or {}))
	self.sessions[sid] = session
	return session
end

---@class floaterm.terminal.OpenOpts
---@field force_new? boolean
---@field session? floaterm.session.Opts

---@param opts? floaterm.terminal.OpenOpts
function Terminal:open(opts)
	opts = opts or {}

	-- cleanup invalid session
	if self.current_session and not self.current_session:is_valid() then
		self.sessions[self.current_session.id] = nil
		self.current_session = nil
	end

	if not self.current_session or opts.force_new then
		local new_session = self:_create_session(opts.session)
		self.current_session = new_session
	end

	self:update(true)
end

---refresh ui
---@param force_open? boolean open if hidden
function Terminal:update(force_open)
	local opts = vim.tbl_deep_extend("force", self.config.ui.window, {
		title = self:_format_sessions(),
		title_pos = "center",
	})
	self.ui:show(self.current_session.bufnr, opts, force_open)
end

---@private
function Terminal:_format_sessions()
	local session_ids = vim.tbl_keys(self.sessions)
	table.sort(session_ids)
	local icons = vim.iter(session_ids)
		:map(function(sid)
			local icon = self.current_session.id == sid and self.config.ui.icons.active or self.config.ui.icons.inactive
			local sess = self.sessions[sid]
			if sess.exit_code ~= nil and sess.exit_code ~= 0 then
				icon = self.config.ui.icons.urgent
			end
			return icon
		end)
		:totable()
	if #icons < 2 and self.config.ui.auto_hide_tabs then
		return ""
	end
	local s = table.concat(icons, " ")

	return string.format(" %s ", s)
end

function Terminal:hidden()
	return self.ui:hidden() or not self.ui:is_valid()
end

function Terminal:hide()
	self.ui:hide()
end

function Terminal:toggle()
	if self:hidden() then
		self:open()
	else
		self:hide()
	end
end

---@private
---@return floaterm.session.Id?
function Terminal:_current_session_id()
	return self.current_session and self.current_session.id
end

---@private
---@param session_id floaterm.session.Id
function Terminal:_set_current(session_id)
	self.current_session = self.sessions[session_id]
	self:update()
end

---@private
---@param session_id floaterm.session.Id
---@param cycle? boolean
---@param comp? fun(a: number, b: number): boolean
---@return number?
function Terminal:_neighbor_session(session_id, cycle, comp)
	comp = comp or function(a, b)
		return a < b
	end
	local session_ids = vim.tbl_keys(self.sessions)
	if #session_ids < 1 then
		return
	end
	table.sort(session_ids, comp)

	for _, sid in ipairs(session_ids) do
		if sid ~= session_id and not comp(sid, session_id) then
			return sid
		end
	end

	if not cycle then
		return
	end

	local first = session_ids[1]
	if first == session_id then
		return
	end
	return first
end

---@private
---@param session_id floaterm.session.Id
---@param cycle? boolean
---@return floaterm.session.Id?
function Terminal:_next_session(session_id, cycle)
	return self:_neighbor_session(session_id, cycle)
end

---@private
---@param session_id floaterm.session.Id
---@param cycle? boolean
---@return floaterm.session.Id?
function Terminal:_prev_session(session_id, cycle)
	return self:_neighbor_session(session_id, cycle, function(a, b)
		return a > b
	end)
end

---@private
---@param session_id floaterm.session.Id
---@param exit_code integer
function Terminal:_on_session_error(session_id, exit_code)
	exit_code = exit_code -- lint

	if not self.sessions[session_id] then
		return
	end

	self:update()
end

---@private
---@param session_id floaterm.session.Id
function Terminal:_fallback(session_id)
	return self:_next_session(session_id, false) or self:_prev_session(session_id, false)
end

---@private
---@param session_id floaterm.session.Id
function Terminal:_on_session_closed(session_id)
	self.sessions[session_id] = nil

	-- other session closed, just remove it and update ui if needed
	if not self.current_session or session_id ~= self.current_session.id then
		self:update()
		return
	end

	-- current session closed, fallback to next or prev session
	local fallback = self:_fallback(session_id)
	-- no session left
	if not fallback then
		self.current_session = nil
		self:hide()
		return
	end

	self:_set_current(fallback)

	-- idk why, but the delay is needed, otherwise the fallback session won't start insert
	vim.defer_fn(function()
		if not self.current_session or not self.current_session:is_valid() then
			return
		end
		self.current_session:prompt()
	end, 10)
end

---@param cycle? boolean
function Terminal:next_session(cycle)
	local current_session_id = self:_current_session_id()
	if not current_session_id then
		return
	end
	local sid = self:_next_session(current_session_id, cycle)
	if not sid then
		return
	end

	self:_set_current(sid)
end

---@param cycle? boolean
function Terminal:prev_session(cycle)
	local current_session_id = self:_current_session_id()
	if not current_session_id then
		return
	end
	local sid = self:_prev_session(current_session_id, cycle)
	if not sid then
		return
	end

	self:_set_current(sid)
end

---@type floaterm.Terminal
---@overload fun(config: floaterm.Config): floaterm.Terminal
local cls = setmetatable(Terminal, {
	__call = function(_, ...)
		return Terminal.new(...)
	end,
})
return cls
