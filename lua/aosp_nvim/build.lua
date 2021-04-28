
local M = {}

M.build = function(module_name)
    local job = require('plenary.job')
    local environment = require'aosp_nvim.environment'
    local build_job = job:new({
        command = 'bash',
        args = {
            '-c',
            '. build/envsetup.sh && '..
            'lunch '..environment.lunch_target()..' && '..
            'm -j '..module_name
        },
        cwd = environment.get().tree_top,
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

return M
