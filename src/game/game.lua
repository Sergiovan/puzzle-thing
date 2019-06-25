-- game/game.lua

local utils = require 'utils.utils'
local input = require 'input.input'

local Game = utils.make_class()

--- Does not start the game, actually
function Game:_init()  
  self.states = {} -- Change to proper state later
  self.default_mouse = love.graphics.newImage "img/cursor.png"

  self.debug = false -- Debug mode (console)
  self.show_fps = false -- FPS shown or not
  self.mouse = true -- If playing with mouse or with keyboard
end

--- Starts the game
function Game:init()
  local LevelState = require 'game.state.level_state'
  local TestState = require 'game.state.test_state'
  local Console = require 'utils.console'
  
  self.console = Console 'top'
  -- self:addState(LevelState())
  self:addState(TestState())
end

--- Updates the game state. dt is the seconds since last update
function Game:update(dt)
  if input.mouse_moved then
    self.mouse = true
  elseif input.key_pressed then
    self.mouse = false
  end
  
  if not self.debug then
    local change, new = self:state():update(dt) -- Update state
    if change then
      if new then
        self:addState(new)
      else
        self:popState()
      end
    end
  end
  
  if self.debug or self.console.visible then
    self.console:update(dt) -- Only update console
  end

  -- Show console on Ctrl + F3
  if (input.keyboard_down['rctrl'] or input.keyboard_down['lctrl']) and input.keyboard_press['f3'] then
    self.debug = not self.debug
    if self.debug then
      self.console:open()
    else
      self.console:close()
    end
  end

end

function Game:draw()
  local gui = require 'gui.gui'
  self:state():draw()

  self.console:draw()
  if self.show_fps then -- Barebones fps
    love.graphics.setFont(gui.fonts.console)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS()), 0, love.graphics.getHeight() - 15)
  end
  
  if self.mouse then -- Draw mouse if visible
    local mx, my = input:get_mouse_position()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self:state().mouse or self.default_mouse, mx-5, my-5)
  end
end

--- Returns current state
function Game:state()
  return self.states[#self.states]
end

--- Sets the top state to a new one
function Game:addState(state)
  self.states[#self.states + 1] = state
end

--- Removes the current state and returns it
function Game:popState()
  return table.remove(self.states)
end

--- Print to console and to output
function Game:print(...) 
  print(...)
  local num = select('#', ...)
  for i=1, num do
    self.console:log(tostring(select(i, ...)))
  end
end

--- Print to console and to output, but failure
function Game:failure(...)
  print(...)
  local num = select('#', ...)
  for i=1, num do
    self.console:failure(tostring(select(i, ...)))
  end
end

local game = Game()
return game