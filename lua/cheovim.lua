-- Initialize the loader
require("cheovim.functions")
local loader = require("cheovim.loader")

-- Grab the selected profiles from the profiles file
local selected_profile, profiles = loader.get_profiles(vim.fn.stdpath("config") .. "/profiles.lua")

-- If our supplied profile is nil then error out
if not selected_profile then
	vim.notify("[Cheovim v0.3] Failed to load cheovim: profile could not be found.", vim.log.levels.ERROR)
	return
end

-- Echo random loading message
loader.echo_loading_message()

-- Create all the plugins if necessary and start up the rest of cheovim!
loader.load_state(selected_profile, profiles)
loader.add_config_to_rtp()
loader.create_plugin_symlink()

vim.api.nvim_create_augroup("Cheovim", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	desc = "Invoke a post-load command specified by the user once the user configuration is loaded",
	group = "Cheovim",
	pattern = "*",
	callback = function()
		require("cheovim.functions").cheovim_config_callback()
	end,
})

vim.api.nvim_create_user_command("Cheovim", require("cheovim.functions").cheovim_execute_func, {
	desc = "Cheovim command interface",
	nargs = 1,
	complete = require("cheovim.functions").cheovim_autocomplete,
})
