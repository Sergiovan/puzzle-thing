-- gui/gui.lua

local utils = require 'utils.utils'
local make_gobject = require 'abstract.gobject'
local input = require 'input.input'
local Animator = require 'utils.animator'
local utf8 = require 'utf8'

local module = {}
local colors = {}
colors.default = {1, 1, 1}

local font_size = 36
local font_size_small = 16
local font_size_big = 60

local fonts = {}
fonts.default = love.graphics.newFont(font_size)
fonts.default_small = love.graphics.newFont(font_size_small)
fonts.console = utils.file_exists 'res/Consolas.ttf' and love.graphics.newFont('res/Consolas.ttf', font_size_small) or fonts.default
fonts.game    = utils.file_exists 'res/GameFont.ttf' and love.graphics.newFont('res/GameFont.ttf', font_size) or fonts.default
fonts.game_small = utils.file_exists 'res/GameFont.ttf' and love.graphics.newFont('res/GameFont.ttf', font_size_small) or fonts.default_small

local Label = make_gobject()

function Label:_init(x, y, text, font)
  self.x = x
  self.y = y
  self.text = text
  self.font = font or fonts.game
  self.color = {1, 1, 0}
  self.anim = {}
  self._text = love.graphics.newText(self.font, self.text)
end

function Label:_draw(x, y)
  love.graphics.setColor(self.color)
  love.graphics.draw(self._text, self.x + x, self.y + y)
end

function Label:_update(dt, x, y)
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

local TextInput = make_gobject()

function TextInput:_init(x, y, w, font)
  self.x = x
  self.y = y
  self.w = w
  
  self.font = font or fonts.default
  self.h = font:getHeight() + 2
  
  self.text = ''
  self._text = love.graphics.newText(font)
  
  self.textpos = 1
  self.lastchar = 0
  self.cursor = {
    position = 0,
    alpha = 0
  }
  self.cursor_blink = Animator(self.cursor, {{alpha = Animator.fromToIn(1, 0, 0.5)}, {alpha = Animator.fromToIn(0, 1, 0.5)}}, true, true)
  
  self.focused = false
  self.formatting = nil
  self.on_return = function() self.focused = false self.cursor.alpha = 0 end
  self._canvas = love.graphics.newCanvas(self.w, self.h)
end

function TextInput:_resize()
  self._canvas = love.graphics.newCanvas(self.w, self.h)
end

