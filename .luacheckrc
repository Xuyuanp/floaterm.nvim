stds.nvim = {
	read_globals = { "jit", "vim" },
}
std = "lua51+nvim"
cache = true
self = false
include_files = { "lua/", "*.lua" }
exclude_files = { "deps/**/*.lua" }
ignore = {
	"631", -- max_line_length
	"212/_.*", -- unused argument, for vars with "_" prefix
	"122", -- setting readonly field
	"411", -- redefined local var
}
