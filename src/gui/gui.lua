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

--- Labels are simply text on screen. Reacts to nothing
local Label = make_gobject()

--- Make a label at position (`x`, `y`), with text `text` and font `font` or the default
function Label:_init(x, y, text, font)
  self.x = x -- Label's x position
  self.y = y -- Label's y position
  self.text = text -- Label's text
  self.font = font or fonts.game -- Label's font
  self.color = {1, 1, 0} -- Label's color
  self.anim = {} -- Animations, if any
  self._text = love.graphics.newText(self.font, self.text) -- Label canvas
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

--- Resets the text to the value of `text`
function Label:setText(text)
  text = text or ''
  self.text = text
  self._text:clear()
  self._text:add(self.text)
end

--- Adds `text` to the label
function Label:appendText(text)
  self.text = self.text .. text
  self._text:clear()
  self._text:add(self.text)
end

--- TextInput objects accept user input and show it, optionally formatted
local TextInput = make_gobject()

--- Make a text input at position (`x`, `y`), of width `w` and font `font` or the default
-- The height of the text input equals the height of the font chosen
function TextInput:_init(x, y, w, font)
  self.x = x -- x position
  self.y = y -- y position
  self.w = w -- width
  
  self.font = font or fonts.default -- font
  self.h = font:getHeight() + 2 -- height
  
  self.text = '' -- text shown
  self.text_buffer = '' -- text waiting to be shown
  self._text = love.graphics.newText(font) -- canvas for text
  
  self.textpos = 1 -- Position of the first character shown
  self.lastchar = 0 -- Time since last character written
  self.cursor = { -- Cursor data
    position = 0, -- Cursor position, relative to text shown, not full text
    alpha = 0 -- Cursor alpha
  }
  self.cursor_blink = Animator(self.cursor, {{alpha = Animator.fromToIn(1, 0, 0.5)}, {alpha = Animator.fromToIn(0, 1, 0.5)}}, true, true) -- Blinking animation. It loops yo!
  
  self.focused = false -- If the text input is focused
  self.formatting = nil -- Formatting function, if any
  self.on_return = function() self.focused = false self.cursor.alpha = 0 end -- Return function, if any
  self._canvas = love.graphics.newCanvas(self.w, self.h) -- Canvas to draw on
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

--- Updates text with offset
function TextInput:_update(dt, x, y)
  if not self.focused then
    return -- Update fuck all if we're not focused
  end
  
  self.cursor_blink:update(dt) -- O.O -.- O.O
  self.lastchar = self.lastchar + dt
  if self.lastchar > 0.5 and not self.cursor_blink.started then
    self.cursor_blink:start() -- Blink only after a bit when typing
  end
  local reset_blink = false
  local update = false -- If the cursor position/text shown might have to be updated
  
  if #self.text_buffer > 0 then -- Something was added to the buffer
    reset_blink = true
    update = true
    self.text = self:beforeCursor() .. self.text_buffer .. self:afterCursor() -- Add it to the text
    self.cursor.position = self.cursor.position + utf8.len(self.text_buffer) -- Update cursor position
    self.text_buffer = ''
  end
  if input.text_input and #input.text_input > 0 then -- This is repeated twice but I don't want to call an anonymous function...
    reset_blink = true
    update = true
    self.text = self:beforeCursor() .. input.text_input .. self:afterCursor()
    self.cursor.position = self.cursor.position + utf8.len(input.text_input)
  end
  if input.keyboard_press['backspace'] then -- Backspace, remove backwards
    if self.cursor.position + self.textpos > 1 then
      self.text = self.text:sub(1, utf8.offset(self:beforeCursor(), 0, -1) - 1) .. self:afterCursor()
      self.cursor.position = self.cursor.position - 1
      reset_blink = true
      update = true
    end
  end
  if input.keyboard_press['delete'] then -- Delete, remove forwards
    if self.cursor.position + self.textpos - 1 < utf8.len(self.text) then 
      self.text = self:beforeCursor() .. self.text:sub(utf8.offset(self.text, self.cursor.position + self.textpos + 1))
      reset_blink = true
      update = true
    end
  end
  if input.keyboard_press['left'] or update then -- Move left?
    if input.keyboard_press['left'] then  -- Move left
      self.cursor.position = self.cursor.position - 1
    end
    if self.cursor.position < 0 then -- Fix cursor position and text shown
      if self.textpos ~= 1 then
        self.textpos = math.max(self.textpos + self.cursor.position, 1)
        update = true
      end
      self.cursor.position = 0
    end
    reset_blink = true
  end
  if input.keyboard_press['right'] or update then -- Move right?
    if input.keyboard_press['right'] then -- Move right
      self.cursor.position = self.cursor.position + 1
    end
    local font = self.font
    while self.textpos + self.cursor.position - 1 > utf8.len(self.text) or 
          font:getWidth(self:visibleBeforeCursor()) > self.w do -- Fix cursor position
      self.cursor.position = self.cursor.position - 1
      if self.textpos + self.cursor.position - 1 < utf8.len(self.text) then 
        self.textpos = self.textpos + 1
        update = true
      end
    end
    reset_blink = true
  end
  if input.keyboard_press['return'] then -- Enter
    self.on_return(self.text) -- Call enter function
  end
  if reset_blink then -- Something typed, reset cursor blinking
    self.cursor_blink:reset()
    self.cursor_blink:stop()
    self.cursor.alpha = 1 -- Cursor visible by default
    self.lastchar = 0
  end
  if update then
    self:updateText() -- Update the text canvas
  end
end

--- Add text to the buffer as if it had been typed
function TextInput:addText(text)
  self.text_buffer = self.text_buffer .. text
end

