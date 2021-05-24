local M = {}

local log = require('cheovim.utils.log')

---- File Utilities -----------------------------------------------------------
-------------------------------------------------------------------------------

-- expand_home expands the home directory
-- @usage expand_home('~/.config/doom-nvim') → '/home/user/.config/doom-nvim'
-- @tparam string path The path where home should be expanded
-- @return string or nil
M.expand_home = function(path)
	-- Expand `$HOME` and `~`
	if string.find(path, '$HOME') then
		path = string.gsub(path, '$HOME', os.getenv('HOME'))
	elseif string.find(path, '~') then
		path = string.gsub(path, '~', os.getenv('HOME'))
	end

	return path
end

-- file_exists checks if the provided file exists
-- @usage file_exists('~/.config/cheovim/nvim-profile.lua') → true
-- @tparam string file The path of the file to check
-- @return boolean
M.file_exists = function(file)
	file = io.open(M.expand_home(file), 'rb')
	if file then
		file:close()
	end

	return file ~= nil
end

-- read_file reads the content of the provided file
-- @usage read_file('~/.config/cheovim/nvim-profile') → {'doom-nvim'}
-- @tparam string file The file to read
-- @return {string...} a table with the file content
M.read_file = function(file)
	if not M.file_exists(file) then
		return {}
	end

	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end

	return lines
end

-- is_dir_empty checks if the given directory is empty
-- @tparam string dir The directory to check
-- @return boolean
local function is_dir_empty(dir)
	local ls = string.format("ls -1qA %s | grep -q '.'", dir)
	if not os.execute(ls) then
		return true
	end

	return false
end

-- get_files gets all files in the provided directory
-- @usage get_files('~/.config/doom-nvim', {'LICENSE', '*.md'}) → {string...}
-- @tparam string path The path to get all its files
-- @tparam table ignore_files files to be ignored, optional
-- @return {string...} a table with the directory files
M.get_files = function(path, ignore_files)
	local files = {}
	if type(ignore_files) == 'nil' then
		ignore_files = {}
	end
	-- Expand path home dir
	path = M.expand_home(path)

	-- Fast return for empty directory
	if is_dir_empty(path) then
		return files
	end

	-- Set ignored filetypes based on ignore_files values, e.g. '*.md' → '.md'
	local ignored_filetypes = {}
	for _, filetype in ipairs(ignore_files) do
		if string.find(filetype, '*') then
			ignored_filetypes[#ignored_filetypes + 1] =
				filetype:gsub('*', '')
		end
	end

	for file in io.popen('ls ' .. path):lines() do
		-- If the file is not ignored, then search if the filetype is ignored and
		-- if the file is not a directory, and if it isn't ignored and isn't a
		-- directory then add the file to files table
		if
			not vim.tbl_contains(ignore_files, file)
			and (not vim.tbl_contains(ignored_filetypes, M.get_file_extension(file)))
		then
			table.insert(files, file)
		end
	end

	return files
end

-- get_file_extension returns the provided file extension
-- @usage get_file_extension('init.lua') → '.lua'
-- @tparam string file The file to extract its extension
-- @return string
M.get_file_extension = function(file)
	return file:match('^.+(%..+)$')
end

-- readlink is a wrapper for libuv's fs_readlink function
-- @usage readlink('/path/to/symlink')
-- @tparam string path The symlink path
-- @tparam boolean debug If the function should print traceback at errors
-- @return string or nil
M.readlink = function(path, debug)
	local symlink, err = vim.loop.fs_readlink(path)

    if debug and err then
        log.error(
            'Failed to read ' .. path .. ' symlink'
            .. '\nError traceback:'
            .. err
        )
    end

    return symlink
end

-- unlink is a wrapper for libuv's fs_unlink function
-- @usage unlink('/path/to/symlink')
-- @tparam string path The symlink path
M.unlink = function(path)
	vim.loop.fs_unlink(path, function(err, success)
		if err then
			log.error(
				'Failed to remove symlink from '
					.. path
					.. '\nError traceback: '
					.. err
			)
		end

		return success
	end)
end

-- symlink is a wrapper for libuv's fs_symlink function
-- @usage symlink('/path/to/original/file', '/path/to/symlink')
-- @tparam string path The path of the file to symlink
-- @tparam string new_path The symlink path
-- @tparam boolean remove_old_symlink Remove the previous symlink if there's one
-- @tparam table flags The flags to be used in the symlink, e.g. {dir = true} (optional)
M.symlink = function(path, new_path, remove_old_symlink, flags)
	if remove_old_symlink then
		if M.file_exists(new_path) then
			local prev_link = M.readlink(new_path, false)

			if prev_link then
				M.unlink(new_path)
			end
		end
	end

	if M.file_exists(path) then
		vim.loop.fs_symlink(path, new_path, flags, function(err, success)
			if err then
				log.error(
					'Failed to create symlink from '
						.. path
						.. ' to '
						.. new_path
						.. '\nError traceback: '
						.. err
				)
			end

			return success
		end)
	end
end

---- Table Utilities ----------------------------------------------------------
-------------------------------------------------------------------------------

-- head returns the first element in the provided table, just because I'm lazy
-- @usage head({1,2,3}) → 1
-- @tparam table tbl The table to extract its first element
-- @return first table element or nil
M.head = function(tbl)
	if vim.tbl_isempty(tbl) then
		return nil
	end

	return tbl[1]
end

return M
