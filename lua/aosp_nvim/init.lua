
local vim = vim

local M = {}

M._find_module_and_do = function(module_action)
    local Picker = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local action_set = require('telescope.actions.set')
    local module_info = require('aosp_nvim.module_info').get()
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

M.build_target = function()
    M._find_module_and_do(function(module)
        local build_job = require'aosp_nvim.build'.build(module.module_name)
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
