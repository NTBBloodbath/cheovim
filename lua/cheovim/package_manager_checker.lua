local checker, logger = {

	package_manager = { "packer", "packer.nvim" }

}, require('cheovim.logger')

-- @Summary Universal function to check for the availability of a package manager
function checker:check()
	local err, _ = pcall(require, self.package_manager[1])

	return err
end

function checker:get_package_manager(error_check)

	vim.cmd("packadd " .. self.package_manager[2])

	if error_check then
		if not self:check() then
			logger.error("Unable to locate any package managers (currently cheovim supports packer.nvim). Did you use the install script?")
			return
		end
	end

	return require(self.package_manager[1])
end

return checker
