
local vim = vim

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

M.push = function(module)
    local Job = require'plenary.job'
    local Path = require'plenary.path'
    local environment = require'aosp_nvim.environment'.get()
    local tree_out = environment.tree_out
    local tree_top = environment.tree_top
    local adb_root = Job:new({
        command = 'adb',
        args = { 'root' },
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
    local adb_remount = Job:new({
        command = 'adb',
        args = { 'remount' },
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
    local local_path = Path:new(tree_top..'/'..module.installed[1])
    local_path:make_relative(tree_top)
    local target_path = Path:new(tree_top..'/'..module.installed[1])
    target_path:make_relative(tree_out)
    local adb_push = Job:new({
        command = 'adb',
        args = {
            'push',
            local_path.filename,
            target_path.filename,
        },
        cwd = tree_top,
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
    adb_root:and_then_on_success(adb_remount)
    adb_remount:and_then_on_success(adb_push)
    return adb_root
end

return M
