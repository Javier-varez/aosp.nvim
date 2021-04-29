
local vim = vim

local M = {}

M._append_text_output = function(_, text)
    require'aosp_nvim'._append_text_to_display(text)
end

M._append_command_result = function(_, result)
    local text
    if result == 0 then
        text = 'Command executed successfully'
    else
        text = 'Command failed'
    end
    require'aosp_nvim'._append_text_to_display(text)
end

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
        on_stdout = M._append_text_output,
        on_stderr = M._append_text_output,
        on_exit = M._append_command_result,
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
        on_stdout = M._append_text_output,
        on_stderr = M._append_text_output,
        on_exit = M._append_command_result,
    })
    local adb_remount = Job:new({
        command = 'adb',
        args = { 'remount' },
        on_stdout = M._append_text_output,
        on_stderr = M._append_text_output,
        on_exit = M._append_command_result,
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
        on_stdout = M._append_text_output,
        on_stderr = M._append_text_output,
        on_exit = M._append_command_result,
    })
    adb_root:and_then_on_success(adb_remount)
    adb_remount:and_then_on_success(adb_push)
    return adb_root
end

return M
