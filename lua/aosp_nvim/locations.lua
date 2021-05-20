
local vim = vim

local M = {
    __locations = nil
}

local common_dirs = {
    {
        display_name = 'Frameworks',
        directory = 'frameworks',
    },
    {
        display_name = 'Apps',
        directory = 'packages/apps',
    },
    {
        display_name = 'Interfaces',
        directory = 'hardware/interfaces',
    },
    {
        display_name = 'System',
        directory = 'system',
    },
    {
        display_name = 'Recovery',
        directory = 'bootable/recovery',
    },
    {
        display_name = 'External',
        directory = 'external',
    },
    {
        display_name = 'Vendor',
        directory = 'vendor',
    },
    {
        display_name = 'CTS',
        directory = 'cts',
    },
}

M.get = function()
    if M.__locations == nil then
        local context_manager = require'plenary.context_manager'
        local path = require'plenary.path'
        local environment = require'aosp_nvim.environment'.get()
        local with = context_manager.with
        local open = context_manager.open
        local tree_top = environment.tree_top

        M.__locations = common_dirs

        -- Try to load additional configuration
        local aosp_nvim_config_path = path:new(tree_top..'/.aosp_nvim.json')
        if aosp_nvim_config_path:exists() then
            with(open(tree_top..'/.aosp_nvim.json'), function(reader)
                local data = reader:read("*all")
                local custom_dirs = vim.fn.json_decode(data)

                for _, v in ipairs(custom_dirs) do
                    table.insert(M.__locations, v)
                end
            end)
        end
    end

    return M.__locations
end

M.reload = function()
    M.__locations = nil
    return M.get()
end

return M
