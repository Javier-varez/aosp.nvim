
local vim = vim

local M = {
    __environment = nil,
    __environment_table = {
        product = 'TARGET_PRODUCT',
        build_variant = 'TARGET_BUILD_VARIANT',
        tree_top = 'ANDROID_BUILD_TOP',
        tree_out = 'ANDROID_PRODUCT_OUT',
    },
}

M.validate = function()
    for k, _ in pairs(M.__environment_table) do
        if M.get()[k] == nil then
            return false
        end
    end
    return true
end

M.get = function()
    if M.__environment == nil then
        M.__environment = {}
        for k, v in pairs(M.__environment_table) do
            M.__environment[k] = vim.env[v]
        end
    end
    return M.__environment
end

M.lunch_target = function()
    return M.get().product..'-'..M.get().build_variant
end

M.relative_out = function()
    local Path = require'plenary.path'
    local module_info = Path:new(M.get().tree_out)
    return module_info:make_relative(M.get().tree_top)
end

return M
