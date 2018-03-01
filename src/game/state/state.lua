-- game/state.lua
local utils = require 'utils.utils'
local Board = require 'game.board.board'

State = utils.make_class()

function State:_init()
  self.board = Board(50, 50, 10, 10)
end

function State:draw()
  self.board:draw()
end

function State:update(dt)
  self.board:update(dt)
end

return State
