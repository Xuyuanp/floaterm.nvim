# Agent Guidelines for floaterm.nvim

This file documents the development standards, architecture, commands, and conventions for the `floaterm.nvim` repository.
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
This is a pure Lua plugin interpreted by Neovim's runtime, so there is no compilation step.
- **Reloading:** Changes to `.lua` files are effective immediately upon reloading the module (e.g., `:luafile %`, `:source %`, or using `lazy.nvim` hot-reload).
- **Runtime:** Target Neovim 0.10+ (implied by usage of `vim.cmd.startinsert` and `vim.iter`).

### Linting & Formatting
- **Configuration:** `stylua.toml` governs formatting.
- **Formatter:** `stylua` is the standard.
    - **Indentation:** **Tabs** (indent_width = 4) - strictly enforced.
    - **Quotes:** Double quotes `"` preferred (`AutoPreferDouble`).
    - **Call Parentheses:** Always (e.g., `func()` not `func "arg"`).
- **Linter:** `luacheck` is standard for Neovim Lua.
    - **Status:** No `.luacheckrc` exists currently.
    - **Command:** `luacheck . --globals vim jit`
    - **Note:** Always include `--globals vim` to avoid false positives on the Neovim API.

### Testing
**Framework:** The project uses `mini.test` (from `mini.nvim`) for testing.
**Location:** Tests are located in the `tests/` directory (e.g., `tests/test_session.lua`).
**Dependencies:** `mini.nvim` is downloaded automatically to `deps/` by the Makefile.

#### Running Tests
Use the provided `Makefile` for running tests. Do not try to run `busted` or `plenary` directly.

1.  **Run All Tests:**
    ```bash
    make test
    ```

2.  **Run a Single Test File:**
    Pass the file path to the `FILE` variable.
    ```bash
    make test_file FILE=tests/test_session.lua
    ```

3.  **Writing Tests:**
    -   Follow the patterns in existing test files (`tests/test_*.lua`).
    -   Use `MiniTest.new_set()` to define test sets.
    -   Use `MiniTest.expect` for assertions.
    -   Example:
        ```lua
        local new_set = MiniTest.new_set
        local expect, child = MiniTest.expect, MiniTest.new_child_neovim()
        local T = new_set({
            hooks = {
                pre_case = function() child.restart({ '-u', 'scripts/minimal_init.lua' }) end,
                post_case = function() child.stop() end,
            },
        })
        
        T['works'] = function()
            child.lua([[require('floaterm').new({ ... })]])
            expect.equality(child.lua([[return _G.some_state]]), true)
        end
        
        return T
        ```

## Architecture & State Management

### Class Structure
The project uses a consistent Object-Oriented style via `setmetatable`.
- **Classes:** Define with `---@class <Namespace>.<ClassName>` and `__index`.
- **Constructor:** `Class.new(opts)` returns a table with the metatable set.
- **Call Metamethod:** The module often returns a callable table that delegates to `new` (see `term.lua`).

### Event-Driven Communication
The `Terminal` and `Session` classes allow decoupled communication via Neovim `User` autocommands.
- **Pattern:** `Session` fires events; `Terminal` listens.
- **Events:**
    - `FloatermSessionClose`: Fired when a session buffer is wiped.
    - `FloatermSessionError`: Fired when a job exits with non-zero code.
- **Implementation:**
    - *Fire:* `vim.api.nvim_exec_autocmds("User", { pattern = "...", data = { ... } })`
    - *Listen:* `vim.api.nvim_create_autocmd("User", { pattern = "...", callback = ... })`

## Code Style & Conventions

### File Structure
- **Module Pattern:**
    ```lua
    local M = {}
    -- ... implementation ...
    return M
    ```
- **Imports:** `require` statements should be at the top of the file.

### Naming Conventions
- **Variables & Functions:** `snake_case` (e.g., `gen_term_id`, `auto_hide_tabs`).
- **Classes/Types:** `PascalCase` (e.g., `Terminal`, `UI`, `Session`).
- **Private/Internal:** Prefix with `_` (e.g., `_hidden`, `_subscribe_events`, `_on_exit`).
    - *Note:* Methods starting with `_` are considered internal and safe to refactor. Public methods are API.

### Type Annotations (LuaCATS)
Extensive use of LuaCATS is required for IntelliSense and documentation.
- **Classes:** Define fields explicitly.
    ```lua
    ---@class floaterm.Terminal
    ---@field id integer
    ---@field private config floaterm.Config
    ---@field private sessions table<floaterm.session.Id, floaterm.Session>
    ```
- **Functions:** Document parameters and return types.
    ```lua
    ---@param opts? floaterm.terminal.OpenOpts
    ---@return floaterm.Terminal
    ```

### Error Handling & Safety
- **Unsafe Calls:** Use `pcall` when interacting with Windows/Buffers that might be closed asynchronously.
    ```lua
    pcall(vim.api.nvim_win_hide, self.winnr)
    ```
- **Validation:** Always check `is_valid()` (wrapping `nvim_buf_is_valid` or `nvim_win_is_valid`) before operating on UI elements.
- **Deferring:** Use `vim.defer_fn` when operations must wait for the UI loop (e.g., entering insert mode after a session switch).

### Neovim API Usage
- **API:** Prefer `vim.api.nvim_*` functions over `vim.cmd` where possible.
- **Configuration:** Use `vim.tbl_deep_extend("force", default, opts)` for merging options.
- **Highlights:** Define default highlights using `vim.api.nvim_set_hl` with `{ default = true }` to allow user overrides.

## AI Coding Assistant Rules
- **Cursor/Copilot:** No specific `.cursorrules` or `.github/copilot-instructions.md` were found. Follow this file.
- **Docstrings:** Maintain existing LuaCATS. Update them if you change function signatures.
- **Refactoring:** When refactoring, ensure you do not break the public API.
- **Tool Usage:**
  - Use `make test` to verify changes.
  - Use `make test_file FILE=...` for rapid iteration on specific features.
  - Always read `stylua.toml` before creating new files to match indentation.

## Development Workflow
1.  **Exploration:**
    - Understand the interaction between `Terminal` (controller) and `Session` (model) before changes.
    - Check `lua/floaterm/term.lua` for the central orchestration.
2.  **Implementation:**
    - Use `vim.notify("msg", vim.log.levels.INFO)` for debugging if needed, but remove before committing.
    - Respect the `_` private prefix convention.
3.  **Verification:**
    - **Lint:** `luacheck . --globals vim jit`
    - **Format:** `stylua .`
    - **Test:** Run `make test` to ensure no regressions.
