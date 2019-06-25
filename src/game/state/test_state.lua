-- game/level_state.lua
local utils = require 'utils.utils'
local Board = require 'game.board.board'
local gui   = require 'gui.gui'
local input = require 'input.input'
local game  = require 'game.game'

local TestState = utils.make_class()

--- Initializes level number `level` from file `file`
function TestState:_init() 
  local zone = gui.Zone(100, 100, 400, 400, -1, 200)
  local label = gui.Label(100, 100, 'Test1')
  zone:add_elem(label)
  zone:add_elem(gui.Label(500, 100, 'Test2'))
  zone:add_elem(gui.Label(100, 500, 'Test3'))
  self.gui = {zone} -- All gui elements
end

--- Render state
function TestState:draw()
  for k, v in pairs(self.gui) do
    v:draw()
  end
  love.graphics.setColor({1, 1, 1})
  love.graphics.rectangle('line', 100, 100, 400, 400)
end

--- Update state
function TestState:update(dt)
  for k, v in ipairs(self.gui) do
    v:update(dt) -- GUI
  end
end

return TestState
