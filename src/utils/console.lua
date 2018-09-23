-- utils/console.lua

local utils = require 'utils.utils'
local Animator = require 'utils.animator'
local gui = require 'gui.gui'
local input = require 'input.input'
local game = require 'game.game'
local LevelState = require 'game.state.level_state'
local utf8 = require 'utf8'

local Console = utils.make_class()

local param_types = {string = {}, number = {}, text = {}, filename = {}}
local white = {1, 1, 1}
local command_color = {0.6, 0.6, 0.1}
local command_error = {1, 0, 0}

function Console:_init(dir)
  self.position = dir or 'right'
  self.visible = false
  self.moving = false
  
  self.text_input = gui.TextInput(0, 0, 1, gui.fonts.console)
  self.text_input.on_return = function (text) 
    self.text_input:clear() 
    self:input(text) 
  end
  self.text_input.formatting = function(text, position)
    local toks  = Console.tokenize(text, true)
    local parts = self:test(toks, true)
    return Console.formatted(parts, text, position)
  end
  
  self:resize()

  self.history = {{white, "Type 'help' for help"}}
  self._history = love.graphics.newText(gui.fonts.console)
  self:updateHistory()

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
  
  addCommand('echo', {param_types.text}, function (params) return params[2].val end)
  addCommand('quit', {}, function (params) love.event.quit() return 'Exiting...' end)
  addCommand('exit', {}, self.commands.quit.func)
  addCommand('restart', {}, function (params) love.event.quit('restart') return 'Restarting...' end)
  addCommand('load', {param_types.filename, param_types.number}, 
    function(params)
      game:popState()
      game:addState(LevelState(params[2].val, params[3].val))
      return 'Level loaded' -- Error reporting during load
    end)
  addCommand('fps', {}, function (params) game.show_fps = not game.show_fps return 'FPS counter toggled' end)
end

