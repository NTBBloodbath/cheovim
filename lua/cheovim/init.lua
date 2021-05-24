---[[------------------------------------------------------------------------------------------]]---
--                                                                                                --
--      ___           ___           ___           ___                                    ___      --
--     /  /\         /__/\         /  /\         /  /\          ___        ___          /__/\     --
--    /  /:/         \  \:\       /  /:/_       /  /::\        /__/\      /  /\        |  |::\    --
--   /  /:/           \__\:\     /  /:/ /\     /  /:/\:\       \  \:\    /  /:/        |  |:|:\   --
--  /  /:/  ___   ___ /  /::\   /  /:/ /:/_   /  /:/  \:\       \  \:\  /__/::\      __|__|:|\:\  --
-- /__/:/  /  /\ /__/\  /:/\:\ /__/:/ /:/ /\ /__/:/ \__\:\  ___  \__\:\ \__\/\:\__  /__/::::| \:\ --
-- \  \:\ /  /:/ \  \:\/:/__\/ \  \:\/:/ /:/ \  \:\ /  /:/ /__/\ |  |:|    \  \:\/\ \  \:\~~\__\/ --
--  \  \:\  /:/   \  \::/       \  \::/ /:/   \  \:\  /:/  \  \:\|  |:|     \__\::/  \  \:\       --
--   \  \:\/:/     \  \:\        \  \:\/:/     \  \:\/:/    \  \:\__|:|     /__/:/    \  \:\      --
--    \  \::/       \  \:\        \  \::/       \  \::/      \__\::::/      \__\/      \  \:\     --
--     \__\/         \__\/         \__\/         \__\/           ~~~~                   \__\/     --
--                                                                                                --
--                                                                                                --
--                               cheovim - Neovim profile switcher                                --
---]]------------------------------------------------------------------------------------------[[---

local utils = require('cheovim.utils')
local log = require('cheovim.utils.log')
local filter = vim.tbl_filter

---- Variables -----------------------------------------------------------------
--------------------------------------------------------------------------------

local cheovim_version = '0.1.0'
local user_home = os.getenv('HOME')
local config_home =
	(os.getenv('XDG_CONFIG_HOME') or user_home .. '/.config')

local cheovim_profiles_path =
	string.format('%s/%s', config_home, 'cheovim/profiles.lua')

local cheovim_default_profile_path =
	string.format('%s/%s', config_home, 'cheovim/profile')

local cheovim_profile_name = utils.read_file(cheovim_default_profile_path)[1]
	or 'default'

---- Functions -----------------------------------------------------------------
--------------------------------------------------------------------------------

-- get_profile looks for the profile which is currently in use
-- @return table or nil
local function get_profile()
	local current_profile = {}

	if not utils.file_exists(cheovim_profiles_path) then
		log.error('Cannot find profiles file')
		return nil
	else
		-- Load Profiles table
		vim.cmd('luafile ' .. cheovim_profiles_path)
		for name, path in pairs(Profiles) do
			if name == cheovim_profile_name then
				current_profile = {
					name = name,
					path = path,
				}
				break
			end
		end
	end

	return current_profile
end

-- cheovim_load_config_files removes the old configuration files if they exists
-- and loads the current profile configuration files
local function cheovim_load_config_files()
	local current_profile = get_profile()
	local current_profile_path = utils.expand_home(current_profile.path)

	local nvim_config_path = vim.fn.stdpath('config')
	local nvim_core_dirs = {
		'after',
		'autoload',
		'colors',
		'doc',
		'templates',
		'ftdetect',
		'ftplugin',
		'syntax',
		'plugin',
		'snippets',
		'spell',
	}

	-- Symlink configuration Vim directories, e.g. autoload
	for _, nvim_dir in ipairs(nvim_core_dirs) do
		local prev_config_dir =
			utils.readlink(nvim_config_path .. '/' .. nvim_dir, false)

		-- If there's no previous config dir symlink or if the previous
		-- config dir symlink is not from the current profile then remove
		-- and create it again
		if
			not prev_config_dir
			or (
				prev_config_dir
				and not prev_config_dir:find(current_profile.name, 1, true)
			)
		then
			utils.symlink(
				current_profile_path .. '/' .. nvim_dir,
				nvim_config_path .. '/' .. nvim_dir,
				true,
				{ dir = true }
			)
		end
	end

	---- Symlink also the files at config root, e.g. lv-settings.lua in LunarVim
	---- or doomrc in doom-nvim
	-- Ignore unnecessary files, like README.md, the configs LICENSE and Neovim
	-- dirs like `autoload/` since they should be already symlinked
	local config_ignore_files = {
		'init.vim',
		'init.lua',
		'LICENSE',
		'*.md',
		'lua',
		table.unpack(nvim_core_dirs),
	}
	local config_extra_files =
		utils.get_files(current_profile_path, config_ignore_files)
	for _, config_file in ipairs(config_extra_files) do
		local prev_config_file =
			utils.readlink(nvim_config_path .. '/' .. config_file, false)

		-- If there's no previous config file symlink or if the previuos
		-- config file symlink is not from the current profile then remove
		-- and create it again
		if
			not prev_config_file
			or (
					prev_config_file
					and not prev_config_file:find(current_profile.name, 1, true)
				)
		then
			utils.symlink(
				current_profile_path .. '/' .. config_file,
				nvim_config_path .. '/' .. config_file,
				true
			)
		end
	end

	--- Remove symlinks of profile-specific things
	local nvim_config_files = utils.get_files(nvim_config_path)
	for _, config_file in ipairs(nvim_config_files) do
		local prev_config_file =
			utils.readlink(nvim_config_path .. '/' .. config_file, false)

		if
			prev_config_file
			and not prev_config_file:find(current_profile.name, 1, true)
			-- and (not config_file:find('lua'))
		then
			utils.unlink(nvim_config_path .. '/' .. config_file)
		end
	end
end

function Cheovim_load_user_init()
	log.info('Starting version ' .. cheovim_version)
	local current_profile = get_profile()
	local current_profile_path = utils.expand_home(current_profile.path)

	-- Set possible init files for Neovim, defaults to `init.vim`
	local inits = {
		current_profile_path .. '/init.vim',
		current_profile_path .. '/init.lua',
	}
	local init_file = utils.head(filter(utils.file_exists, inits))
		or utils.head(inits)

	-- Check if cheovim should load a Vimscript init or a Lua init
	local init_type = utils.get_file_extension(init_file)

	-- Add lua files to Lua's path if there's a lua directory
	if utils.file_exists(current_profile_path .. '/lua/') then
		package.path = current_profile_path
			.. '/lua/?/init.lua;'
			.. current_profile_path
			.. '/lua/?.lua;'
			.. package.path
	end

	-- Load the config files from the current profile, e.g. `autoload` and files
	-- at the profile root path like `doomrc` in Doom Nvim or `lv-settings.lua`
	-- in LunarVim
	cheovim_load_config_files()

	-- Source init file
	if init_type:find('lua') then
		vim.cmd('luafile ' .. init_file)
	else
		vim.cmd('source ' .. init_file)
	end

	log.info('Loaded ' .. cheovim_profile_name .. ' profile')
end
