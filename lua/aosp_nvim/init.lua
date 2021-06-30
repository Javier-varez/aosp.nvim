
local vim = vim

local M = {
    __display = require'aosp_nvim.display':new()
}

local default_options = {
    native_tests = false,
    host_module = false,
    include_fakes = false,
}

local parse_options = function(opts)
    local module_info = require('aosp_nvim.module_info')
    local fulfills_requirements = function(module, opts)
        if opts == nil then
            opts = default_options
        end

        if opts.native_tests then
            if not module:is_native_test() then
                return false
            end
        end

        if opts.host_module then
            if not module:is_host_module () then
                return false
            end
        end

        if not opts.include_fakes then
            if module:is_fake () then
                return false
            end
        end
        return true
    end

    local out = {}
    for _, module in ipairs(module_info.get()) do
        if fulfills_requirements(module, opts) then
            table.insert(out, module)
        end
    end
    return out
end

M._find_module_and_do = function(module_action, opts)
    local Picker = require('telescope.pickers')
    local finders = require('telescope.finders')
    local sorters = require('telescope.sorters')
    local action_set = require('telescope.actions.set')
    local module_info = require('aosp_nvim.module_info')
    if not module_info.exists() then
        local rebuild = vim.fn.input('Module info not found, rebuild? [Y/n]: ')
        if rebuild == 'y' or rebuild == 'Y' or rebuild == '' then
            local build_job = module_info.rebuild()
            M.__display:clear()
            M.__display:show()
            build_job:start()
            return
        else
            return
        end
    end

    Picker.new(nil, {
        prompt_title = 'AOSP Module',
        finder = finders.new_table {
            results = parse_options(opts),
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
                actions.close(prompt_buffer)
                M.__display:clear()
                M.__display:show()
                module_action(action_state.get_selected_entry().value)
            end)
            return true
        end
     }):find()
end

M._append_text_to_display = vim.schedule_wrap(function(data)
    M.__display:append(tostring(data))
end)

M.toggle_display = function()
    M.__display:toggle()
end

M.rebuild_module_info = function()
    local module_info = require('aosp_nvim.module_info')
    local build_job = module_info.rebuild()
    M.__display:clear()
    M.__display:show()
    build_job:start()
end

M.build_target = function(opts)
    M._find_module_and_do(function(module)
        local build_job = require'aosp_nvim.build'.build(module.module_name)
        build_job:start()
    end, opts)
end

M.build_and_push = function(opts)
    M._find_module_and_do(function(module)
        local build_job = require'aosp_nvim.build'.build(module.module_name)
        local push_job = require'aosp_nvim.build'.push(module)
        build_job:and_then_on_success(push_job)
        build_job:start()
    end, opts)
end

M.run_test = function(opts)
    if opts == nil then
        opts = {}
    end
    opts.native_tests = true

    M._find_module_and_do(function(module)
        local atest_job = require'aosp_nvim.build'.atest(module.module_name, opts)
        atest_job:start()
    end, opts)
end

M.compdb = function()
    local compdb_job = require'aosp_nvim.build'.compdb()
    M.__display:clear()
    M.__display:show()
    compdb_job:start()
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
