# aosp.nvim

Plugin with support for building AOSP targets easily from Neovim. Supports building an pushing targets to a connected device.

# Getting Started

Get this pluggin with you plugin manager of choice. Beware, you will need [NeoVim nightly (V0.5)](https://github.com/neovim/neovim/releases/tag/nightly) and [Telescope](https://github.com/nvim-telescope/telescope.nvim) (along with its dependencies). If you want to show colors in the `aosp_console`, then make sure to add as well the `norcalli/nvim-terminal.lua` plugin.

Using [vim-plug](https://github.com/junegunn/vim-plug):

```
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'norcalli/nvim-terminal.lua'
Plug 'javier-varez/aosp.nvim'
```

Using [packer](https://github.com/wbthomason/packer.nvim):

```
use 'nvim-lua/popup.nvim'
use 'nvim-lua/plenary.nvim'
use 'nvim-telescope/telescope.nvim'
use 'norcalli/nvim-terminal.lua'
use 'javier-varez/aosp.nvim'
```

## Usage

You can set remaps to build a target, build and push and toggle the aosp console:

```
vim.api.nvim_set_keymap('n', '<leader>ab', '<Cmd>lua require("aosp_nvim").build_target()<CR>', {
    noremap = true,
    silent=true
})
vim.api.nvim_set_keymap('n', '<leader>ap', '<Cmd>lua require("aosp_nvim").build_and_push()<CR>', {
    noremap = true,
    silent=true
})
vim.api.nvim_set_keymap('n', '<leader>at', '<Cmd>lua require("aosp_nvim").toggle_display()<CR>', {
    noremap = true,
    silent=true
})
```

