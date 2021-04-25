
local vim = vim

local get_aosp_out_dir = function()
    local dir = vim.env['ANDROID_PRODUCT_OUT']
    if dir == nil then
        print('Please source the aosp build/envsetup.sh and select a target with lunch first')
    end
    return dir
end

local to_buffer = function(data)
    local buffer = vim.api.nvim_create_buf(false, true)

    local lines = {}
    for s in vim.inspect(data):gmatch("[^\r\n]+") do
        table.insert(lines, s)
    end

    vim.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)
    vim.cmd('vnew')
    local current_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(current_window, buffer)
end

local find_module_info = function()
    local context_manager = require'plenary.context_manager'
    local with = context_manager.with
    local open = context_manager.open

    local out_dir = get_aosp_out_dir()
    if out_dir == nil then
        return
    end

    print('Loading module info')
    local module_info_dict = with(open(out_dir..'/module-info.json'), function(reader)
        local data = reader:read("*all")
        return vim.fn.json_decode(data)
    end)

    local module_info = {}
    for k, v in pairs(module_info_dict) do
        v.module_name = k
        table.insert(module_info, v)
    end

    return module_info
end

local find_module_and_do = function(database, module_action)
    local Picker = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local action_set = require('telescope.actions.set')
    Picker.new(nil, {
        prompt_title = 'AOSP Module',
        finder = finders.new_table {
            results = database,
            entry_maker = function(entry)
                return {
                    value = entry,
                    ordinal = entry.module_name,
                    display = entry.module_name,
                }
            end,
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function()
            action_set.select:replace(function(prompt_buffer)
                local actions = require'telescope.actions'
                local action_state = require'telescope.actions.state'
                module_action(action_state.get_selected_entry())
                actions.close(prompt_buffer)
            end)
            return true
        end
     }):find()
end

local module_info = nil

local M = {}

M.reload_module_info = function()
    module_info = find_module_info()
end

M.build_target = function()
    if module_info == nil then
        module_info = find_module_info()
    end

    find_module_and_do(module_info, function(module)
        print('The choice is: '..vim.inspect(module))
    end)
    --to_buffer(module_info)
    --local job = require('plenary.job')
    --local buffer = vim.api.nvim_create_buf(true, false)

    --job:new({
    --    command = 'make',
    --    on_stdout = vim.schedule_wrap(function(_, data)
    --        vim.api.nvim_buf_set_lines(buffer, -1, -1, true, { data })
    --    end),
    --    on_stderr = vim.schedule_wrap(function(_, data)
    --        vim.api.nvim_buf_set_lines(buffer, -1, -1, true, { data })
    --    end),
    --    on_exit = vim.schedule_wrap(function(j, return_val)
    --        print(return_val)
    --    end),
    --}):start()
end

M.reload = function()
    require'plenary.reload'.reload_module('aosp_nvim')
end

return setmetatable({}, {
    __index = function(_, k)
        --require'plenary.reload'.reload_module('aosp_nvim')
        return M[k]
    end
})
