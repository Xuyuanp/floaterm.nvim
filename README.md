# Floaterm.nvim

Floaterm.nvim is a Neovim plugin that provides a floating terminal with multi-tab support. It is designed to enhance your workflow by allowing you to manage terminal sessions efficiently within Neovim.

![image](https://github.com/user-attachments/assets/2264e2e8-ea56-4a5b-a5ed-02a0a741f50c)


## Features

- **Floating Terminal**: Open a terminal in a floating window for seamless integration with your Neovim workflow.
- **Multi-Tab Support**: Manage multiple terminal sessions using tabs, with customizable UI options.

## Installation

Use your favorite plugin manager to install Floaterm.nvim. For example, with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "Xuyuanp/floaterm.nvim",
  -- default options
  opts = {
    session = {
      -- string or string[]
      -- a session will be started with env NVIM_FLOATERM=1
      cmd = vim.o.SHELL
    },
    ui = {
      auto_hide_tabs = true, -- Automatically hide tabs when only one terminal is open
      title_pos = "center",  -- Position of the tab title: "center" | "left" | "right"
      icons = {
        active = "",       -- Icon for active tab
        inactive = "",     -- Icon for inactive tab
        urgent = "󰐾",       -- Icon for urgent tab
      },
      window = {
        width = 0.8,         -- Width of the floating terminal (as a fraction of the editor width)
        height = 0.8,        -- Height of the floating terminal (as a fraction of the editor height)
        border = nil,        -- use winborder by default, if winborder is empty, 'none' or 'shadow', use 'rounded'
      },
    },
  }
}
```

## Usage

### `require('floaterm').new(config: floaterm.Config): floaterm.Terminal`

Creates a new terminal instance. You may not need to call this directly, as the plugin creates a global one automatically.

- **Parameters**:
  - `config`: Configuration for the terminal.
- **Returns**: A new `floaterm.Terminal` instance.

### `require('floaterm').open(opts?: floaterm.terminal.OpenOpts)`

Opens the terminal.

- **Parameters**:
  - `opts` (optional): Options for opening the terminal.
    - `force_new` (optional): If `true`, forces the creation of a new session.
    - `session` (optional): Session options.

### `require('floater').update(force_open?: boolean)`

Refreshes the terminal UI.

- **Parameters**:
  - `force_open` (optional): If `true`, opens the terminal if it is hidden.

### `require('floaterm').hidden(): boolean`

Checks if the terminal is hidden.

- **Returns**: `true` if the terminal is hidden, otherwise `false`.

### `require('floaterm').hide()`

Hides the terminal.

### `require('floaterm').toggle()`

Toggles the visibility of the terminal.

### `require('floaterm').next_session(cycle?: boolean)`

Switches to the next(right) session.

- **Parameters**:
  - `cycle` (optional): If `true`, cycles back to the first session when at the last session.

### `require('floaterm').prev_session(cycle?: boolean)`

Switches to the previous(left) session.

- **Parameters**:
  - `cycle` (optional): If `true`, cycles to the last session when at the first session.

## Highlights

Floaterm.nvim provides customizable highlight groups for better visual integration:

- `FloatermIconActive`: Highlight for the active tab icon.
- `FloatermIconInactive`: Highlight for the inactive tab icon.
- `FloatermIconUrgent`: Highlight for the urgent tab icon.

You can override these highlights in your Neovim configuration.

## License

This plugin is licensed under the MIT License.
