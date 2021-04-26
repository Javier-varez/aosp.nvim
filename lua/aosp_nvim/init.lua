
local vim = vim
local environment_table = {
    product = 'TARGET_PRODUCT',
    build_variant = 'TARGET_BUILD_VARIANT',
    tree_top = 'ANDROID_BUILD_TOP',
    tree_out = 'ANDROID_PRODUCT_OUT',
}

local M = {
    -- module variables
    __environment = nil,
    __module_info = nil
}

M._validate_environment = function()
    for k, _ in pairs(environment_table) do
        if M.environment()[k] == nil then
            return false
        end
    end
    return true
end

M._module_info = function()
    if M.__module_info == nil then
        local context_manager = require'plenary.context_manager'
        local with = context_manager.with
        local open = context_manager.open

        local out_dir = M.environment().tree_out
        local module_info_dict = with(open(out_dir..'/module-info.json'), function(reader)
            local data = reader:read("*all")
            return vim.fn.json_decode(data)
        end)

        local module_info = {}
        for k, v in pairs(module_info_dict) do
            v.module_name = k
            table.insert(module_info, v)
        end
        M.__module_info = module_info
    end

    return M.__module_info
end

M._find_module_and_do = function(module_action)
    local Picker = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local action_set = require('telescope.actions.set')
    Picker.new(nil, {
        prompt_title = 'AOSP Module',
        finder = finders.new_table {
            results = M._module_info(),
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
                module_action(action_state.get_selected_entry().value)
                actions.close(prompt_buffer)
            end)
            return true
        end
     }):find()
end

M._current_lunch_target = function()
    return M.environment().product..'-'..M.environment().build_variant
end

M.environment = function()
    if M.__environment == nil then
        M.__environment = {}
        for k, v in pairs(environment_table) do
            M.__environment[k] = vim.env[v]
        end
    end
    return M.__environment
end

M.reload_module_info = function()
    M.__module_info = nil
    M._module_info()
end

M.build_target = function()
    M._find_module_and_do(function(module)
        local job = require('plenary.job')
        local build_job = job:new({
            command = 'bash',
            args = {
                '-c',
                '. build/envsetup.sh && '..
                'lunch '..M._current_lunch_target()..' && '..
                'm -j '..module.module_name
            },
            cwd = M.environment().tree_top,
            on_stdout = vim.schedule_wrap(function(_, data)
                print(data)
            end),
            on_stderr = vim.schedule_wrap(function(_, data)
                print(data)
            end),
            on_exit = vim.schedule_wrap(function(_, return_val)
                print(return_val)
            end),
        })
        build_job:start()
    end)
end

M.reload = function()
    require'plenary.reload'.reload_module('aosp_nvim')
end

return setmetatable({}, {
    __index = function(_, k)
        -- You can uncomment the following line in order to enable reloading
        -- of the module every time a function is called.
        --M.reload()
        if not M._validate_environment() then
            return function()
                print("Please, run 'source build/envsetup.sh' and 'lunch' first.")
            end
        end
        return M[k]
    end
})
