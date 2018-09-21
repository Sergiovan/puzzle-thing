-- game/game.lua

local utils = require 'utils.utils'
local input = require 'input.input'

local Game = utils.make_class()

function Game:_init()  
  self.states = {} -- Change to proper state later
  self.default_mouse = love.graphics.newImage "img/cursor.png"

  self.debug = false
  self.show_fps = false
end

function Game:init()
  local State = require 'game.state.state'
  local Console = require 'utils.console'
  
  self.console = Console 'top'
  self:addState(State())
end

function Game:update(dt)
  local change, new = self:state():update(dt)
  if change then
    if new then
      self:addState(new)
    else
      self:popState()
    end
  end

  if (input.keyboard_down['rctrl'] or input.keyboard_down['lctrl']) and input.keyboard_press['f3'] then
    self.debug = not self.debug
    if self.debug then
      self.console:open()
    else
      self.console:close()
    end
  end

  self.console:update(dt)

end

function Game:draw()
  self:state():draw(0, 0)
  local mx, my = input:get_mouse_position()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self:state().mouse or self.default_mouse, mx-5, my-5)

  self.console:draw()
  if self.show_fps then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, love.graphics.getHeight() - 15)
  end
end

function Game:state()
  return self.states[#self.states]
end

function Game:addState(state)
  table.insert(self.states, state)
end

function Game:popState()
  return table.remove(self.states)
end

function Game:print(...) 
  print(...)
  local num = select('#', ...)
  for i=1, num do
    self.console:log(tostring(select(i, ...)))
  end
end

function Game:failure(...)
  print(...)
  local num = select('#', ...)
  for i=1, num do
    self.console:failure(tostring(select(i, ...)))
  end
end

local game = Game()
return game