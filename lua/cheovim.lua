local loader, log = require('cheovim.loader'), require('cheovim.logger')

local selected_profile, profiles = loader.get_profiles(vim.fn.stdpath("config") .. "/profiles.lua")

if not selected_profile then
	log.error("Failed to load cheovim: profile could not be found.")
	return
end

loader.create_plugin_symlink(selected_profile, profiles)
