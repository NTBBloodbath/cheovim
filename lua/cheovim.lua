local cheovim = {}

require('cheovim.loader').get_profiles(vim.fn.stdpath("config") .. "/profiles.lua")

return cheovim
