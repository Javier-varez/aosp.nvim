
local M = {}


local search_android = function(title, action)
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local action_set = require('telescope.actions.set')
    local sorters = require('telescope.sorters')
    local tree_top = require 'aosp_nvim.environment'.get().tree_top
    local locations = require 'aosp_nvim.locations'.get()

    pickers.new(nil, {
        prompt_title = title,
        finder = finders.new_table {
            results = locations,
            entry_maker = function(entry)
                local directory = tree_top..'/'..entry.directory
                return {
                    value = directory,
                    ordinal = entry.display_name,
                    display = entry.display_name
                }
            end,
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function()
            action_set.select:replace(function(prompt_buffer)
                local actions = require'telescope.actions'
                local action_state = require'telescope.actions.state'
                local entry = action_state.get_selected_entry()
                actions.close(prompt_buffer)
                action(entry)
            end)
            return true
        end
    }):find()
end

M.find_files = function()
    search_android('AOSP find file. Select subtree.', function(entry)
        require('telescope.builtin').find_files {
            prompt_title = 'Find files under: '..entry.display,
            cwd = entry.value
        }
    end)
end

M.live_grep = function()
    search_android('AOSP file grep. Select subtree.', function(entry)
        require('telescope.builtin').live_grep {
            prompt_title = 'Live grep in: '..entry.display,
            cwd = entry.value
        }
    end)
end

return setmetatable({}, {
    __index = function(_, k)
        local environment = require'aosp_nvim.environment'
        if not environment.validate() then
            return function()
                print("Please, run 'source build/envsetup.sh' and 'lunch' first.")
            end
        end
        return M[k]
    end
})
