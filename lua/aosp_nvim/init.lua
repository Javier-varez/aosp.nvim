
local vim = vim

local M = {
    __module_info = nil
}

M._module_info_exists = function()
    local environment = require'aosp_nvim.environment'.get()
    local module_info= io.open(environment.tree_out.."/module-info.json", "r")
    if module_info == nil then
        return false
    else
        return true
    end
end

M._module_info = function()
    if M.__module_info == nil then
        local context_manager = require'plenary.context_manager'
        local environment = require'aosp_nvim.environment'.get()
        local with = context_manager.with
        local open = context_manager.open
        local out_dir = environment.tree_out

        if not M._module_info_exists() then
            local rebuild = vim.fn.input('Module info not found, rebuild? [Y/n]: ')
            if rebuild == 'y' or rebuild == 'Y' or rebuild == '' then
                M._rebuild_module_info()
            else
                return
            end
        end

        M.__module_info = with(open(out_dir..'/module-info.json'), function(reader)
            local data = reader:read("*all")
            local module_info_dict = vim.fn.json_decode(data)

            local module_info = {}
            for k, v in pairs(module_info_dict) do
                v.module_name = k
                table.insert(module_info, v)
            end
            return module_info
        end)
    end

    return M.__module_info
end

M._rebuild_module_info = function()
    local environment = require'aosp_nvim.environment'.get()
    local Path = require'plenary.path'
    local module_info = Path:new(environment.tree_out..'/module-info.json')

    local build_job = M._build_command(module_info:make_relative(environment.tree_top))
    build_job:sync()
end

M._find_module_and_do = function(module_action)
    local Picker = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local action_set = require('telescope.actions.set')
    local module_info = M._module_info()
    if module_info == nil then
        return
    end

    Picker.new(nil, {
        prompt_title = 'AOSP Module',
        finder = finders.new_table {
            results = module_info,
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
    local environment = require'aosp_nvim.environment'.get()
    return environment.product..'-'..environment.build_variant
end

M._build_command = function(module_name)
    local job = require('plenary.job')
    local environment = require'aosp_nvim.environment'.get()
    local build_job = job:new({
        command = 'bash',
        args = {
            '-c',
            '. build/envsetup.sh && '..
            'lunch '..M._current_lunch_target()..' && '..
            'm -j '..module_name
        },
        cwd = environment.tree_top,
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
    return build_job
end

M.reload_module_info = function()
    M.__module_info = nil
    M._module_info()
end

M.build_target = function()
    M._find_module_and_do(function(module)
        local build_job = M._build_command(module.module_name)
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
        -- M.reload()
        local environment = require'aosp_nvim.environment'
        if not environment.validate() then
            return function()
                print("Please, run 'source build/envsetup.sh' and 'lunch' first.")
            end
        end
        return M[k]
    end
})