--- Gives all text before the cursor
function TextInput:beforeCursor()
  return self.text:sub(1, utf8.offset(self.text, self.textpos + self.cursor.position) - 1)
end

--- Gives all visible text before the cursor
function TextInput:visibleBeforeCursor()
  return self.text:sub(utf8.offset(self.text, self.textpos), utf8.offset(self.text, self.textpos + self.cursor.position) - 1)
end

--- Gives all text after the cursor
function TextInput:afterCursor()
  return self.text:sub(utf8.offset(self.text, self.textpos + self.cursor.position))
end

--- Gives all text that can be seen
function TextInput:visibleText()
  return self.text:sub(utf8.offset(self.text, self.textpos))
end

--- Prints to the text canvas
function TextInput:updateText()
  local printout = self.formatting and self.formatting(self.text, self.textpos) or {{1, 1, 1}, self:visibleText()}
  self._text:clear()
  self._text:set(printout)
end

--- Clears the text input
function TextInput:clear()
  self.text = ''
  self.textpos = 1
  self.cursor.position = 0
  self:updateText()
end

--- Button. What else do you need?
local Button = make_gobject()

Button.states = {normal = "normal", focused = "focused", held = "held", clicked = "clicked"}

--- Creates a button at position (`x`, `y`), which will call `callback` when pressed.
-- `options` is a table that may contain 
-- {
--  width = button width, height = button height
--  text = button text, toggle = button is toggleable, inverse_callback = callback on detoggle
--  font = button text font, image = button image, text_color = button text color,
--  background_color = button background color, border_color = button border color
--  + clicked, held and hover versions
--  border_radius = border radius for round buttons
-- }
function Button:_init(x, y, callback, options)
  self.x = x -- x position
  self.y = y -- y position
  self.callback = callback -- press function
  
  self.text = options.text -- text, if any
  
  self.toggle = options.toggle or false -- toggleable, if any
  if self.toggle then
    if type(options.inverse_callback) == "function" then -- inverse callback in case of toggle button
      self.inverse_callback = options.inverse_callback
    else
      error("Toggle button must contain inverse_callback.")
    end
  end
  
  self.previous_state = Button.states.normal -- Buttons start in normal state
  self.state = Button.states.normal
  self.updates_since_click = 0 -- Time since last click

  -- Text button
  self.font = options.font or fonts.game -- Text font, if any

  -- Image button
  self.image = options.image -- Button image, if any

  -- Colors for all kinds of stuff, yo
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
  
  self.corner_radius = options.corner_radius or 0 -- Button roundness, hmmm, nice

  if self.image ~= nil then
    self._drawable = love.graphics.newImage(self.image) -- Canvas for image
  elseif self.text ~= nil and self.text:trim() ~= '' then
    self._drawable = love.graphics.newText(self.font, self.text) -- Canvas for text
  else
    self._drawable = nil -- No canvas, invisible button
  end

  if type(options.width) == "number" and type(options.height) == "number" then
    self.width, self.height = options.width, options.height -- Optional width-height
  elseif (self.text ~= nil and self.text:match("%S+")) or self.image ~= nil then
    self.width, self.height = self._drawable:getDimensions() -- Get width height from text/image
  else
    error("Width and height required for empty/whitespace-only string.")
  end
end

--- Draw button, if anything
function Button:_draw(x, y)
  local text_color = self.colors[self.state].text
  local background_color = self.colors[self.state].background
  local border_color = self.colors[self.state].border

  love.graphics.setColor(background_color)
  love.graphics.rectangle("fill", self.x + x, self.y + y, self.width, self.height, self.corner_radius)
  love.graphics.setColor(border_color)
  love.graphics.rectangle("line", self.x + x, self.y + y, self.width, self.height, self.corner_radius)
  if self._drawable then -- Don't draw anything if it doesn't exist, ofc
    love.graphics.setColor(text_color)
    love.graphics.draw(self._drawable, self.x + x, self.y + y)
  end
end

--- Set button to normal state
function Button:normal()
  self.state = Button.states.normal
end

--- Set button to focused state
function Button:focus()
  self.state = Button.states.focused
end

--- Set buttons to previous state state
function Button:unhold()
  self.state = self.previous_state
end

--- Set button to held state
function Button:hold()
  if self.state ~= Button.states.held then 
    self.previous_state = self.state 
  end
  self.state = Button.states.held
end

--- Clicks the button. Manages state changes and callback calls
function Button:click()
  if self.toggle then -- Toggleable buttons
    if self.state == Button.states.clicked then
      self.state = Button.states.normal -- Go back to unclicked
      self.inverse_callback()
    else
      self.state = Button.states.clicked -- Set to clicked
      self.callback()
    end
  else
    self.state = Button.states.clicked
    self.callback()
  end
end

--- Updates the button based on user input
function Button:_update(dt, x, y)
  local mx, my = input:get_mouse_position()
  mx = mx - x
  my = my - y
  if self.x <= mx and mx <= self.x + self.width and self.y <= my and my <= self.y + self.height then -- Mouse inside button
    if not (input.mouse_press[1] or input.mouse_down[1]) and self.updates_since_click == 0 then
      if self.state ~= Button.states.clicked then -- Not clicking, simply focus
        self:focus()
      end
    else
      self.updates_since_click = self.updates_since_click + 1
      if self.updates_since_click <= 10 then -- Clicking 
        if input.mouse_release[1] then
          self:click()
          self.updates_since_click = 0
        end
      else -- ???
        if input.mouse_down[1] then 
          self:hold()
        else
          self:normal()
          self.updates_since_click = 0
        end
      end
    end
  elseif not input.mouse_down[1] then -- Mouse outside button
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