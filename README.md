```
      ___           ___           ___                                    ___     
     /  /\         /__/\         /__/\          ___        ___          /__/\    
    /  /:/         \  \:\        \  \:\        /__/\      /  /\        |  |::\   
   /  /:/           \__\:\        \  \:\       \  \:\    /  /:/        |  |:|:\  
  /  /:/  ___   ___ /  /::\   _____\__\:\       \  \:\  /__/::\      __|__|:|\:\ 
 /__/:/  /  /\ /__/\  /:/\:\ /__/::::::::\  ___  \__\:\ \__\/\:\__  /__/::::| \:\
 \  \:\ /  /:/ \  \:\/:/__\/ \  \:\~~\~~\/ /__/\ |  |:|    \  \:\/\ \  \:\~~\__\/
  \  \:\  /:/   \  \::/       \  \:\  ~~~  \  \:\|  |:|     \__\::/  \  \:\      
   \  \:\/:/     \  \:\        \  \:\       \  \:\__|:|     /__/:/    \  \:\     
    \  \::/       \  \:\        \  \:\       \__\::::/      \__\/      \  \:\    
     \__\/         \__\/         \__\/           ~~~~                   \__\/    
```

<div align="center">

![License](https://img.shields.io/github/license/NTBBloodbath/chnvim?style=flat-square)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
![Neovim version](https://img.shields.io/badge/Neovim-0.5-57A143?style=flat-square&logo=neovim)

Neovim profile switcher written in Lua. Inspired by chemacs.

[Introduction](#introduction) • [Installation](#installation) • [Usage](#usage)

</div>

---

## Introduction

> Chnvim is a Neovim profile switcher inspired by chemacs. It makes it easy to run multiple
> Neovim configurations side by side.
> 
> So, you can think of Chnvim as a bootloader for Neovim.

Neovim configuration is kept in a `~/.config/nvim` directory and that path is hard-coded.
If you want to try out someone else's configuration, or run different distributions like
LunarVim, Doom Nvim or SpaceVim, then you need to swap out `~/.config/nvim`.

Chnvim tries to implement this idea in a user-fiendly way, and that's why it's inspired
by Chemacs.

## Installation

> **IMPORTANT:** chnvim requires Neovim >= 0.5 to work!

Clone the Chnvim repository as `$HOME/.config/nvim`. Note that if you already have a Neovim
setup in `~/.config/nvim` you need to move it out of the way first.

```sh
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim_default
git clone https://github.com/NTBBloodbath/chnvim.git ~/.config/nvim
```

Next you will need to create a `~/.nvim_profiles.lua` file, for details see below.

```lua
Profiles = {
    default = "~/.config/nvim_default",
}
```

## Usage

Chnvim profiles are configured in `~/.nvim_profiles.lua`.

If a profile is not provided by a `~/.nvim_profile` file, then the `default`
profile is used.

### .nvim_profiles.lua

This file contains a table, with the keys being the profile names and the values
their configuration path.

```lua
Profiles = {
    default = "~/.config/nvim_default",
    ["doom-nvim"] = "~/.config/doom-nvim",
}
```

Chnvim will symlink all the Vim core directories from that directory (e.g. `autoload/`)
and load `init.vim` or `init.lua` form that directory.

> **NOTE:** `nvim_profiles.lua` can also be defined as `profiles.lua` in the `~/.config/chnvim` directory.

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
you'd like to be used.

```bash
$ echo 'doom-nvim' > ~/.nvim_profile
```

This will set the default profile to be the `doom-nvim` profile, instead of `default`.
You can change the default by simply changing the contents of this file:

```bash
$ sed "s/doom-nvim/LunarVim/" ~/.nvim_profile
```

If this file doesn't exist, then `default` will be used, as before.

> **NOTE:** `nvim_profile` can also be defined as `profile` in the `~/.config/chnvim` directory.

## Todo

- [ ] Check if the current profile was changed.
- [ ] Stop deleting and creating again the symlinks if the profile haven't changed.
- [ ] Add a command to use inside Neovim to switch profiles (not live reload, or maybe yes?)

## License

Chnvim is distributed under the [MIT](./LICENSE) License
