return {
	-- @Summary An autocompletion function for the :Cheovim command
	-- @Description Returns a list of potential matches for the currently supplied argument
	cheovim_autocomplete = function(part, command)
		local split_command = vim.split(command, " ")
		-- Remove command from table
		table.remove(split_command, 1)
		-- Remove blank string from table
		if #split_command == 1 and split_command[1] == "" then
			table.remove(split_command, 1)
		end

		local cmds = { "clean-plugins", "clean-remote-configs", "deep-clean", "force-reload", "reload", "version" }

		-- If `:Cheovim |<tab>`
		if part:len() == 0 and #split_command == 0 then
			table.sort(cmds, function(current, next)
				return current:len() > next:len()
			end)
			return cmds
		end

		if part:len() >= 1 and #split_command == 1 then
			local possible_matches = vim.tbl_filter(function(cmd)
				if cmd:match("^" .. part) then
					return cmd
				end
			end, vim.tbl_values(cmds))
			return possible_matches
		end
	end,

	-- @Summary Callback for executing a :Cheovim call
	-- @Description Invoked whenever the user issues a call to :Cheovim
	-- @Param args (table) - the list of arguments as returned by <f-args>
	cheovim_execute_func = function(args)
		local state = require("cheovim.state").state

		-- Extract the first argument from that list since we should only be receiving one argument
		local arg = args.fargs[1]

		-- If we want to print the current version then do so
		if arg == "version" then
			vim.notify("Cheovim version 0.3, written by NTBBloodbath and Vhyrro ", vim.log.levels.INFO)
		elseif arg == "reload" then -- If we would like to reload the current config on next boot then
			-- Unlink the cheovim symlink to trigger a reload on next startup
			vim.loop.fs_unlink(vim.fn.stdpath("data") .. "/site/pack/cheovim/start/cheovim", function(err, _)
				if err then
					vim.notify(
						"[Cheovim v0.3] Failed to unlink the Cheovim symlink at "
							.. vim.fn.stdpath("data")
							.. "/site/pack/cheovim/start/cheovim",
						vim.log.levels.ERROR
					)
				else
					vim.notify(
						"[Cheovim v0.3] Removed configuration symlink, to commence with the reload please restart Neovim.",
						vim.log.levels.WARN
					)
				end
			end)
		elseif arg == "force-reload" then -- If we would like to fully reload our configuration then
			-- Unlink the cheovim symlink to trigger a reload on next startup
			vim.loop.fs_unlink(vim.fn.stdpath("data") .. "/site/pack/cheovim/start/cheovim", function(err, _)
				if err then
					vim.notify(
						"[Cheovim v0.3] Failed to unlink the Cheovim symlink at "
							.. vim.fn.stdpath("data")
							.. "/site/pack/cheovim/start/cheovim",
						vim.log.levels.ERROR
					)
				end
			end)

			-- Remove the remotely installed configuration if present
			vim.cmd("silent! !rm -rf " .. vim.fn.stdpath("data") .. "/cheovim/" .. state.current_profile.name)

			vim.notify(
				"[Cheovim v0.3] Please restart your editor to commence with the full reload.",
				vim.log.levels.WARN
			)
		elseif arg == "clean-remote-configs" then -- If we would like to clean unused remote configurations then
			-- Get all the currently installed configurations and store them in a clean list
			local configs = (function()
				local result = vim.fn.glob(vim.fn.stdpath("data") .. "/cheovim/*", 0, 1)
				for i, config in ipairs(result) do
					local split = vim.split(config, "/")
					result[i] = split[#split]
				end
				return result
			end)()

			-- Get all of the configurations currently defined in the profiles.lua file
			local present_configs = (function()
				local profiles = state.profiles
				local result = {}

				for name, profile in pairs(profiles) do
					if profile[2] and profile[2].url then
						table.insert(result, name)
					end
				end

				return result
			end)()

			-- Track the amount of removed configurations
			local removed_config_count = 0

			-- For every configuration that we have installed
			for _, config in ipairs(configs) do
				-- If it is not present in the list of configs we have specified then remove it
				if not vim.tbl_contains(present_configs, config) then
					vim.notify(
						"[Cheovim v0.3] Unused configuration",
						config,
						"detected, removing...",
						vim.log.levels.INFO
					)
					vim.cmd("silent! !rm -rf " .. vim.fn.stdpath("data") .. "/cheovim/" .. config)
					removed_config_count = removed_config_count + 1
				end
			end

			-- Issue the finish message
			if removed_config_count > 0 then
				vim.notify(
					"[Cheovim v0.3] Cheovim removed",
					removed_config_count,
					"configurations.",
					vim.log.levels.INFO
				)
			else
				vim.notify("[Cheovim v0.3] Cheovim removed no configurations, you're all good!", vim.log.levels.INFO)
			end
		elseif arg == "clean-plugins" then
			-- Unlink the cheovim symlink to trigger a reload on next startup
			vim.loop.fs_unlink(vim.fn.stdpath("data") .. "/site/pack/cheovim/start/cheovim", function(err, _)
				if err then
					vim.notify(
						"[Cheovim v0.3] Failed to unlink the Cheovim symlink at "
							.. vim.fn.stdpath("data")
							.. "/site/pack/cheovim/start/cheovim",
						vim.log.levels.ERROR
					)
				end
			end)

			-- Remove all the current config's plugins
			vim.cmd("silent! !rm -rf " .. vim.fn.stdpath("data") .. "/site/pack/cheovim/" .. state.current_profile.name)

			vim.notify("[Cheovim v0.3] Cleaned all the current configuration's plugins!", vim.log.levels.INFO)
		elseif arg == "deep-clean" then
			vim.cmd([[
				Cheovim clean-plugins
				Cheovim force-reload
			]])
		else
			vim.notify(
				"[Cheovim v0.3] Unrecognized argument '" .. arg .. "' for :Cheovim command",
				vim.log.levels.ERROR
			)
		end
	end,

	-- @Summary Invoke a post-load command specified by the user
	-- @Description Triggered whenever a configuration is switched and whenever the user has set the `config` option
	cheovim_config_callback = function()
		local state = require("cheovim.state").state

		-- If our profile hasn't changed since last load then don't trigger
		if not state.profile_changed then
			return
		end

		-- Grab the configuration for our current profile
		local profile_config = state.profiles[state.current_profile.name][2]

		-- If we have defined a config variable then
		if profile_config.config then
			-- Depending on the type of the config variable execute the code in a different way
			-- NOTE: We defer for 100ms here to be absolutely sure the config has loaded
			vim.defer_fn(
				vim.schedule_wrap(function()
					if type(profile_config.config) == "string" then
						vim.cmd(profile_config.config)
					elseif type(profile_config.config) == "function" then
						profile_config.config()
					end
				end),
				100
			)
		end
	end,
}
