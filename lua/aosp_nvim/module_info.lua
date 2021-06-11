
local M = {
    __module_info = nil
}

-- This is a class that represents an AOSP module and provides utility methods
AospModule = {}

AospModule.is_native_test = function(module)
    for _, v in ipairs(module.class) do
        if v == 'NATIVE_TESTS' then
            return true
        end
    end
    return false
end

AospModule.is_host_module = function(module)
    for _, installed_path in ipairs(module.installed) do
        if installed_path:find('/host/') then
            return true
        end
    end
    return false
end

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
            return
        end

        M.__module_info = with(open(out_dir..'/module-info.json'), function(reader)
            local data = reader:read("*all")
            local module_info_dict = vim.fn.json_decode(data)

            local module_info = {}
            for _, v in pairs(module_info_dict) do
                setmetatable(v, {__index = AospModule})
                table.insert(module_info, v)
            end
            return module_info
        end)
    end

    return M.__module_info
end

M.rebuild = function()
    local out_dir = require'aosp_nvim.environment'.relative_out()
    local build = require'aosp_nvim.build'.build

    local build_job = build(out_dir..'/module-info.json', function()
        -- Now reload module info
        M.reload()
    end)
    return build_job
end

M.reload = function()
    M.__module_info = nil
    M.get()
end

return M
