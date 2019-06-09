-- game/level_state.lua
local utils = require 'utils.utils'
local Board = require 'game.board.board'
local gui   = require 'gui.gui'
local input = require 'input.input'
local game  = require 'game.game'

local LevelState = utils.make_class()

--- Initializes level number `level` from file `file`
function LevelState:_init(file, level)
  file = file or 'res/levels.txt'
  level = level or 1
  
  self.text = love.graphics.newText(gui.fonts.game_small) -- Top of the screen has cool-beans text
  self.text_height = gui.fonts.game_small:getHeight() * 2 + 15 -- Space needed for text canvas
  
  self.board = Board(50, 50 + self.text_height) -- Actual board, account for UI height
  local err, msg = self.board:load(file, level) -- Load from file
  
  if err then -- Could not load, yo
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
    self.board:load() -- Load default level
  end
  
  self.gui = {} -- All gui elements
  self.ui_background = {0, 0, 0.25}
  self.timer = -3 -- Seconds elapsed in current level
  self.mouse = nil -- Nothing?
  self.done = false -- If the level has finished
end

--- Render state
function LevelState:draw()
  local h = self.text_height
  
  self.board:draw() -- Draw the board first
  
  -- TODO Draw on canvas?
  local c = {love.graphics.getColor()}
  love.graphics.setColor(self.ui_background)
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), h)
  love.graphics.setColor({1, 1, 1})
  love.graphics.rectangle('line', 0, 0, love.graphics.getWidth(), h)
  love.graphics.draw(self.text)
  love.graphics.setColor(c)
  
  for k, v in pairs(self.gui) do
    v:draw()
  end
end

--- Update state
function LevelState:update(dt)
  if input.keyboard_press['p'] then -- Pause as shit
    return true, require('game.state.pause_state')() -- This is hilarious
  end
  self.board:update(dt) -- Update the state of the board, of course
  if self.board.updated then -- Board has changed
    if self.timer < 0 then
      self.timer = 0 - dt -- Set timer to 0 if it was negative, we have started
    end
    local board_state = self.board:getBoardState()
    if board_state == Board.board_states.victory then -- We are victorious
      self.ui_background = {0, 0.25, 0}
      self:updateText(dt)
      self.done = true
    elseif board_state == Board.board_states.defeat then -- This sucks
      self.ui_background = {0.25, 0, 0}
    end
  end
  for k, v in ipairs(self.gui) do
    v:update(dt) -- GUI
  end
  self:updateText(dt) -- Text
end

--- Updates upper gui
function LevelState:updateText(dt)
  if self.done then
    return
  end
  self.timer = self.timer + dt
  self.text:clear()
  
  local font = self.text:getFont()
  local h = font:getHeight()
  
  local level_label = 'Level: '
  local level_value = self.board.name
  
  local difficulty_label = 'Difficulty: '
  local difficulty_value = self.board.difficulty .. '/10'
  local difficulty_width = font:getWidth('10/10')
  
  local progress_label = 'Progress:'
  local progress_value = self.board.filled .. '/' .. self.board.total
  local progress_width = font:getWidth((self.board.total * 10) .. '/' .. self.board.total) -- These can be done at init, but ehhhh. Maybe if it's too slow
  
  local score_label = 'Score: '
  local score_value = self.timer < self.board.time and self.board.score or (math.max(0, math.floor(self.board.score - ((self.timer - self.board.time) * 500))))
  local score_width = font:getWidth('999999999')
  
  local time_label = 'Time: '
  local time_value = utils.to_time_string(self.timer)
  local time_width = font:getWidth('-00:00.000')
  
  local m = 5 -- margin
  
  local i = self.text:add(level_label .. level_value, m, m)
  local w = m * 5 + self.text:getWidth(i)
  i = self.text:add(difficulty_label, m + w, m)
  w = m + w + self.text:getWidth(i)
  self.text:addf(difficulty_value, w + difficulty_width, 'right', 0, m)
  
  self.text:addf(score_label, love.graphics.getWidth() - (m + score_width), 'right', 0, m)
  self.text:addf(score_value, love.graphics.getWidth() - m, 'right', 0, m)
  
  i = self.text:add(progress_label, m, m * 2 + h)
  w = m + self.text:getWidth(i)
  self.text:addf(progress_value, w + progress_width, 'right', 0, m * 2 + h)
  
  self.text:addf(time_label, love.graphics.getWidth() - (m + time_width), 'right', 0, m * 2 + h)
  self.text:addf(time_value, love.graphics.getWidth() - m, 'right', 0, m * 2 + h)
  
end

return LevelState
