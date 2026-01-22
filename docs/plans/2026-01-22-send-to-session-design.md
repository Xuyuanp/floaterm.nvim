# Send to Session Feature Design

## Overview

Add ability to send raw text to a terminal session by session ID or name. If no target specified, sends to current session. Auto-opens UI if hidden.

## API

### Session:send(text)

Low-level method on Session class — sends raw text to job channel.

```lua
---@param text string
function Session:send(text)
```

- Uses `vim.api.nvim_chan_send` to send to job channel
- Reads `job_id` from buffer variable `vim.b[bufnr].floaterm_job_id`
- No validation, no newline appended — raw passthrough

### Terminal:send(text, opts)

High-level method on Terminal class — resolves target and delegates.

```lua
---@class floaterm.terminal.SendOpts
---@field id? floaterm.session.Id      -- target by ID (priority)
---@field name? string                  -- target by name (fallback)

---@param text string
---@param opts? floaterm.terminal.SendOpts
function Terminal:send(text, opts)
```

**Resolution order:**
1. `opts.id` provided → find by ID
2. `opts.name` provided → find by name
3. Neither → use `current_session`
4. Not found → `vim.notify` warning, return early

**Auto-open behavior:**
- UI hidden → open UI, switch to target session, send
- UI visible but different session active → switch to target, send
- UI visible and target is current → just send

### Public API

Exposed via `require('floaterm').send(text, opts)` through existing metatable pattern in `init.lua`.

## Usage Examples

```lua
-- Send to current session
require('floaterm').send("ls -la\n")

-- Send to session by ID
require('floaterm').send("echo hello\n", { id = 2 })

-- Send to session by name
require('floaterm').send("npm test\n", { name = "dev" })
```

## Implementation Plan

1. Add `Session:send(text)` method to `lua/floaterm/session.lua`
2. Add `Terminal:send(text, opts)` method to `lua/floaterm/term.lua`
3. Update README with new API documentation
4. Add tests for send functionality

## Error Handling

- Session not found by ID → `vim.notify("Session not found: id=X", WARN)`
- Session not found by name → `vim.notify("Session not found: name=X", WARN)`
- No current session → `vim.notify("No current session", WARN)`
- Session invalid → `vim.notify("Session is invalid", WARN)`
