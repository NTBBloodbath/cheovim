-- Loader for neovim configurations

local loader, checker = {}, require('cheovim.package_manager_checker')

function loader.get_profiles(path)
	-- No pcall or error checking here because we need to be as speedy as possible
	local selected_profile, profiles = dofile(path)

	if profiles[selected_profile] then
		package.path = package.path .. ";" .. profiles[selected_profile][1] .. "/lua/?.lua"
		dofile(profiles[selected_profile][1] .. "/init.lua")
	end
end

return loader
