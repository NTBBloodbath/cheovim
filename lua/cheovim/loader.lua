-- Loader for neovim configurations

-- Initialize the loader and logger
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

    -- Construct a default configuration
	local default_config = {
		url = false,
		plugins = "packer",
		preconfigure = nil,
	}

    -- Override all the default values with the user's options
	local profile_config = vim.tbl_deep_extend("force", default_config, profiles[selected_profile][2])
	local root_plugin_dir = vim.fn._stdpath("data") .. "/site/pack"

    -- Delete all symlinks present inside of site/pack
	for _, symlink in ipairs(vim.fn.glob(root_plugin_dir .. "/*", 0, 1, 1)) do
		vim.loop.fs_unlink(symlink)
	end

    -- Create all the necessary cheovim directories if they don't already exist
	vim.loop.fs_mkdir(root_plugin_dir .. "/cheovim/" .. selected_profile, 16877)
	vim.loop.fs_mkdir(root_plugin_dir .. "/cheovim/" .. selected_profile .. "/plugin", 16877)

    -- Relink the current config's plugin/ directory with a symlinked version
    -- If we don't do this then packer will write its packer_compiled.vim into a location we cannot track
	vim.loop.fs_unlink(vim.fn._stdpath("config") .. "/plugin")
	vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile .. "/plugin", vim.fn._stdpath("config") .. "/plugin")

    -- Symlink the plugin install location
	vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile, root_plugin_dir .. "/" .. profile_config.plugins, { dir = true })

    -- If we want to preconfigure some software
	if profile_config.preconfigure then
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
		}

		-- Set a pseudorandom seed
		math.randomseed(os.time())
		vim.cmd(("echom \"%s\""):format(loading_messages[math.random(#loading_messages)]))

		-- Cheovim can configure itself for several known configurations, they are defined here
		local config_matches = {
			["doom-nvim"] = "packer:opt",
			["lunarvim"] = "packer:start",
			["vapournvim"] = "packer:start",
			["nv-ide"] = "packer:start",
		}

		-- Check whether the user has picked one of the above configs
		local config_match = config_matches[profile_config.preconfigure:lower()]

		-- If they have then set profile_config.preconfigure to its respective option in the config_matches table
		profile_config.preconfigure = config_match or profile_config.preconfigure

		-- Split the preconfigure options at every ':'
		local preconfigure_options = vim.split(profile_config.preconfigure, ":", true)

        -- If we elected to autoconfigure packer
		if preconfigure_options[1] == "packer" then
			local branch = "master"

            -- Perform option checking
			if #preconfigure_options < 2 then
				log.trace("Did not provide second option for the packer preconfiguration. Assuming packer:start...")
				table.insert(preconfigure_options, "start")
			elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
				log.warn("Config option for packer:{opt|start} did not match the allowed values {opt|start}. Assuming packer:start...")
				table.insert(preconfigure_options, "start")
			end

            -- If we have specified a branch then set it
			if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
				branch = preconfigure_options[3]
			end

			-- Grab packer from GitHub with all the options
			vim.cmd("silent !git clone https://github.com/wbthomason/packer.nvim -b " .. branch .. " " .. root_plugin_dir .. "/" .. profile_config.plugins .. "/" .. preconfigure_options[2] .. "/packer.nvim")
		elseif preconfigure_options[1] == "paq-nvim" then
			local branch = "master"

            -- Perform option checking
			if #preconfigure_options < 2 then
				log.trace("Did not provide second option for paq's preconfiguration. Assuming paq-nvim:start...")
				table.insert(preconfigure_options, "start")
			elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
				log.warn("Config option for paq-nvim:{opt|start} did not match the allowed values {opt|start}. Assuming paq-nvim:start...")
				table.insert(preconfigure_options, "start")
			end

            -- If we have specified a branch then set it
			if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
				branch = preconfigure_options[3]
			end

			-- Grab packer from GitHub with all the options
			vim.cmd("silent !git clone https://github.com/savq/paq-nvim -b " .. branch .. " " .. root_plugin_dir .. "/" .. profile_config.plugins .. "/" .. preconfigure_options[2] .. "/paq-nvim")
		else -- We do not know of such a configuration, so print an error
			log.error(("Unable to preconfigure %s, such a configuration is not available, sorry!"):format(preconfigure_options[1]))
		end
	end

    -- Invoke the profile's init.lua
	dofile(profiles[selected_profile][1] .. "/init.lua")

    -- If we want to invoke a command or a lua function then do so (currently does not work)
	if profile_config.config then
		if type(profile_config.config) == "string" then
			vim.cmd(profile_config.config)
		elseif type(profile_config.config) == "function" then
			profile_config.config()
		end
	end

	-- Issue the success message
	log.info("Successfully loaded new configuration")
end

function loader.handle_url(selected_profile, profiles)

	local url = profiles[selected_profile][1]
	local cheovim_pulled_config_location = vim.fn._stdpath("data") .. "/cheovim/"

	vim.loop.fs_mkdir(cheovim_pulled_config_location, 16877)

	local dir, err_message = vim.loop.fs_scandir(cheovim_pulled_config_location .. selected_profile)

	if not dir then
		log.info("Pulling your config via git...")
		vim.cmd("!git clone " .. url .. " " .. cheovim_pulled_config_location .. selected_profile)
	end

	return cheovim_pulled_config_location .. selected_profile

end

function loader.create_plugin_symlink(selected_profile, profiles)

	local selected = profiles[selected_profile]

	if not selected then
		log.error("Unable to find profile with name", selected_profile)
		return
	elseif not selected[1] then
		log.error("Unable to load profile with name", selected_profile, "- the first element of the profile must be a path.")
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

    -- Set this variable to the site/pack location
	local root_plugin_dir = vim.fn._stdpath("data") .. "/site/pack"

    -- Unlink the plugins/ directory so packer_compiled.vim doesn't autotrigger
	vim.loop.fs_unlink(vim.fn._stdpath("config") .. "/plugins")

	if selected[2] and selected[2].url then
		selected[1] = loader.handle_url(selected_profile, profiles)
	end

	selected[1] = vim.fn.expand(selected[1])

    -- Create the necessary directories if they don't already exist
	vim.loop.fs_mkdir(root_plugin_dir .. "/cheovim/", 16877) -- Permissions: 0775

	local start_directory = root_plugin_dir .. "/cheovim/start"

    -- Create a start/ directory for the cheovim configuration
	vim.loop.fs_mkdir(start_directory, 16877)

    -- Read the cheovim symlink from the start/ directory
	local symlink = vim.loop.fs_readlink(start_directory .. "/cheovim")

    -- If that symlink does not exist or it differs from the selected config
    -- then update the current configuration and reload everything
	if not symlink then
		vim.loop.fs_symlink(selected[1], start_directory .. "/cheovim", { dir = true })
		loader.create_plugin_manager_symlinks(selected_profile, profiles)
	elseif symlink ~= selected[1] then
		vim.loop.fs_unlink(start_directory .. "/cheovim")
		vim.loop.fs_symlink(selected[1], start_directory .. "/cheovim", { dir = true })
		loader.create_plugin_manager_symlinks(selected_profile, profiles)
	else -- Else load the config and restore the plugin/ directory
		dofile(selected[1] .. "/init.lua")
		vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile .. "/plugin", vim.fn._stdpath("config") .. "/plugin")
	end

end

return loader
