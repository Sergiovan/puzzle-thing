-- gui/gui.lua
local utils = require 'utils.utils'
local Animator = require 'utils.animator'

local module = {}
local colors = {}
colors.default = {1, 1, 1}
local fonts = {}
fonts.default = love.graphics.newFont(36)
fonts.console = utils.file_exists 'res/Consolas.ttf' and love.graphics.newFont('res/Consolas.ttf', 24) or fonts.default
fonts.game    = utils.file_exists 'res/GameFont.ttf' and love.graphics.newFont('res/GameFont.ttf', 60) or fonts.default

local Label = utils.make_class()

function Label:_init(x, y, text, font)
  self.x = x
  self.y = y
  self.text = text
  self.font = font or fonts.default
  self.color = {1, 1, 0}
  self.anim = {}
  self._text = love.graphics.newText(self.font, self.text)
end

function Label:draw(x, y)
  x = x or 0
  y = y or 0
  love.graphics.setColor(self.color)
  love.graphics.draw(self._text, self.x + x, self.y + y)
end

function Label:update(dt)
  for k, v in ipairs(self.anim) do
    v:update(dt)
  end
end

function Label:setText(text)
  text = text or ''
  self.text = text
  self._text:clear()
  self._text:add(self.text)
end

function Label:appendText(text)
  self.text = self.text .. text
  self._text:clear()
  self._text:add(self.text)
end

module.colors = colors
module.fonts = fonts
module.Label = Label

return module