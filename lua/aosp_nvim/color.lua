
local M = {}

local colors = {
  -- reset
  reset =      0,

  -- misc
  bright     = 1,
  dim        = 2,
  underline  = 4,
  blink      = 5,
  reverse    = 7,
  hidden     = 8,

  -- foreground colors
  black     = 30,
  red       = 31,
  green     = 32,
  yellow    = 33,
  blue      = 34,
  magenta   = 35,
  cyan      = 36,
  white     = 37,

  -- background colors
  blackbg   = 40,
  redbg     = 41,
  greenbg   = 42,
  yellowbg  = 43,
  bluebg    = 44,
  magentabg = 45,
  cyanbg    = 46,
  whitebg   = 47
}

return setmetatable({}, {
    __index = function(_, key)
        return function(text)
            local escape_sequence_from_color = function(color)
                local escape_string = string.char(27)..'[%dm'
                return escape_string:format(color)
            end
            local color = colors[key]
            return escape_sequence_from_color(color)..text..escape_sequence_from_color(colors.reset)
        end
    end
})
