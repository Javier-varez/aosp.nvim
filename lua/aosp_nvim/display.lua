
local vim = vim

local Display = { }

function Display:new()
    local object = {}
    self.__index = self
    object.__buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(object.__buffer, 'modifiable', false)
    vim.api.nvim_buf_set_name(object.__buffer, 'AOSP Console')
    return setmetatable(object, self)
end


function Display:show()
    if self.__split ~= nil and vim.api.nvim_win_is_valid(self.__split) then
        return
    end

    local current_window_height = vim.api.nvim_win_get_height(0)
    local new_window_size = current_window_height / 4

    vim.cmd('belowright '..tostring(new_window_size)..'new')
    self.__split = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(self.__split, self.__buffer)
end

function Display:append(text)
    vim.api.nvim_buf_set_option(self.__buffer, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.__buffer, -1, -1, false, { text })
    if self.__split ~= nil then
        local length = vim.api.nvim_buf_line_count(self.__buffer)
        vim.api.nvim_win_set_cursor(self.__split, { length, 0 })
    end
    vim.api.nvim_buf_set_option(self.__buffer, 'modifiable', false)
end

function Display:toggle()
    if self.__split == nil then
        self:show()
    elseif not vim.api.nvim_win_is_valid(self.__split) then
        self.__split = nil
        self:show()
    else
        self:hide()
    end
end

function Display:hide()
    if self.__split == nil then return end

    if vim.api.nvim_win_is_valid(self.__split) then
        vim.api.nvim_win_hide(self.__split)
    end
    self.__split = nil
end

function Display:clear()
    vim.api.nvim_buf_set_option(self.__buffer, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.__buffer, 0, -1, false, { })
    vim.api.nvim_buf_set_option(self.__buffer, 'modifiable', false)
end

return Display
