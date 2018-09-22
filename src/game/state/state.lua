-- game/state.lua
local utils = require 'utils.utils'
local Board = require 'game.board.board'
local gui   = require 'gui.gui'
local input = require 'input.input'
local game  = require 'game.game'

local State = utils.make_class()

function State:_init(file, level)
  file = file or 'res/levels.txt'
  level = level or 1
  self.board = Board(50, 50)
  local err, msg = self.board:load(file, level)
  
  if err then
    if type(err) == 'string' then 
      game:failure(msg)
    elseif type(err) == 'table' then
      for k, v in ipairs(msg) do
        game:failure('Several errors: ')
        game:failure(k .. ': ' .. v)
      end
    else
      game:failure(tostring(msg))
    end
    self.board:load()
  end
  
  self.gui = {}
  self.mouse = nil
end

function State:draw(x, y)
  x = x or 0
  y = y or 0
  self.board:draw(x, y)
  for k, v in pairs(self.gui) do
    v:draw(x, y)
  end
end

function State:update(dt)
  if input.keyboard_press['p'] then
    return true, require('game.state.pause_state')()
  end
  self.board:update(dt)
  if self.board.updated then 
    local board_state = self.board:getBoardState()
    if board_state == Board.board_states.victory then
      self.gui[#self.gui + 1] = gui.Label(10, 10, "Winner winner dine whatever you want!")
    elseif board_state == Board.board_states.defeat then 
      self.gui[#self.gui + 1] = gui.Label(10, 10, "Oops...")
    end
  end
  for k, v in ipairs(self.gui) do
    v:update(dt)
  end
end

return State
