-- utils/console.lua

local utils = require 'utils.utils'
local Animator = require 'utils.animator'
local gui = require 'gui.gui'
local input = require 'input.input'

local Console = utils.make_class()

local param_types = {string = {}, number = {}}

function Console:_init(dir)
  self.position = dir or 'right'
  self.visible = false
  self.moving = false
  
  self:resize()

  self.history = {"Type 'help' for help"}
  self._history = love.graphics.newText(gui.fonts.console)
  self:updateHistory()

  self.text = ''
  self._text = love.graphics.newText(gui.fonts.console)

  self.commands = {}

  local function addCommand(name, spec, func)
    local function specConvert(spec) 
      local ret = {}
      for k, v in ipairs(spec) do
        if type(v) == 'string' then
          local arr = {}
          for a in v:gmatch('%|+') do 
            arr[#arr + 1] = a
          end
          ret[#ret + 1] = arr
        else 
          ret[#ret + 1] = v
        end
      end
      return ret
    end
    self.commands[name] = {spec = specConvert(spec), func = func}
  end
  
  addCommand('echo', {param_types.number, param_types.string, param_types.number, {'hello', 'goodbye'}}, function () end)

  self.textpos = 1
  self.lastchar = 0
  self.cursor = {
    position = 0,
    alpha = 1
  }
  self.cursor_blink = Animator(self.cursor, {{alpha = Animator.fromToIn(1, 0, 0.5)}, {alpha = Animator.fromToIn(0, 1, 0.5)}}, true, true)
  self:updateText()
  
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
    local font = self._history:getFont()
    local height = font:getHeight()
    love.graphics.setCanvas(self._canvas)
      love.graphics.setColor({0, 0, 0})
      love.graphics.rectangle('fill', 0, 0, self.w, self.h)
      love.graphics.setColor({1, 1, 1})
      love.graphics.rectangle('line', 0, 0, self.w, self.h)
      love.graphics.draw(self._history, 0, 0)
      love.graphics.draw(self._text, 5, self.h - height - 5)
      local ctext = '> ' .. self.text:sub(self.textpos, self.textpos + self.cursor.position - 1)
      love.graphics.setColor({1, 1, 1, self.cursor.alpha})
      love.graphics.rectangle('fill', 5 + font:getWidth(ctext), self.h - height - 10, 2, height)
    love.graphics.setCanvas()
    love.graphics.setColor({1, 1, 1, 0.75})
    love.graphics.draw(self._canvas, self.x, self.y)
  end
end

function Console:update(dt)
  if not self.visible then
    return
  end
  self._open:update(dt)
  self._close:update(dt)
  if self.moving then 
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
    local font = self._history:getFont()
    while self.textpos + self.cursor.position - 1 > #self.text or 
          font:getWidth(('> ' .. self.text:sub(self.textpos, self.textpos + self.cursor.position - 1))) > self.w - 10 do 
      self.cursor.position = self.cursor.position - 1
      if self.textpos + self.cursor.position - 1 < #self.text then 
        self.textpos = self.textpos + 1
        update = true
      end
    end
    reset_blink = true
  end
  if input.keyboard_press['return'] then 
    self:input(self.text)
    table.insert(self.history, self.text)
    self.text = ''
    self:updateHistory()
    reset_blink = true
    self.cursor.position = 0
    self.textpos = 1
    update = true
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

function Console:tokenize(text, full)
  full = full or false
  local ret = {}
  local cur = ''
  local i = 1
  local quoted = false
  while i <= #text do
    local char = text:at(i) -- string.at exists in extension.lua
    if not char then 
      break
    elseif char == '\\' then
      i = i + 1
      cur = cur .. text:at(i)
      i = i + 1
    elseif (not quoted) and (char == ' ' or char == '\t') then
      while char == ' '  or char == '\t' do
        if full then 
          cur = cur .. char
        end
        i = i + 1
        char = text:at(i)
      end
      if #cur > 0 then 
        ret[#ret + 1] = cur
        cur = ''
      end
    elseif char == '"' then
      while char == '"' do
        quoted = not quoted
        if full then 
          cur = cur .. char
        end
        i = i + 1
        char = text:at(i)
      end
    else
      cur = cur .. char
      i = i + 1
    end
  end
  if #cur > 0 then 
    ret[#ret + 1] = cur
    cur = ''
  end
  return ret
end

local token_type = {name={}, string={}, number={}, choice={}, none={}}
local correctness = {ok={}, missing={}, error={}} 

function Console:test(tokens, str) 
  str = str or false
  local res = {}
  local obj = nil
  local spec = nil
  if #tokens ~= 0 then 
    local command = str and tokens[1]:trim() or tokens[1]
    if self.commands[command] then
      obj = self.commands[command]
      spec = obj.spec
      res[#res + 1] = {val=tokens[1], hint='', type=token_type.name, stat=correctness.ok}
    else
      local choices = {}
      for k, v in pairs(self.commands) do 
        if k:sub(1, #command) == command then 
          choices[#choices + 1] = k:sub(#command + 1)
        end
      end
      if #choices == 0 then
        obj = {}
        spec = {}
        res[#res + 1] = {val=tokens[1], hint='', type=token_type.name, stat=correctness.error}
      else
        table.sort(choices)
        obj = self.commands[command .. choices[1]]
        spec = obj.spec
        res[#res + 1] = {val=tokens[1], hint=choices[1], type=token_type.name, stat=correctness.missing}
      end
    end
  else
    return {val='', hint='<command name>', type=token_type.name, stat=correctness.missing}
  end
  
  local i = 1
  while i <= #tokens-1 or i <= #spec do
    local token = tokens[i + 1]
    local cspec = spec[i]
    if cspec == nil then 
      res[#res + 1] = {val=token, hint='', type=token_type.none, stat=correctness.error}
    else
      if token == nil then 
        if cspec == param_types.string then 
          res[#res + 1] = {val='', hint='<string>', type=token_type.string, stat=correctness.missing}
        elseif cspec == param_types.number then 
          res[#res + 1] = {val='', hint='<number>', type=token_type.number, stat=correctness.missing}
        elseif type(cspec) == 'table' then 
          res[#res + 1] = {val='', hint='<' .. table.concat(cspec, '|') .. '>', type=token_type.choice, stat=correctness.missing}
        else
          res[#res + 1] = last .. {val='', hint='<????>', type=token_type.none, stat=correctness.missing}
        end
      else
        if cspec == param_types.string then 
          res[#res + 1] = {val=token, hint='', type=token_type.string, stat=correctness.correct}
        elseif cspec == param_types.number then 
          local num = tonumber(token)
          if num == nil then 
            res[#res + 1] = {val=token, hint='', type=token_type.number, stat=correctness.error}
          else
            res[#res + 1] = {val=str and token or num, hint='', type=token_type.number, stat=correctness.ok}
          end
        elseif type(cspec) == 'table' then
          local choices = {}
          local t = str and token:trim() or token
          for k, v in ipairs(cspec) do
            if v == t then 
              choices = {v:sub(#token + 1)}
              break
            elseif #v > #token and v:sub(1, #token) == t then
              choices[#choices + 1] = v:sub(#token + 1)
            end
          end
          if #choices == 0 then
            res[#res + 1] = {val=token, hint='', type=token_type.choice, stat=correctness.error}
          elseif #choices == 1 then 
            res[#res + 1] = {val=token, hint=choices[1], type=token_type.choice, stat=#choices[1] > 0 and correctness.missing or correctness.ok}
          else
            table.sort(choices)
            res[#res + 1] = {val=token, hint=choices[1], type=token_type.choice, stat=correctness.missing}
          end
        else
          res[#res + 1] = last .. {val='', hint='<????>', type=token_type.none, stat=correctness.missing}
        end
      end
    end
    i = i + 1
  end
  local endresult = nil
  for k, v in ipairs(res) do 
    if not endresult then 
      endresult = v.stat
    elseif v.stat == correctness.error then 
      endresult = correctness.error 
    elseif v.stat == correctness.missing and endresult == correctness.ok then 
      endresult = correctness.missing
    end
  end
  res[1].stat = endresult
  return res
end

function Console:input(text)
  
end

function Console:updateHistory()
  local font = self._history:getFont()
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

  self._history:clear()

  for k, v in pairs(dlines) do
    if v then  
      self._history:addf(v, self.w - 10, 'left', 5, (k - 1) * height + 5)
    end
  end
end

function Console:updateText()
  local tokens = self:tokenize(self.text, true)
  local res    = self:test(tokens, true)
  local printout = {{1, 1, 1}, '> '}
  local hadhint = false
  local hidden = self.textpos - 1
  for k, v in ipairs(res) do
    local text = v.val
    if #text > 0 then 
      local willtext = true
      if #text < hidden then 
        hidden = hidden - #text
        willtext = false
      elseif hidden ~= 0 then 
        text = text:sub(hidden + 1)
        hidden = 0
      end
      if willtext then 
        if v.type == token_type.string then 
          printout[#printout + 1] = {1, 165/255, 0}
          printout[#printout + 1] = text
        else
          if v.stat == correctness.ok then 
            printout[#printout + 1] = {0, 1, 0}
          elseif v.stat == correctness.missing then 
            printout[#printout + 1] = {1, 1, 0}
          else
            printout[#printout + 1] = {1, 0, 0}
          end
          printout[#printout + 1] = text
        end
      end
    end
    local hint = v.hint
    if #hint > 0 then 
      if not hadhint then 
        hadhint = true
        if (self.text:at(-1) ~= ' ' and self.text:at(-1) ~= '\t') and #v.val == 0 then 
          hint = ' ' .. hint
        end
      else 
        hint = ' ' .. hint
      end
      local willhint = true
      if #hint < hidden then 
        hidden = hidden - #hint
        willhint = false
      elseif hidden ~= 0 then 
        hint = hint:sub(hidden + 1)
        hidden = 0
      end
      if willhint then
        printout[#printout + 1] = {1, 1, 1, 0.75}
        printout[#printout + 1] = hint
      end
    end
  end
  self._text:clear()
  self._text:set(printout)
end

return Console