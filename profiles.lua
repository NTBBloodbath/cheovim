-- Profiles for cheovim

local profiles = {

	my_config = { "/home/vhyrro/.config/nvim.lua", {
			url = false,
			plugins = "packer",
			preconfigure = "packer:opt",
		}
	},

	doom_nvim = { "/home/vhyrro/dev/doom-nvim", {
			url = false,
			plugins = "packer",
			preconfigure = "packer:opt:fix/premature-display-opening",
		}
	},

}

return "my_config", profiles
