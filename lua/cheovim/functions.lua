local log = require('cheovim.logger')

function cheovim_autocomplete(_, command)
	local split_command = vim.split(command, " ")

	return vim.tbl_filter(function(key) return key:find(split_command[#split_command]) end, { "clean-remote-configs", "force-reload", "reload", "version" })
end

return {

	cheovim_execute_func = function(...)
		local arg = ({ ... })[1]

		if arg == "version" then
			log.info("Cheovim Version 0.2, Written by NTBBloodbath and Vhyrro ")
		elseif arg == "reload" then
			vim.loop.fs_unlink(vim.fn.stdpath("data") .. "/site/pack/cheovim/start/cheovim")
			log.warn("Removed configuration symlink, to commence with the reload please restart Neovim.")
		elseif arg == "force-reload" then
			vim.loop.fs_unlink(vim.fn.stdpath("data") .. "/site/pack/cheovim/start/cheovim")
			vim.cmd("silent! !rm -rf " .. vim.fn.stdpath("data") .. "/cheovim/" .. require('cheovim.loader').selected_profile)
			log.warn("Please restart your editor to commence with the full reload.")
		elseif arg == "clean-remote-configs" then
			local configs = (function()
				local result = vim.fn.glob(vim.fn.stdpath("data") .. "/cheovim/*", 0, 1)
				for i, config in ipairs(result) do
					local split = vim.split(config, "/")
					result[i] = split[#split]
				end
				return result
			end)()

			local present_configs = (function()
				local profiles = require('cheovim.loader').profiles
				local result = {}

				for name, profile in pairs(profiles) do
					if profile[2] and profile[2].url then
						table.insert(result, name)
					end
				end

				return result
			end)()

			local removed_config_count = 0

			for _, config in ipairs(configs) do
				if not vim.tbl_contains(present_configs, config) then
					log.info("Unused configuration", config, "detected, removing...")
					vim.cmd("silent! !rm -rf " .. vim.fn.stdpath("data") .. "/cheovim/" .. config)
					removed_config_count = removed_config_count + 1
				end
			end

			if removed_config_count > 0 then
				log.info("Cheovim removed", removed_config_count, "configurations.")
			else
				log.info("Cheovim removed no configurations, you're all good!")
			end
		end
	end,

	cheovim_config_callback = function()
		local loader = require('cheovim.loader')

        if not loader.profile_changed then return end

		local profile_config = loader.profiles[loader.selected_profile][2]

		if profile_config.config then
			vim.defer_fn(vim.schedule_wrap(function()
                if type(profile_config.config) == "string" then
                    vim.cmd(profile_config.config)
                elseif type(profile_config.config) == "function" then
                    profile_config.config()
                end
            end), 100)
		end
	end,

}