function TextInput:_draw(x, y)
  local c = love.graphics.getCanvas()
  local font = self.font
  love.graphics.setCanvas(self._canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(self._text, 0, 1)
    local beforeCursor = self:beforeCursor()
    local ctext = beforeCursor:sub(utf8.offset(beforeCursor, self.textpos) or 0)
    love.graphics.setColor({1, 1, 1, self.cursor.alpha})
    love.graphics.rectangle('fill', font:getWidth(ctext), 0, 2, self.h)
  love.graphics.setCanvas(c)
  love.graphics.setColor({1, 1, 1, 0.75})
  love.graphics.draw(self._canvas, self.x + x, self.y + y)
end

function TextInput:_update(dt, x, y)
  if not self.focused then
    return
  end
  
  self.cursor_blink:update(dt)
  self.lastchar = self.lastchar + dt
  if self.lastchar > 0.5 and not self.cursor_blink.started then
    self.cursor_blink:start()
  end
  local reset_blink = false
  local update = false
  
  if input.text_input and #input.text_input > 0 then
    reset_blink = true
    update = true
    self.text = self:beforeCursor() .. input.text_input .. self:afterCursor()
    self.cursor.position = self.cursor.position + utf8.len(input.text_input)
  end
  if input.keyboard_press['backspace'] then 
    if self.cursor.position + self.textpos > 1 then
      self.text = self.text:sub(1, utf8.offset(self:beforeCursor(), 0, -1) - 1) .. self:afterCursor()
      self.cursor.position = self.cursor.position - 1
      reset_blink = true
      update = true
    end
  end
  if input.keyboard_press['delete'] then
    if self.cursor.position + self.textpos - 1 < utf8.len(self.text) then 
      self.text = self:beforeCursor() .. self.text:sub(utf8.offset(self.text, self.cursor.position + self.textpos + 1))
      reset_blink = true
      update = true
    end
  end
  if input.keyboard_press['left'] or update then
    if input.keyboard_press['left'] then 
      self.cursor.position = self.cursor.position - 1
    end
    if self.cursor.position < 0 then
      if self.textpos ~= 1 then
        self.textpos = math.max(self.textpos + self.cursor.position, 1)
        update = true
      end
      self.cursor.position = 0
    end
    reset_blink = true
  end
  if input.keyboard_press['right'] or update then 
    if input.keyboard_press['right'] then 
      self.cursor.position = self.cursor.position + 1
    end
    local font = self.font
    while self.textpos + self.cursor.position - 1 > utf8.len(self.text) or 
          font:getWidth(self:visibleBeforeCursor()) > self.w do 
      self.cursor.position = self.cursor.position - 1
      if self.textpos + self.cursor.position - 1 < utf8.len(self.text) then 
        self.textpos = self.textpos + 1
        update = true
      end
    end
    reset_blink = true
  end
  if input.keyboard_press['return'] then 
    self.on_return(self.text)
  end
  if reset_blink then 
    self.cursor_blink:reset()
    self.cursor_blink:stop()
    self.cursor.alpha = 1
    self.lastchar = 0
  end
  if update then
    self:updateText()
  end
end

function TextInput:beforeCursor()
  return self.text:sub(1, utf8.offset(self.text, self.textpos + self.cursor.position) - 1)
end

function TextInput:visibleBeforeCursor()
  return self.text:sub(utf8.offset(self.text, self.textpos), utf8.offset(self.text, self.textpos + self.cursor.position) - 1)
end

function TextInput:afterCursor()
  return self.text:sub(utf8.offset(self.text, self.textpos + self.cursor.position))
end

function TextInput:visibleText()
  return self.text:sub(utf8.offset(self.text, self.textpos))
end

function TextInput:updateText()
  local printout = self.formatting and self.formatting(self.text, self.textpos) or {{1, 1, 1}, self:visibleText()}
  self._text:clear()
  self._text:set(printout)
end

function TextInput:clear()
  self.text = ''
  self.textpos = 1
  self.cursor.position = 0
  self:updateText()
end

local Button = make_gobject()

Button.states = {normal = "normal", focused = "focused", held = "held", clicked = "clicked"}

function Button:_init(x, y, callback, options)
  self.x = x
  self.y = y
  self.callback = callback
  
  self.text = options.text
  
  self.toggle = options.toggle or false
  if self.toggle then
    if type(options.inverse_callback) == "function" then
      self.inverse_callback = options.inverse_callback
    else
      error("Toggle button must contain inverse_callback.")
    end
  end
  
  self.previous_state = Button.states.normal
  self.state = Button.states.normal
  self.updates_since_click = 0

  -- Text button
  self.font = options.font or fonts.game

  -- Image button
  self.image = options.image

  local text_color = options.text_color or {1, 1, 1}
  local background_color = options.background_color or {1, 1, 1, 0}
  local border_color = options.border_color or {1, 1, 1, 0}

  self.colors = {
    normal = {
      text = text_color,
      background = background_color,
      border = border_color,
    },
    focused = {
      text = options.focused_text_color or text_color,
      background = options.focused_background_color or background_color,
      border = options.focused_border_color or border_color,
    },
    held = {
      text = options.held_text_color or text_color,
      background = options.held_background_color or background_color,
      border = options.focused_border_color or border_color,
    },
    clicked = {
      text = options.clicked_text_color or text_color,
      background = options.clicked_background_color or background_color,
      border = options.clicked_border_color or border_color,
    },
  }
  
  self.corner_radius = options.corner_radius or 0

  if self.image ~= nil then
    self._drawable = love.graphics.newImage(self.image)
  elseif self.text ~= nil and self.text:trim() ~= '' then
    self._drawable = love.graphics.newText(self.font, self.text)
  else
    self._drawable = nil
  end

  if type(options.width) == "number" and type(options.height) == "number" then
    self.width, self.height = options.width, options.height
  elseif (self.text ~= nil and self.text:match("%S+")) or self.image ~= nil then
    self.width, self.height = self._drawable:getDimensions()
  else
    error("Width and height required for empty/whitespace-only string.")
  end
end

function Button:_draw(x, y)
  local text_color = self.colors[self.state].text
  local background_color = self.colors[self.state].background
  local border_color = self.colors[self.state].border

  love.graphics.setColor(background_color)
  love.graphics.rectangle("fill", self.x + x, self.y + y, self.width, self.height, self.corner_radius)
  love.graphics.setColor(border_color)
  love.graphics.rectangle("line", self.x + x, self.y + y, self.width, self.height, self.corner_radius)
  if self._drawable then
    love.graphics.setColor(text_color)
    love.graphics.draw(self._drawable, self.x + x, self.y + y)
  end
end

function Button:normal()
  self.state = Button.states.normal
end

function Button:focus()
  self.state = Button.states.focused
end

function Button:unhold()
  self.state = self.previous_state
end

function Button:hold()
  if self.state ~= Button.states.held then 
    self.previous_state = self.state 
  end
  self.state = Button.states.held
end

function Button:click()
  if self.toggle then
    if self.state == Button.states.clicked then
      self.state = Button.states.normal
      self.inverse_callback()
    else
      self.state = Button.states.clicked
      self.callback()
    end
  else
    self.state = Button.states.clicked
    self.callback()
  end
end

function Button:_update(dt, x, y)
  local mx, my = input:get_mouse_position()
  mx = mx - x
  my = my - y
  if self.x <= mx and mx <= self.x + self.width and self.y <= my and my <= self.y + self.height then
    if not (input.mouse_press[1] or input.mouse_down[1]) and self.updates_since_click == 0 then
      if self.state ~= Button.states.clicked then
        self:focus()
      end
    else
      self.updates_since_click = self.updates_since_click + 1
      if self.updates_since_click <= 10 then
        if input.mouse_release[1] then
          self:click()
          self.updates_since_click = 0
        end
      else
        if input.mouse_down[1] then
          self:hold()
        else
          self:normal()
          self.updates_since_click = 0
        end
      end
    end
  elseif not input.mouse_down[1] then
    if self.state ~= Button.states.clicked then
      self:unhold()
      self.updates_since_click = 0
    end
  end
end

module.colors = colors
module.fonts = fonts
module.Label = Label
module.TextInput = TextInput
module.Button = Button

return module