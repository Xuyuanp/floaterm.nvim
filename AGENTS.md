# Agent Guidelines for floaterm.nvim

This file documents development standards, architecture, commands, and conventions for the `floaterm.nvim` repository.
Adhere to these strictly when operating within this codebase to ensure consistency and maintainability.

## Project Overview

`floaterm.nvim` is a Neovim plugin written in pure Lua that provides a floating terminal with multi-tab support.

- **Source:** `lua/floaterm/`
- **Entry Point:** `lua/floaterm/init.lua` (Lazy-loading friendly setup)
- **Core Logic:**
  - `lua/floaterm/term.lua`: **Terminal** - Orchestrates sessions and UI, handles global state.
  - `lua/floaterm/session.lua`: **Session** - Manages the underlying terminal buffer and job execution.
  - `lua/floaterm/ui.lua`: **UI** - Manages the floating window, geometry, and border rendering.

## Build, Lint & Test

### Build

This is a pure Lua plugin interpreted by Neovim's runtime—no compilation step.

- **Reloading:** Changes to `.lua` files take effect after reloading (`:luafile %`, `:source %`, or `lazy.nvim` hot-reload).
- **Runtime:** Targets Neovim 0.10+ (uses `vim.cmd.startinsert`, `vim.iter`).

### Linting & Formatting

- **Formatter:** `stylua` (config: `stylua.toml`)
  - **Indentation:** **Tabs** (`indent_type = "Tabs"`, `indent_width = 4`) - strictly enforced.
  - **Quotes:** Double quotes preferred (`quote_style = "AutoPreferDouble"`).
  - **Line width:** 120 characters.
  - **Call Parentheses:** Always required (e.g., `func()` not `func "arg"`).
  - **Command:** `stylua --check .` (verify) or `stylua .` (fix)
- **Linter:** `luacheck` (config: `.luacheckrc`)
  - **Globals:** `vim`, `jit` are pre-defined.
  - **Ignored warnings:** 631 (line length), 212 (unused `_`-prefixed args), 122 (readonly field), 411 (redefined local).
  - **Excluded:** `deps/**/*.lua`
  - **Command:** `luacheck .`

### Testing

**Framework:** `mini.test` (from `mini.nvim`)
**Location:** `tests/` directory (e.g., `tests/test_session.lua`, `tests/test_terminal.lua`)
**Dependencies:** `mini.nvim` is auto-downloaded to `deps/` by the Makefile.

#### Running Tests

Use the `Makefile`. Do NOT run `busted` or `plenary` directly.

```bash
# Run all tests
make test

# Run a single test file
make test_file FILE=tests/test_session.lua
```

#### Writing Tests

- Use `MiniTest.new_set()` to define test sets.
- Use `MiniTest.expect` for assertions (`eq` = equality, `no_equality` = inequality).
- Always cleanup buffers/terminals in tests.

```lua
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local T = new_set()

T["my_feature()"] = new_set()

T["my_feature()"]["does something"] = function()
    local Session = require("floaterm.session")
    local session = Session(1, 100, {})
    eq(session.id, 1)
    -- Cleanup
    vim.api.nvim_buf_delete(session.bufnr, { force = true })
end

return T
```

## Architecture & State Management

### Class Structure

The project uses OOP via `setmetatable`.

- **Pattern:** `---@class Namespace.ClassName` + `__index`
- **Constructor:** `Class.new(opts)` returns a table with metatable set.
- **Call Metamethod:** Modules return a callable table that delegates to `new`.

### Event-Driven Communication

`Session` fires events; `Terminal` listens—decoupled via Neovim `User` autocommands.

- **Events:**
  - `FloatermSessionClose`: Fired when session buffer is wiped.
  - `FloatermSessionError`: Fired when job exits with non-zero code.
- **Fire:** `vim.api.nvim_exec_autocmds("User", { pattern = "...", data = { ... } })`
- **Listen:** `vim.api.nvim_create_autocmd("User", { pattern = "...", callback = ... })`

## Code Style & Conventions

### File Structure

```lua
local M = {}
-- ... implementation ...
return M
```

- **Imports:** `require` statements at the top of the file.

### Naming Conventions

| Element               | Style        | Examples                                   |
| --------------------- | ------------ | ------------------------------------------ |
| Variables & Functions | `snake_case` | `gen_term_id`, `auto_hide_tabs`            |
| Classes/Types         | `PascalCase` | `Terminal`, `UI`, `Session`                |
| Private/Internal      | `_` prefix   | `_hidden`, `_subscribe_events`, `_on_exit` |

Methods starting with `_` are internal—safe to refactor. Public methods are API.

### Type Annotations (LuaCATS)

**Required** for all classes and functions.

```lua
---@class floaterm.Terminal
---@field id integer
---@field private config floaterm.Config
---@field private sessions table<floaterm.session.Id, floaterm.Session>

---@param opts? floaterm.terminal.OpenOpts
---@return floaterm.Terminal
function Terminal:open(opts)
```

### Error Handling & Safety

- **Use `pcall`** when interacting with buffers/windows that may be closed asynchronously:
  ```lua
  pcall(vim.api.nvim_win_hide, self.winnr)
  ```
- **Validate** with `is_valid()` before operating on UI elements.
- **Use `vim.defer_fn`** when operations must wait for the UI loop.

### Neovim API Usage

- Prefer `vim.api.nvim_*` over `vim.cmd` where possible.
- Use `vim.tbl_deep_extend("force", default, opts)` for merging options.
- Define highlights with `{ default = true }` to allow user overrides.

## AI Coding Assistant Rules

- **Cursor/Copilot:** No `.cursorrules` or `.github/copilot-instructions.md` exists—follow this file.
- **Docstrings:** Maintain existing LuaCATS. Update if you change function signatures.
- **Refactoring:** Do not break the public API.
- **Tool Usage:**
  - Use `make test` to verify changes.
  - Use `make test_file FILE=...` for rapid iteration.
  - Check `stylua.toml` before creating new files to match indentation.

## Development Workflow

1. **Exploration:**
   - Understand `Terminal` (controller) ↔ `Session` (model) interaction.
   - Check `lua/floaterm/term.lua` for central orchestration.
2. **Implementation:**
   - Use `vim.notify("msg", vim.log.levels.INFO)` for debugging (remove before commit).
   - Respect the `_` private prefix convention.
3. **Verification:**
   - **Lint:** `luacheck .`
   - **Format:** `stylua .`
   - **Test:** `make test`
