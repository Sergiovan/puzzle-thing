-- abstract/gobject.lua

local utils = require 'utils.utils'

local GObject = utils.make_class()

function GObject:_init(...)
  self._x_offset = 0
  self._y_offset = 0
end

local gcol = love.graphics.getColor
local gsha = love.graphics.getShader
local gcan = love.graphics.getCanvas

local scol = love.graphics.setColor
local ssha = love.graphics.setShader
local scan = love.graphics.setCanvas

function GObject:draw(x, y)
  x = (x or 0) + self._x_offset
  y = (y or 0) + self._y_offset
  local r, g, b, a = gcol()
  local sha = gsha()
  local can = gcan()
  self:_draw(x, y)
  scan(can)
  ssha(sha)
  scol(r, g, b, a)
end

function GObject:_draw(x, y)
  -- Default does nothing
end

function GObject:update(dt, x, y)
  x = (x or 0) + self._x_offset
  y = (y or 0) + self._y_offset
  self:_update(dt, x, y)
end

function GObject:_update(dt, x, y)
  -- Default does nothing
end

function GObject:resize()
  self:_resize()
end  
  
function GObject:_resize()
  -- Default does nothing
end

function GObject:move(x, y)
  self._x_offset = self._x_offset + x
  self._y_offset = self._y_offset + y
end

function GObject:set_offset(x, y)
  self._x_offset = x
  self._y_offset = y
end

function GObject:clear_offset()
  self._x_offset = 0
  self._y_offset = 0
end

local function make_gobject(...)
  local res = utils.make_class(GObject, ...)
  local mt = getmetatable(res)
  mt.__call = function(c, ...)
    local instance = setmetatable({}, c)
    -- run gobject init
    GObject._init(instance, ...)
    -- run the init method if it's there
    local init = instance._init
    if init then init(instance, ...) end
    return instance
  end
  return res
end

return make_gobject