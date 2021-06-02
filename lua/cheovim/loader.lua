-- Loader for neovim configurations

local loader, log = {}, require('cheovim.logger')

function loader.get_profiles(path)
	-- No pcall or error checking here because we need to be as speedy as possible
	local selected_profile, profiles = dofile(path)

	-- If the profile exists add it to the current path and return it
	if profiles[selected_profile] then
		package.path = package.path .. ";" .. profiles[selected_profile][1] .. "/lua/?.lua"
		return selected_profile, profiles
	end
end

function loader.create_plugin_manager_symlinks(selected_profile, profiles)

	local default_config = {
		url = false,
		plugins = "packer",
		preconfigure = nil,
	}

	local profile_config = vim.tbl_deep_extend("force", default_config, profiles[selected_profile][2])
	local root_plugin_dir = vim.fn.stdpath("data") .. "/site/pack"

	for _, symlink in ipairs(vim.fn.glob(root_plugin_dir .. "/*", 0, 1, 1)) do
		vim.loop.fs_unlink(symlink)
	end

	vim.loop.fs_mkdir(root_plugin_dir .. "/cheovim/" .. selected_profile, 16877)
	vim.loop.fs_mkdir(root_plugin_dir .. "/cheovim/" .. selected_profile .. "/plugin", 16877)

	vim.loop.fs_unlink(vim.fn.stdpath("config") .. "/plugin")
	vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile .. "/plugin", vim.fn.stdpath("config") .. "/plugin")

	vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile, root_plugin_dir .. "/" .. profile_config.plugins, { dir = true })

	if profile_config.preconfigure then
		local preconfigure_options = vim.split(profile_config.preconfigure, ":", true)

		if preconfigure_options[1] == "packer" then
			local branch = "master"

			if #preconfigure_options < 2 then
				log.warn("Did not provide enough options for the packer preconfiguration option. Format: packer:{opt|start}. Assuming packer:start...")
				table.insert(preconfigure_options, "start")
			elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
				log.warn("Config option for packer:{opt|start} did not match the allowed values {opt|start}. Assuming packer:start...")
				table.insert(preconfigure_options, "start")
			end

			if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
				branch = preconfigure_options[3]
			end

			vim.cmd("silent !git clone https://github.com/wbthomason/packer.nvim -b " .. branch .. " " .. root_plugin_dir .. "/" .. profile_config.plugins .. "/" .. preconfigure_options[2] .. "/packer.nvim")
		end
	end

	dofile(profiles[selected_profile][1] .. "/init.lua")

	if profile_config.config then
		if type(profile_config.config) == "string" then
			vim.cmd(profile_config.config)
		elseif type(profile_config.config) == "function" then
			profile_config.config()
		end
	end
end

function loader.create_plugin_symlink(selected_profile, profiles)

	local root_plugin_dir = vim.fn.stdpath("data") .. "/site/pack"

	vim.loop.fs_unlink(vim.fn.stdpath("config") .. "/plugins")

	vim.loop.fs_mkdir(root_plugin_dir .. "/cheovim/", 16877) -- Permissions: 0775

	local start_directory = root_plugin_dir .. "/cheovim/start"

	vim.loop.fs_mkdir(start_directory, 16877)

	local symlink = vim.loop.fs_readlink(start_directory .. "/cheovim")

	if not symlink then
		vim.loop.fs_symlink(profiles[selected_profile][1], start_directory .. "/cheovim", { dir = true })
		loader.create_plugin_manager_symlinks(selected_profile, profiles)
	elseif symlink ~= profiles[selected_profile][1] then
		vim.loop.fs_unlink(start_directory .. "/cheovim")
		vim.loop.fs_symlink(profiles[selected_profile][1], start_directory .. "/cheovim", { dir = true })
		loader.create_plugin_manager_symlinks(selected_profile, profiles)
	else
		dofile(profiles[selected_profile][1] .. "/init.lua")
		vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile .. "/plugin", vim.fn.stdpath("config") .. "/plugin")
	end

end

return loader
