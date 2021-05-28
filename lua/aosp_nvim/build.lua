
local M = {}

M.schedule_job = function(opts)
    local job = require('plenary.job')
    local color = require'aosp_nvim.color'
    local environment = require'aosp_nvim.environment'

    local command = 'true'
    if opts.command ~= nil then
        command = opts.command
    end

    local args = ''
    if opts.args ~= nil then
        args = opts.args
    end

    local cwd = environment.get().tree_top
    if opts.cwd ~= nil then
        cwd = opts.cwd
    end

    local env = opts.env

    return job:new({
        command = command,
        args = args,
        cwd = cwd,
        on_start = vim.schedule_wrap(function()
            local append = require'aosp_nvim'._append_text_to_display

            local job_text = command
            for _, v in ipairs(args) do
                job_text = job_text..' '..v
            end
            append(color.bright(color.green('Running '..job_text)))
        end),
        env = env,
        on_stdout = vim.schedule_wrap(function(_, text)
            require'aosp_nvim'._append_text_to_display(text)
        end),
        on_stderr = vim.schedule_wrap(function(_, text)
            require'aosp_nvim'._append_text_to_display(text)
        end),
        on_exit = vim.schedule_wrap(function(a, result)
            local text
            if result == 0 then
                text = color.bright(color.green('Command executed successfully'))
            else
                text = color.bright(color.red('Command failed'))
            end
            require'aosp_nvim'._append_text_to_display(text)
            if opts.on_exit ~= nil then
                opts.on_exit(a, result)
            end
        end)
    })
end

M.build = function(module_name)
    local environment = require'aosp_nvim.environment'
    return M.schedule_job({
        command = 'bash',
        args = {
            '-c',
            '. build/envsetup.sh && '..
            'lunch '..environment.lunch_target()..' && '..
            'm -j '..module_name
        }
    })
end

M.push = function(module)
    local Path = require'plenary.path'
    local environment = require'aosp_nvim.environment'.get()
    local tree_out = environment.tree_out
    local tree_top = environment.tree_top

    local adb_root = M.schedule_job({
        command = 'adb',
        args = {'root'}
    })
    local adb_remount = M.schedule_job({
        command = 'adb', args = {'remount'}
    })

    local local_path = Path:new(tree_top..'/'..module.installed[1])
    local_path:make_relative(tree_top)
    local target_path = Path:new(tree_top..'/'..module.installed[1])
    target_path:make_relative(tree_out)

    local adb_push = M.schedule_job({
        command = 'adb',
        args = { 'push', local_path.filename, target_path.filename }
    })
    adb_root:and_then_on_success(adb_remount)
    adb_remount:and_then_on_success(adb_push)
    return adb_root
end

M.compdb = function()
    local environment = require'aosp_nvim.environment'
    local env = vim.fn.environ()
    env.SOONG_GEN_COMPDB = 1
    env.SOONG_GEN_COMPDB_DEBUG = 1
    env.SOONG_LINK_COMPDB_TO = environment.get().tree_top
    return M.schedule_job({
        command = 'bash',
        args = {
            '-c',
            '. build/envsetup.sh && '..
            'lunch '..environment.lunch_target()..' && '..
            'make nothing'
        },
        env = env,
    })
end

return M
