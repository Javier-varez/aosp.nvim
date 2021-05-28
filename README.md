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

You can set remaps to build a target, build and push and toggle the aosp console.

`build_target` can be use to fuzzy search all targets described by the `module-info.json` and built the selected target.
```lua
vim.api.nvim_set_keymap('n', '<leader>ab', '<Cmd>lua require("aosp_nvim").build_target()<CR>', {
    noremap = true,
    silent=true
})
```

`build_and_push` also fuzzy searches the targets defined in `module-info.json`, but additionally it runs `adb root`, `adb remount` and `adb push` to install the target in the device:

```lua
vim.api.nvim_set_keymap('n', '<leader>ap', '<Cmd>lua require("aosp_nvim").build_and_push()<CR>', {
    noremap = true,
    silent=true
})
```

To show/hide the `AOSP console` you can use the following shortcut:

```lua
vim.api.nvim_set_keymap('n', '<leader>at', '<Cmd>lua require("aosp_nvim").toggle_display()<CR>', {
    noremap = true,
    silent=true
})
```

If you want to fuzzy search a particular subtree of the aosp project, you can also use any of the following extensions of telescope:

```lua
vim.api.nvim_set_keymap('n', '<leader>ag', '<Cmd>lua require("aosp_nvim.telescope").live_grep()<CR>', {
    noremap = true,
    silent=true
})

vim.api.nvim_set_keymap('n', '<leader>af', '<Cmd>lua require("aosp_nvim.telescope").find_files()<CR>', {
    noremap = true,
    silent=true
})
```

This will show a picker with the available subtrees. More subtrees can be defined specifically for your project by creating a file named `.aosp_nvim.json` in the root of the AOSP tree with the following contents:

```json
[
    {
        "display_name": "Someother subtree name",
        "directory": "path/to/the/desired/subtree"
    }
]
```

To generate the compilation database and symlink it to the top directory you can add the following mapping:

```lua
vim.api.nvim_set_keymap('n', '<leader>ac', '<Cmd>lua require("aosp_nvim").compdb()<CR>', {
    noremap = true,
    silent=true
})
```
