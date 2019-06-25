-- abstract/gobject.lua

local utils = require 'utils.utils'

local GObject = utils.make_class()

function GObject:_init(...)
  self._x_offset = 0 -- Extra draw + update x offset
  self._y_offset = 0 -- Extra draw + update y offset
end

local gcol = love.graphics.getColor
local gsha = love.graphics.getShader
local gcan = love.graphics.getCanvas

local scol = love.graphics.setColor
local ssha = love.graphics.setShader
local scan = love.graphics.setCanvas

--- Calls _draw() on subclasses
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

--- Calls _update() on subclasses
function GObject:update(dt, x, y)
  x = (x or 0) + self._x_offset
  y = (y or 0) + self._y_offset
  self:_update(dt, x, y)
end

function GObject:_update(dt, x, y)
  -- Default does nothing
end

--- Calls _resize() on subclasses
function GObject:resize()
  self:_resize()
end  
  
function GObject:_resize()
  -- Default does nothing
end

--- Calls _dimensions() on subclasses
function GObject:dimensions()
  return self:_dimensions()
end

--- Default tries to find dimensions
function GObject:_dimensions()
  return self.w or self.width or 0, self.h or self.height or 0
end

--- Calls _position() on subclasses
function GObject:position()
  return self:_position()
end

--- Default tries to find position
function GObject:_position()
  return self.x or 0, self.y or 0
end

function GObject:change_offset(x, y)
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