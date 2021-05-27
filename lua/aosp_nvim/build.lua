
local vim = vim

local M = {}

M._append_text_output = function(_, text)
    require'aosp_nvim'._append_text_to_display(text)
end

M._append_command_result = function(_, result)
    local color = require'aosp_nvim.color'
    local text
    if result == 0 then
        text = color.bright(color.green('Command executed successfully'))
    else
        text = color.bright(color.red('Command failed'))
    end
    require'aosp_nvim'._append_text_to_display(text)
end

M._append_job_start = function(command, args)
    local color = require'aosp_nvim.color'
    local append = require'aosp_nvim'._append_text_to_display

    local job_text = command
    for _, v in ipairs(args) do
        job_text = job_text..' '..v
    end
    append(color.bright(color.green('Running '..job_text)))
end

M._schedule_job = function(command, args)
    local job = require('plenary.job')
    local environment = require'aosp_nvim.environment'
    return job:new({
        command = command,
        args = args,
        cwd = environment.get().tree_top,
        on_start = function()
            M._append_job_start(command, args)
        end,
        on_stdout = M._append_text_output,
        on_stderr = M._append_text_output,
        on_exit = M._append_command_result,
    })
end

M.build = function(module_name)
    local environment = require'aosp_nvim.environment'
    local command = 'bash'
    local args = {
        '-c',
        '. build/envsetup.sh && '..
        'lunch '..environment.lunch_target()..' && '..
        'm -j '..module_name
    }
    return M._schedule_job(command, args)
end

M.push = function(module)
    local Job = require'plenary.job'
    local Path = require'plenary.path'
    local environment = require'aosp_nvim.environment'.get()
    local tree_out = environment.tree_out
    local tree_top = environment.tree_top

    local adb_root = M._schedule_job('adb', {'root'})
    local adb_remount = M._schedule_job('adb', {'remount'})

    local local_path = Path:new(tree_top..'/'..module.installed[1])
    local_path:make_relative(tree_top)
    local target_path = Path:new(tree_top..'/'..module.installed[1])
    target_path:make_relative(tree_out)

    local adb_push = M._schedule_job('adb', { 'push', local_path.filename, target_path.filename })
    adb_root:and_then_on_success(adb_remount)
    adb_remount:and_then_on_success(adb_push)
    return adb_root
end

return M
