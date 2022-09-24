-- Loader for neovim configurations

-- Initialize the loader and the state
local loader = {}
local state = require("cheovim.state")

function loader.get_profiles(path)
	-- No pcall or error checking here because we need to be as speedy as possible
	local selected_profile, profiles = dofile(path)

	return selected_profile, profiles
end

function loader.echo_loading_message()
	-- Print a unique and epic loading message
	local loading_messages = {
		"Brewing up your plugins...",
		"Linearly interpolating your config...",
		"Binary searching for a decent config...",
		"Configuring all the goodies...",
		"Finding who asked...",
		"Making sure nothing breaks...",
		"Loading up your favourite plugin manager...",
		"Finding reasons why Neovim is the best text editor...",
		"Laughing at all the emacs users...",
		"Initializing the plugin manager...",
		"Finding the next occurrence of a leap second...",
		"Listing all the reasons why Kyoko is best waifu...",
		"Telling the population to use Linux...",
		"Arbitrarily executing code...",
		"Censoring all the bad reviews...",
		"Locating Peach's castle...",
		"Dividing by 0...",
		"Breaking the 4th wall...",
		"Just Neovim Just Neovim Just Neovim Just Neovim...",
		"Locating the funny...",
		"Manipulating the stock market...",
		"Spamming all r/emacs comments with hAhA I sTiLl hAvE mY PiNKy...",
		"My devs once had a nightmare where I was written in Emacs Lisp ...",
		"Consooming all the RAM...",
	}

	-- Set a pseudorandom seed
	math.randomseed(os.time())
	vim.notify(loading_messages[math.random(#loading_messages)])
end

function loader.load_state(selected_profile, profiles)
	-- Set the public variables for use by other files
	state.set({
		profiles = profiles,
		current_profile = {
			name = selected_profile,
			path = vim.fn.fnamemodify(profiles[selected_profile][1], ":p:h"),
			init = vim.fn.fnamemodify(profiles[selected_profile][1] .. "/init.lua", ":p"),
		},
	})
end

function loader.add_config_to_rtp()
	local _state = state.state
	-- Save a local copy of current runtimepath
	local rtp = vim.opt.runtimepath:get()
	-- Append current profile path as the second rtp path and shift all other path on it
	table.insert(rtp, 2, _state.current_profile.path)
	-- Save new runtimepath
	vim.opt.runtimepath = rtp

	-- Add user configuration to the current path
	package.path = package.path .. ";" .. vim.fn.expand(_state.current_profile.path) .. "/lua/?.lua"
end

function loader.create_plugin_manager_symlinks()
	local profiles = state.state.profiles
	local selected_profile = state.state.current_profile.name
	local root_plugin_dir = vim.fn._stdpath("data") .. "/site/pack"

	-- Construct a default configuration
	local default_config = {
		plugins = "packer",
	}

	-- Override all the default values with the user's options
	local profile_config = vim.tbl_deep_extend("force", default_config, profiles[selected_profile][2])

	-- Early return to reduce time cost when locking Neovim as we want to be speedy as possible
	if
		vim.fn.isdirectory(root_plugin_dir .. "/" .. vim.split(profile_config.plugins, ":")[1]) == 1
		and vim.fn.isdirectory(root_plugin_dir .. "/cheovim/" .. selected_profile) == 1
	then
		return
	end

	-- Delete all symlinks present inside of site/pack
	for _, dir in ipairs(vim.fn.glob(root_plugin_dir .. "/*", 0, 1, 1)) do
		local symlink = vim.loop.fs_readlink(dir)
		if symlink then
			local profile_symlink = vim.fn.fnamemodify(symlink, ":t")
			if profile_symlink ~= selected_profile then
				vim.loop.fs_unlink(dir, function(_, success)
					return success
				end)
			end
		end
	end

	-- Create all the necessary cheovim directories if they don't already exist
	vim.fn.mkdir(root_plugin_dir .. "/cheovim/" .. selected_profile, "p")

	-- Relink the current config's plugin/ directory with a symlinked version
	-- If we don't do this then packer will write its packer_compiled.lua into a location we cannot track
	vim.loop.fs_unlink(vim.fn._stdpath("config") .. "/plugin", function(err, _)
		if err then
			vim.notify(
				"[Cheovim v0.3] Failed to unlink the Cheovim symlink at " .. vim.fn._stdpath("config") .. "/plugin",
				vim.log.levels.ERROR
			)
		end
	end)
	vim.loop.fs_symlink(
		vim.fn.stdpath("config") .. "/plugin",
		vim.fn._stdpath("config") .. "/plugin",
		{ dir = true },
		function(err, _)
			if err then
				vim.notify(
					"[Cheovim v0.3] Failed to create symlink for " .. vim.fn.stdpath("config") .. "/plugin",
					vim.log.levels.ERROR
				)
			end
		end
	)

	-- Symlink the plugin install location
	local plugin_location_path = root_plugin_dir .. "/" .. vim.split(profile_config.plugins, ":")[1]
	local plugin_location_symlink = vim.loop.fs_readlink(plugin_location_path, function(err, path)
		if not err then
			return path
		end
		return nil
	end)
	if not plugin_location_symlink then
		vim.loop.fs_symlink(
			root_plugin_dir .. "/cheovim/" .. selected_profile,
			plugin_location_path,
			{ dir = true },
			function(err, _)
				if err then
					vim.notify(
						"[Cheovim v0.3] Failed to create symlink for "
							.. root_plugin_dir
							.. "/cheovim/"
							.. selected_profile,
						vim.log.levels.ERROR
					)
				end
			end
		)
	end

	-- If we want to preconfigure some software
	if profile_config.preconfigure then
		-- Split the preconfigure options at every ':'
		local preconfigure_options = vim.split(profile_config.preconfigure, ":", true)

		local install_path = root_plugin_dir
			.. "/"
			.. profile_config.plugins
			.. "/"
			.. preconfigure_options[2]
			.. "/"
			.. (preconfigure_options[1] == "packer" and "packer.nvim" or "paq-nvim")

		local install_dir, _ = vim.loop.fs_scandir(install_path, function(err, data)
			if not err then
				return data
			end
			return nil
		end)

		-- Install plugin manager only if needed
		if not install_dir then
			-- If we elected to autoconfigure packer
			if preconfigure_options[1] == "packer" then
				local branch = "master"

				-- Perform option checking
				if #preconfigure_options < 2 then
					table.insert(preconfigure_options, "start")
				elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
					vim.notify(
						"[Cheovim v0.3] Config option for packer:{opt|start} did not match the allowed values {opt|start}. Assuming packer:start...",
						vim.log.levels.WARN
					)
					table.insert(preconfigure_options, "start")
				end

				-- If we have specified a branch then set it
				if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
					branch = preconfigure_options[3]
				end

				-- Grab packer from GitHub with all the options
				vim.notify("Installing 'packer.nvim', please wait ...", vim.log.levels.INFO)
				vim.fn.system({
					"git",
					"clone",
					"--depth",
					"1",
					"-b",
					branch,
					"https://github.com/wbthomason/packer.nvim.git",
					install_path,
				})
				if vim.v.shell_error ~= 0 then
					vim.notify(
						"[Cheovim v0.3] Failed to install 'packer.nvim', please restart to try again",
						vim.log.levels.ERROR
					)
				else
					vim.notify("[Cheovim v0.3] Successfully installed 'packer.nvim'", vim.log.levels.INFO)
				end
			elseif preconfigure_options[1] == "paq-nvim" then
				local branch = "master"

				-- Perform option checking
				if #preconfigure_options < 2 then
					vim.notify(
						"[Cheovim v0.3] Did not provide second option for paq's preconfiguration. Assuming paq-nvim:start...",
						vim.log.levels.TRACE
					)
					table.insert(preconfigure_options, "start")
				elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
					vim.notify(
						"[Cheovim v0.3] Config option for paq-nvim:{opt|start} did not match the allowed values {opt|start}. Assuming paq-nvim:start...",
						vim.log.levels.WARN
					)
					table.insert(preconfigure_options, "start")
				end

				-- If we have specified a branch then set it
				if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
					branch = preconfigure_options[3]
				end

				-- Grab paq-nvim from GitHub with all the options
				vim.notify("[Cheovim v0.3] Installing 'paq-nvim', please wait ...", vim.log.levels.INFO)
				vim.fn.system({
					"git",
					"clone",
					"--depth",
					"1",
					"-b",
					branch,
					"https://github.com/savq/paq-nvim.git",
					install_path,
				})
				if vim.v.shell_error ~= 0 then
					vim.notify(
						"[Cheovim v0.3] Failed to install 'paq-nvim', please restart to try again",
						vim.log.levels.ERROR
					)
				else
					vim.notify("[Cheovim v0.3] Successfully installed 'paq-nvim'", vim.log.levels.INFO)
				end
			else
				-- We do not know of such a configuration, so print an error
				vim.notify(
					("Unable to preconfigure %s, such a configuration is not available, sorry!"):format(
						preconfigure_options[1]
					),
					vim.log.levels.ERROR
				)
			end
		end
		install_dir:closedir()
	end

	if type(profile_config.setup) == "string" then
		vim.cmd(profile_config.setup)
	elseif type(profile_config.setup) == "function" then
		profile_config.setup()
	end

	-- Invoke the profile's init.lua
	dofile(profiles[selected_profile][1] .. "/init.lua")

	-- Issue the success message
	-- vim.notify("[Cheovim v0.3] Successfully loaded new configuration", vim.log.levels.INFO)
end

-- Pulls a config from a URL and returns the path of the stored config
function loader.handle_url(selected_profile, profiles)
	-- Store the URL in a variable
	local url = profiles[selected_profile][1]
	-- Set the install location for remote configurations
	local cheovim_pulled_config_location = vim.fn._stdpath("data") .. "/cheovim/"

	-- Early return if config already exists, we want to be speedy as possible
	if vim.fn.isdirectory(cheovim_pulled_config_location .. selected_profile) == 1 then
		return
	end

	-- Create the directory if it doesn't already exist
	vim.fn.mkdir(cheovim_pulled_config_location, "p")

	-- Check whether we already have a pulled repo in that location
	local dir, _ = vim.loop.fs_scandir(cheovim_pulled_config_location .. selected_profile, function(err, data)
		if not err then
			return data
		end
		return nil
	end)

	-- If we don't then pull it down!
	if not dir then
		vim.notify("[Cheovim v0.3] Pulling your config via git ...", vim.log.levels.INFO)
		vim.fn.system({
			"git",
			"clone",
			url,
			cheovim_pulled_config_location .. selected_profile,
		})
		if vim.v.shell_error ~= 0 then
			vim.notify("[Cheovim v0.3] Failed to pull your config, please restart to try again", vim.log.levels.ERROR)
		else
			vim.notify("[Cheovim v0.3] Successfully pulled your config", vim.log.levels.INFO)
		end
	end
	dir:closedir()

	-- Return the path of the installed configuration
	return cheovim_pulled_config_location .. selected_profile
end

function loader.create_plugin_symlink()
	local profiles = state.state.profiles
	local selected_profile = state.state.current_profile.name
	local selected = profiles[selected_profile]

	-- If we haven't selected a valid profile or that profile doesn't come with a path then error out
	if not selected then
		vim.notify("[Cheovim v0.3] Unable to find profile with name" .. selected_profile, vim.log.levels.ERROR)
		return
	elseif not selected[1] then
		vim.notify(
			"[Cheovim v0.3] Unable to load profile with name"
				.. selected_profile
				.. "- the first element of the profile must be a path.",
			vim.log.levels.ERROR
		)
		return
	end

	-- Clone the current stdpath function definition into an unused func
	vim.fn._stdpath = vim.fn.stdpath

	-- Override vim.fn.stdpath to manipulate the data returned by it. Yes, I know, changing core functions
	-- is really bad practice in any codebase, however this is our only way to make things like LunarVim etc. work
	vim.fn.stdpath = function(what)
		if what:lower() == "config" then
			return selected[1]
		end
		return vim.fn._stdpath(what)
	end

	if string.find(selected[1], "https://") ~= nil then
		selected[1] = loader.handle_url(selected_profile, profiles)
	else
		-- Expand the current path (i.e. convert ~ to the home directory etc.)
		-- NOTE: we do not expand it if configuration path is an URL as handle_url already expands it
		selected[1] = vim.fn.expand(selected[1])
	end

	-- Unlink the plugin/ directory so packer_compiled.{vim,lua} doesn't autotrigger
	if vim.fn.isdirectory(vim.fn._stdpath("config") .. "/plugin") == 1 then
		vim.loop.fs_unlink(vim.fn._stdpath("config") .. "/plugin", function(err, _)
			if err then
				vim.notify(
					"[Cheovim v0.3] Failed to unlink the Cheovim symlink at " .. vim.fn._stdpath("config") .. "/plugin",
					vim.log.levels.ERROR
				)
			end
		end)
	end

	-- Load the config and restore the plugin/ directory
	loader.create_plugin_manager_symlinks()
	dofile(selected[1] .. "/init.lua")
	if vim.fn.isdirectory(vim.fn.stdpath("config") .. "/plugin") == 1 then
		vim.loop.fs_symlink(
			vim.fn.stdpath("config") .. "/plugin",
			vim.fn._stdpath("config") .. "/plugin",
			{ dir = true },
			function(err, _)
				if err then
					vim.notify(
						"[Cheovim v0.3] Failed to create symlink for " .. vim.fn.stdpath("config") .. "/plugin",
						vim.log.levels.ERROR
					)
				end
			end
		)
	end
end

return loader
