-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
	vim.cmd("set rtp+=deps/mini.test")

	-- Set up 'mini.test'
	require("mini.test").setup()

	_G.test_helper = function()
		local child = MiniTest.new_child_neovim()

		local function new_set()
			return MiniTest.new_set({
				hooks = {
					pre_case = function()
						child.restart({ "-u", "scripts/minimal_init.lua" })
					end,
					post_case = function()
						child.stop()
					end,
				},
			})
		end
		return child, new_set
	end
end
