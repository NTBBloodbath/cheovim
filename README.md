```
      ___           ___           ___           ___                                    ___     
     /  /\         /__/\         /  /\         /  /\          ___        ___          /__/\    
    /  /:/         \  \:\       /  /:/_       /  /::\        /__/\      /  /\        |  |::\   
   /  /:/           \__\:\     /  /:/ /\     /  /:/\:\       \  \:\    /  /:/        |  |:|:\  
  /  /:/  ___   ___ /  /::\   /  /:/ /:/_   /  /:/  \:\       \  \:\  /__/::\      __|__|:|\:\ 
 /__/:/  /  /\ /__/\  /:/\:\ /__/:/ /:/ /\ /__/:/ \__\:\  ___  \__\:\ \__\/\:\__  /__/::::| \:\
 \  \:\ /  /:/ \  \:\/:/__\/ \  \:\/:/ /:/ \  \:\ /  /:/ /__/\ |  |:|    \  \:\/\ \  \:\~~\__\/
  \  \:\  /:/   \  \::/       \  \::/ /:/   \  \:\  /:/  \  \:\|  |:|     \__\::/  \  \:\      
   \  \:\/:/     \  \:\        \  \:\/:/     \  \:\/:/    \  \:\__|:|     /__/:/    \  \:\     
    \  \::/       \  \:\        \  \::/       \  \::/      \__\::::/      \__\/      \  \:\    
     \__\/         \__\/         \__\/         \__\/           ~~~~                   \__\/    
```

<div align="center">

![License](https://img.shields.io/github/license/NTBBloodbath/cheovim?style=flat-square)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
![Neovim version](https://img.shields.io/badge/Neovim-0.5-57A143?style=flat-square&logo=neovim)

Neovim configuration switcher written in Lua. Inspired by chemacs.

[Introduction](#introduction) • [Installation](#installation) • [Usage](#usage)

</div>

---

## Introduction

> Cheovim is a Neovim configuration switcher inspired by chemacs. It makes it easy to
> run multiple Neovim configurations without having headaches.
> 
> So, you can think of Cheovim as a bootloader for Neovim.

Neovim configuration is kept in a `~/.config/nvim` directory and that path is hard-coded.
If you want to try out someone else's configuration, or run different distributions like
LunarVim, Doom Nvim or SpaceVim, then you need to swap out `~/.config/nvim` and it can be
a bit tedious.

Cheovim is made to make your life easier and allow you to change Neovim configurations by
simply specifying in a file which configurations you want to use!

## Installation

> **IMPORTANT:** cheovim requires Neovim >= 0.5 to work!

Clone the Cheovim repository as `$HOME/.config/nvim`. Note that if you already have a Neovim
setup in `~/.config/nvim` you need to move it out of the way first to start using cheovim.

```sh
# If a neovim config already exists then rename it
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim_default

# Clone cheovim repository as the Neovim config
git clone https://github.com/NTBBloodbath/cheovim.git ~/.config/nvim
```

Next you will need to create a `~/.nvim_profiles.lua` file like this.

```lua
Profiles = {
    default = "~/.config/nvim_default",
}
```

> **NOTE:** for more details see [below](#nvim_profileslua).

## Usage

Cheovim profiles are configured in `~/.nvim_profiles.lua`.

If a profile is not provided by a `~/.nvim_profile` file, then the `default`
profile is used.

> **IMPORTANT:** Every time you change the configuration, you must run `PackerSync`
> _if you use packer_ to update the plugins and move them since not all setups or
> distributions have the same configuration in their plugins or the same plugins.

### .nvim_profiles.lua

This file contains a Lua table, with the keys being the profile names and the values
their configuration path.

```lua
Profiles = {
    default = "~/.config/nvim_default",
    ["doom-nvim"] = "~/.config/doom-nvim",
}
```

Cheovim will symlink all the Vim core directories from that directories (e.g. `autoload/`)
and source the `init.vim` or `init.lua`.

> **NOTE:** `nvim_profiles.lua` can also be defined as `profiles.lua` in the `~/.config/cheovim` directory.

### Changing the default profile

If your `~/.nvim_profiles.lua` file contains the following:

```lua
Profiles = {
    default = "~/.config/nvim_default",
    ["doom-nvim"] = "~/.config/doom-nvim",
    LunarVim = "~/.config/LunarVim",
}
```

You can create a file called `~/.nvim_profile`, containing the name of the profile
you'd like to be used. For example:

```bash
$ echo 'doom-nvim' > ~/.nvim_profile
```

This will set the default profile to be the `doom-nvim` profile, instead of `default`.
You can change the default by simply changing the contents of this file:

```bash
$ sed "s/doom-nvim/LunarVim/" ~/.nvim_profile
```

If this file doesn't exist, then `default` profile will be used, as before.

> **NOTE:** `nvim_profile` can also be defined as `profile` in the `~/.config/cheovim` directory.

## Todo

- [x] Check if the current profile was changed.
- [x] Stop deleting and creating again the symlinks if the profile haven't changed.
- [ ] Add a command to use inside Neovim to switch profiles (not live reload, or maybe yes?).
- [ ] Refact the configurations loading behavior by using `packadd`.
- [ ] Implement async and lazy-loading, why not?

## License

Cheovim is distributed under the [MIT](./LICENSE) License
