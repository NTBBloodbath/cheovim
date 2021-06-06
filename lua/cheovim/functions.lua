local log = require('cheovim.logger')

function cheovim_autocomplete(_, command)
	local split_command = vim.split(command, " ")

	return vim.tbl_filter(function(key) return key:find(split_command[#split_command]) end, { "force-reload", "reload", "version" })
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
		end
	end

}
