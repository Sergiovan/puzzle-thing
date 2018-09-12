-- utils/console.lua

local utils = require 'utils.utils'
local Animator = require 'utils.animator'
local gui = require 'gui.gui'
local input = require 'input.input'

local Console = utils.make_class()

function Console:_init(dir)
  self.position = dir or 'right'
  self.visible = false
  self.moving = false
  
  self:resize()

  self.history = {"Type 'help' for help"}
  self._text = love.graphics.newText(gui.fonts.console)
  self:updateText()

  self.text = ''
  self.textpos = 1
  self.lastchar = 0
  self.cursor = {
    position = 0,
    alpha = 1
  }
  self.cursor_blink = Animator(self.cursor, {{alpha = Animator.fromToIn(1, 0, 0.5)}, {alpha = Animator.fromToIn(0, 1, 0.5)}}, true, true)

end

function Console:resize()
  local function stop_open()
    self.moving = false
  end

  local function stop_close()
    self.moving = false
    self.visible = false
  end

  self.w = self.position == 'right' and love.graphics.getWidth() / 2 or love.graphics.getWidth()
  self.h = self.position == 'right' and love.graphics.getHeight() or love.graphics.getHeight() / 2

  if self.visible then
    self.x = self.position == 'right' and love.graphics.getWidth() / 2 or 0
    self.y = self.position == 'down'  and love.graphics.getHeight() / 2 or 0
  else
    self.x = self.position == 'right' and love.graphics.getWidth() or 0
    self.y = self.position == 'down'  and love.graphics.getHeight() or 0
  end

  local changer = self.position == 'right' and 'x' or 'y'
  local from    = self[changer]
  local change  = self.position == 'right' and self.w or self.h

  self._open = Animator(self, {{[changer] = Animator.fromToIn(from, change, 0.5)}, stop_open})
  self._close = Animator(self, {{[changer] = Animator.fromToIn(change, from, 0.5)}, stop_close})
  self._canvas = love.graphics.newCanvas(self.w, self.h)

end

function Console:open()
  self._close:terminate()
  self._close:reset()
  self.moving = true
  self.visible = true
  self._open:start()
end

function Console:close()
  self._open:terminate()
  self._open:reset()
  self.moving = true
  self._close:start()
end

function Console:draw()
  if self.visible then
    local font = self._text:getFont()
    local height = font:getHeight()
    love.graphics.setCanvas(self._canvas)
      love.graphics.setColor({0, 0, 0})
      love.graphics.rectangle('fill', 0, 0, self.w, self.h)
      love.graphics.setColor({1, 1, 1})
      love.graphics.rectangle('line', 0, 0, self.w, self.h)
      love.graphics.draw(self._text, 0, 0)
      love.graphics.setFont(font)
      local text = '> ' .. self.text:sub(self.textpos)
      local ctext = '> ' .. self.text:sub(self.textpos, self.textpos + self.cursor.position - 1)
      love.graphics.print(text, 5, self.h - height - 5)
      love.graphics.setColor({1, 1, 1, self.cursor.alpha})
      love.graphics.rectangle('fill', 5 + font:getWidth(ctext), self.h - height - 10, 2, height)
    love.graphics.setCanvas()
    love.graphics.setColor({1, 1, 1, 0.75})
    love.graphics.draw(self._canvas, self.x, self.y)
  end
end

function Console:update(dt)
  self._open:update(dt)
  self._close:update(dt)
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
    self.text = self.text:sub(1, self.textpos + self.cursor.position - 1) .. input.text_input .. self.text:sub(self.textpos + self.cursor.position)
    self.cursor.position = self.cursor.position + #input.text_input
  end
  if input.keyboard_press['backspace'] then
    if self.cursor.position + self.textpos > 1 then 
      self.text = self.text:sub(1, self.cursor.position + self.textpos - 2) .. self.text:sub(self.cursor.position + self.textpos)
      self.cursor.position = self.cursor.position - 1
      reset_blink = true
      update = true
    end
  end
  if input.keyboard_press['delete'] then 
    if self.cursor.position + self.textpos - 1 < #self.text then 
      self.text = self.text:sub(1, self.cursor.position + self.textpos - 1) .. self.text:sub(self.cursor.position + self.textpos + 1)
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
      end
      self.cursor.position = 0
    end
    reset_blink = true
  end
  if input.keyboard_press['right'] or update then 
    if input.keyboard_press['right'] then 
      self.cursor.position = self.cursor.position + 1
    end
    local font = self._text:getFont()
    while self.textpos + self.cursor.position - 1 > #self.text or 
          font:getWidth(('> ' .. self.text:sub(self.textpos, self.textpos + self.cursor.position - 1))) > self.w - 10 do 
      self.cursor.position = self.cursor.position - 1
      if self.textpos + self.cursor.position - 1 < #self.text then 
        self.textpos = self.textpos + 1
      end
    end
    reset_blink = true
  end
  if input.keyboard_press['return'] then 
    -- Do thing
    table.insert(self.history, self.text)
    self.text = ''
    self:updateText()
    reset_blink = true
  end
  if reset_blink then 
    self.cursor_blink:reset()
    self.cursor_blink:stop()
    self.cursor.alpha = 1
    self.lastchar = 0
  end
end

function Console:input()

end

function Console:updateText()
  local font = self._text:getFont()
  local height = font:getHeight()
  local allowed = math.floor(self.h / height) - 2

  local dlines = {}
  local ri = allowed
  for i=#self.history,1,-1 do 
    local w, lines = font:getWrap(self.history[i], self.w - 10)
    for j=#lines, 1, -1 do 
      dlines[ri] = lines[j]
      ri = ri - 1
      if ri == 0 then
        break
      end
    end
    if ri == 0 then
      break
    end
  end

  self._text:clear()

  for k, v in pairs(dlines) do
    if v then  
      self._text:addf(v, self.w - 10, 'left', 5, (k - 1) * height + 5)
    end
  end
end

return Console