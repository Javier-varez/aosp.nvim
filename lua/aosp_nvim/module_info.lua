
local M = {
    __module_info = nil
}

M.exists = function()
    local environment = require'aosp_nvim.environment'.get()
    local module_info = io.open(environment.tree_out.."/module-info.json", "r")
    if module_info == nil then
        return false
    else
        return true
    end
end

M.get = function()
    if M.__module_info == nil then
        local context_manager = require'plenary.context_manager'
        local environment = require'aosp_nvim.environment'.get()
        local with = context_manager.with
        local open = context_manager.open
        local out_dir = environment.tree_out

        if not M.exists() then
            local rebuild = vim.fn.input('Module info not found, rebuild? [Y/n]: ')
            if rebuild == 'y' or rebuild == 'Y' or rebuild == '' then
                M.rebuild()
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

M.rebuild = function()
    local environment = require'aosp_nvim.environment'.get()
    local build = require'aosp_nvim.build'.build
    local Path = require'plenary.path'
    local module_info = Path:new(environment.tree_out..'/module-info.json')

    local build_job = build(module_info:make_relative(environment.tree_top))
    build_job:sync()
end

M.reload = function()
    M.__module_info = nil
    M.get()
end

return M