function Console:log(text, color)
  color = color or white
  self.history[#self.history + 1] = {color, text}
end

function Console:failure(text)
  self.history[#self.history + 1] = {command_error, text}
end

function Console:resize()
  local function stop_open()
    self.moving = false
    self.text_input.focused = true
  end

  local function stop_close()
    self.moving = false
    self.visible = false
  end

  self.w = self.position == 'right' and love.graphics.getWidth() / 2 or love.graphics.getWidth()
  self.h = self.position == 'right' and love.graphics.getHeight() or love.graphics.getHeight() / 2

  if self.visible then
    self.x = self.position == 'right' and love.graphics.getWidth() / 2 or 0
    self.y = self.position == 'down'  and love.graphics.getHeight() - self.h or 0
  else
    self.x = self.position == 'right' and love.graphics.getWidth() or 0
    self.y = self.position == 'down'  and love.graphics.getHeight() or -self.h
  end

  local changer = self.position == 'right' and 'x' or 'y'
  local from    = self[changer]
  local change  = self.position == 'right' and self.w or (self.position == 'down' and love.graphics.getHeight() - self.h or 0)

  self._open = Animator(self, {{[changer] = Animator.fromToIn(from, change, 0.5)}, stop_open})
  self._close = Animator(self, {{[changer] = Animator.fromToIn(change, from, 0.5)}, stop_close})
  self._canvas = love.graphics.newCanvas(self.w, self.h)
  
  if self.text_input then
    self.text_input.w = self.w - (10 + gui.fonts.console:getWidth('> '))
    self.text_input:resize()
  end

end

function Console:open()
  self:updateHistory()
  self._close:terminate()
  self._close:reset()
  self.moving = true
  self.visible = true
  self._open:start()
end

function Console:close()
  self.text_input.focused = false
  self._open:terminate()
  self._open:reset()
  self.moving = true
  self._close:start()
end

function Console:draw()
  if self.visible then
    local font = self._history:getFont()
    local height = font:getHeight()
    local c = love.graphics.getCanvas()
    love.graphics.setCanvas(self._canvas)
      love.graphics.clear({0, 0, 0})
      love.graphics.setColor({1, 1, 1})
      love.graphics.rectangle('line', 0, 0, self.w, self.h)
      love.graphics.draw(self._history, 0, 0)
      
      local off = font:getWidth('> ')
      love.graphics.setColor({1, 1, 1})
      self.text_input:draw(off + 5, self.h - height - 5)
      love.graphics.setFont(font)
      love.graphics.print('> ', 5, self.h - height - 5)
    love.graphics.setCanvas(c)
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
  self.text_input:update(dt)
end

function Console.tokenize(text, full)
  full = full or false
  local ret = {}
  local cur = ''
  local i = 1
  local quoted = false
  local tlen = utf8.len(text)
  while i <= tlen do
    local char = text:utfat(i) -- string.utfat exists in extension.lua
    if not char then
      break
    elseif char == '\\' and not full then
      i = i + 1
      cur = cur .. (text:utfat(i) or '')
      i = i + 1
    elseif (not quoted) and (char == ' ' or char == '\t') then
      while char == ' '  or char == '\t' do
        if full then 
          cur = cur .. char
        end
        i = i + 1
        char = text:utfat(i)
      end
      if #cur:trim() > 0 then 
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
        char = text:utfat(i)
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
    if command == '' then
      return {{val='', hint='', type=token_type.name, stat=correctness.missing}}
    elseif self.commands[command] then
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
    return {{val='', hint='', type=token_type.name, stat=correctness.missing}}
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
        elseif cspec == param_types.text then
          res[#res + 1] = {val='', hint='<text>', type=token_type.string, stat=correctness.missing}
        elseif cspec == param_types.filename then
          res[#res + 1] = {val='', hint='<filename>', type=token_type.string, stat=correctness.missing}
        elseif type(cspec) == 'table' then 
          res[#res + 1] = {val='', hint='<' .. table.concat(cspec, '|') .. '>', type=token_type.choice, stat=correctness.missing}
        else
          res[#res + 1] = last .. {val='', hint='<????>', type=token_type.none, stat=correctness.missing}
        end
      else
        if cspec == param_types.string then 
          res[#res + 1] = {val=token, hint='', type=token_type.string, stat=correctness.ok}
        elseif cspec == param_types.number then 
          local num = tonumber(token)
          if num == nil then 
            res[#res + 1] = {val=token, hint='', type=token_type.number, stat=correctness.error}
          else
            res[#res + 1] = {val=str and token or num, hint='', type=token_type.number, stat=correctness.ok}
          end
        elseif cspec == param_types.text then 
          res[#res + 1] = {val=table.concat(tokens, str and '' or ' ', i+1), hint='', type=token_type.string, stat=correctness.ok}
          i = #tokens+1
        elseif cspec == param_types.filename then 
          local fullp = {}
          local cur = {}
          for p, c in utf8.codes(token) do
            local char = utf8.char(c)
            if char == '/' or char == '\\' then
              fullp[#fullp + 1] = table.concat(cur, '')
              cur = {}
            else
              cur[#cur + 1] = char
            end
          end
          local path = table.concat(fullp, '/')
          local file = table.concat(cur, '')
          local fileInfo = love.filesystem.getInfo(path .. '/' .. file)
          if fileInfo and token:utfat(-1) ~= '/' and token:utfat(-1) ~= '\\' then
            res[#res + 1] = {val=token, hint=(fileInfo.type ~= 'file' and file:utfat(-1) ~= ' ' and i + 2 > #tokens) and '/' or '', type=token_type.choice, stat=correctness.ok}
          else
            local files = love.filesystem.getDirectoryItems(path)
            if not files then
              res[#res + 1] = {val=token, hint='', type=token_type.choice, stat=correctness.error}
            else
              local choices = {}
              local t = str and file:trim() or file
              for k, v in ipairs(files) do 
                if #v > #t and v:sub(1, #t) == t then
                  choices[#choices + 1] = v:sub(#t + 1)
                end
              end
              if #choices == 0 then
                res[#res + 1] = {val=token, hint='', type=token_type.choice, stat=correctness.error}
              elseif #choices == 1 then
                fileInfo = love.filesystem.getInfo(token .. choices[1])
                res[#res + 1] = {val=token, hint=choices[1] .. (fileInfo.type ~= 'file' and '/' or ''), type=token_type.choice, stat=correctness.missing}
              else
                table.sort(choices)
                fileInfo = love.filesystem.getInfo(token .. choices[1])
                res[#res + 1] = {val=token, hint=choices[1] .. (fileInfo.type ~= 'file' and '/' or ''), type=token_type.choice, stat=correctness.missing}
              end
            end
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
  local tokens = Console.tokenize(text)
  local res    = self:test(tokens)
  local name   = res[1]
  local has_error = false
  if name.stat == correctness.error then 
    if #res > 1 then 
      self:log("Error: Incorrect command parameters", command_error)
      has_error = true
    else
      self:log("Error: Command " .. name.val .. " does not exist", command_error)
      has_error = true
    end
  elseif name.stat == correctness.missing then 
    self:log("Error: Missing command parameters", command_error)
    has_error = true
  else
    local cres
    cres, has_error = self.commands[name.val].func(res)
    if cres and type(cres) == 'string' and #cres > 0 then
      if not has_error then
        self:log(cres)
      else
        self:failure(cres)
      end
    end
  end
  self:updateHistory()
  return not has_error
end

function Console:updateHistory()
  local font = self._history:getFont()
  local height = font:getHeight()
  local allowed = math.floor(self.h / height) - 2

  local dlines = {}
  local ri = allowed
  for i=#self.history,1,-1 do
    local color = self.history[i][1]
    local w, lines = font:getWrap(self.history[i][2], self.w - 10)
    for j=#lines, 1, -1 do
      dlines[ri] = {color, lines[j]}
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

  for i=1,allowed do
    if dlines[i] then
      self._history:addf(dlines[i], self.w - 10, 'left', 5, (i - 1) * height + 5)
    end
  end
end

function Console.formatted(parts, fulltext, textpos)
  local printout = {}
  local hadhint = false
  local hidden = textpos - 1
  for k, v in ipairs(parts) do
    local text = v.val
    if #text > 0 then 
      local textlen = utf8.len(text)
      local willtext = true
      if textlen < hidden then 
        hidden = hidden - textlen
        willtext = false
      elseif hidden ~= 0 then 
        text = text:utfsub(hidden + 1)
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
        if (fulltext:utfat(-1) ~= ' ' and fulltext:utfat(-1) ~= '\t') and #v.val == 0 then 
          hint = ' ' .. hint
        end
      else 
        hint = ' ' .. hint
      end
      local willhint = true
      local hintlen = utf8.len(hint)
      if hintlen < hidden then 
        hidden = hidden - hintlen
        willhint = false
      elseif hidden ~= 0 then 
        hint = hint:utfsub(hidden + 1)
        hidden = 0
      end
      if willhint then
        printout[#printout + 1] = {1, 1, 1, 0.75}
        printout[#printout + 1] = hint
      end
    end
  end
  return printout
end

return Console