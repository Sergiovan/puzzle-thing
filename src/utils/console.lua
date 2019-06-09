-- utils/console.lua

local make_gobject = require 'abstract.gobject'
local Animator = require 'utils.animator'
local gui = require 'gui.gui'
local input = require 'input.input'
local game = require 'game.game'
local LevelState = require 'game.state.level_state'
local utf8 = require 'utf8'

local Console = make_gobject()

local param_types = {string = {}, number = {}, text = {}, filename = {}}
local white = {1, 1, 1}
local command_color = {0.6, 0.6, 0.1}
local command_error = {1, 0, 0}

local token_type = {name={}, string={}, number={}, choice={}, none={}}
local correctness = {ok={}, hint_only={}, missing={}, error={}} 

--- Initializes console with position `dir`
function Console:_init(dir)
  self.position = dir or 'right' -- The position on the window of the console
  self.visible = false -- If the console is currently visible
  self.moving = false -- If the console is currently moving
  
  self.text_input = gui.TextInput(0, 0, 1, gui.fonts.console) -- A text input object
  self.text_input.on_return = function (text) -- On enter, clear the input and give it to the console
    self.text_input:clear() 
    self:input(text) 
  end
  self.text_input.formatting = function(text, position) -- Custom text input formatting
    local toks  = Console.tokenize(text, true) -- Tokenize input
    local parts = self:test(toks, true) -- Colorize input
    return Console.formatted(parts, text, position) -- Print formatted
  end
  
  self:resize()

  self.history = {{white, "Type 'help' for help"}} -- Previously sent commands
  self._history = love.graphics.newText(gui.fonts.console) -- Graphical version of history
  self:updateHistory()

  self.commands = {} -- List of commands the console accepts

  --- Adds a command to the console
  -- `name` is a string, the name of the command
  -- `spec` is a table of accepted parameter types
  -- Parameter types can be param_types or strings
  -- `func` is the command's function, which has one argument,
  -- the parameters passed to the function, and returns a string to 
  -- be printed on the console
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
  
  -- Echo command returns the text after it
  addCommand('echo', {param_types.text}, function (params) return params[2].val end)
  -- Quit command... quits the game
  addCommand('quit', {}, function (params) love.event.quit() return 'Exiting...' end)
  -- Exit command is a copy of quit
  addCommand('exit', {}, self.commands.quit.func)
  -- Restart command restarts the game from scratch
  addCommand('restart', {}, function (params) love.event.quit('restart') return 'Restarting...' end)
  -- Load command loads level $2 from file $1
  addCommand('load', {param_types.filename, param_types.number}, 
    function(params)
      game:popState()
      game:addState(LevelState(params[2].val, params[3].val))
      return 'Level loaded' -- Error reporting during load
    end)
  -- FPS command toggles fps viewer
  addCommand('fps', {}, function (params) game.show_fps = not game.show_fps return 'FPS counter toggled' end)
end

--- Shows `text` on the console with color `color` 
function Console:log(text, color)
  color = color or white
  self.history[#self.history + 1] = {color, text}
end

--- Shows `text` on the console in red
function Console:failure(text)
  self.history[#self.history + 1] = {command_error, text}
end

--- Sets up console size data and animation data
function Console:_resize()
  --- Ends the opening animation
  local function stop_open()
    self.moving = false
    self.text_input.focused = true
  end

  --- Closes the opening animation
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

  local changer = self.position == 'right' and 'x' or 'y' -- Which variable needs to be animated for opening
  local from    = self[changer] -- Initial movement value
  local change  = self.position == 'right' and self.w or (self.position == 'down' and love.graphics.getHeight() - self.h or 0) -- Amount of change required

  self._open = Animator(self, {{[changer] = Animator.fromToIn(from, change, 0.5)}, stop_open}) -- Opening animation
  self._close = Animator(self, {{[changer] = Animator.fromToIn(change, from, 0.5)}, stop_close}) -- Closing animation
  self._canvas = love.graphics.newCanvas(self.w, self.h) -- Canvas on which the console will be painted
  
  if self.text_input then
    self.text_input.w = self.w - (10 + gui.fonts.console:getWidth('> '))
    self.text_input:resize() -- Resize text input as well
  end

end

--- Opens the console
function Console:open()
  self:updateHistory()
  self._close:terminate()
  self._close:reset()
  self.moving = true
  self.visible = true
  self._open:start()
end

--- Closes the console
function Console:close()
  self.text_input.focused = false
  self._open:terminate()
  self._open:reset()
  self.moving = true
  self._close:start()
end

--- Draws the console
function Console:_draw(x, y)
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
    love.graphics.draw(self._canvas, self.x + x, self.y + y)
  end
end

--- Updates the console
function Console:_update(dt, x, y)
  if not self.visible then
    return
  end
  self._open:update(dt)
  self._close:update(dt)
  if self.moving then 
    return
  end
  if input.keyboard_press['tab'] then -- Autocomplete
    local toks = Console.tokenize(self.text_input.text, true)
    toks = self:test(toks, true) -- Get all autocomplete values
    for i=1,#toks do
      local tok = toks[i]
      if tok.hint ~= nil and tok.hint ~= '' and tok.stat ~= correctness.hint_only then
        self.text_input:addText(tok.hint) -- Correct with autocompleteable values only
        break
      end
    end
  end
  self.text_input:update(dt, x, y)
end

--- Converts `text` into tokens. If `full` is truthy it takes the input as-is
-- else it does escaping and space skipping
function Console.tokenize(text, full)
  full = full or false
  local ret = {}
  local cur = ''
  local i = 1
  local quoted = false
  local tlen = utf8.len(text)
  while i <= tlen do -- For each character
    local char = text:utfat(i) -- string.utfat exists in extension.lua
    if not char then
      break -- EOS
    elseif char == '\\' and not full then -- Escape the next character
      i = i + 1
      cur = cur .. (text:utfat(i) or '')
      i = i + 1
    elseif (not quoted) and (char == ' ' or char == '\t') then -- Token end when not in quotes
      while char == ' '  or char == '\t' do -- Skip whitespace
        if full then  -- Unless full
          cur = cur .. char
        end
        i = i + 1
        char = text:utfat(i)
      end
      if #cur:trim() > 0 then -- We are at the next token
        ret[#ret + 1] = cur
        cur = ''
      end
    elseif char == '"' then -- Quotation marks
      while char == '"' do
        quoted = not quoted
        if full then -- Quotes only appended if we're doing a full tokenization
          cur = cur .. char
        end
        i = i + 1
        char = text:utfat(i)
      end
    else -- Normal character
      cur = cur .. char
      i = i + 1
    end
  end
  if #cur > 0 then -- EOS, make token
    ret[#ret + 1] = cur
    cur = ''
  end
  return ret -- Array of tokens
end

--- Converts an array of tokens into useful data
-- `tokens` is an array of tokens gotten from `Console.tokenize`
-- and `str` is if the tokens are the entire text, rather than true tokens
-- Format for return is a list of tables {val=value of token, hint=hint to append to token, type=type of the token, stat=status of the token}
function Console:test(tokens, str) 
  str = str or false
  local res = {}
  local obj = nil
  local spec = nil
  if #tokens ~= 0 then -- Only run when there are tokens, ofc
    local command = str and tokens[1]:trim() or tokens[1] -- if str, the tokens are not trimmed
    if command == '' then -- No command, we're done, empty input
      return {{val='', hint='', type=token_type.name, stat=correctness.missing}}
    elseif self.commands[command] then -- The command exists
      obj = self.commands[command]
      spec = obj.spec -- Fill spec with command
      res[#res + 1] = {val=tokens[1], hint='', type=token_type.name, stat=correctness.ok}
    else -- Figure out the name based on current input, to give hints
      local choices = {}
      for k, v in pairs(self.commands) do 
        if k:sub(1, #command) == command then 
          choices[#choices + 1] = k:sub(#command + 1) -- Add choices if they have the same substring
        end
      end
      if #choices == 0 then -- No choices found, erroneous command
        obj = {}
        spec = {}
        res[#res + 1] = {val=tokens[1], hint='', type=token_type.name, stat=correctness.error}
      else -- Some choices found
        table.sort(choices) -- Get the first alphabetically
        obj = self.commands[command .. choices[1]]
        spec = obj.spec -- This is the command we're going for, fill in the spec
        res[#res + 1] = {val=tokens[1], hint=choices[1], type=token_type.name, stat=correctness.missing} -- Missing instead of ok, since it's half-completed
      end
    end
  else
    return {{val='', hint='', type=token_type.name, stat=correctness.missing}} -- Literally nothing dudes
  end
  
  local i = 1
  while i <= #tokens-1 or i <= #spec do -- Hinting for other tokens, sans the name
    local token = tokens[i + 1]
    local cspec = spec[i]
    if cspec == nil then -- No spec, ergo too many arguments
      res[#res + 1] = {val=token, hint='', type=token_type.none, stat=correctness.error}
    else
      if token == nil then -- No token, we're not there yet. Add hint per type
        if cspec == param_types.string then 
          res[#res + 1] = {val='', hint='<string>', type=token_type.string, stat=correctness.hint_only}
        elseif cspec == param_types.number then 
          res[#res + 1] = {val='', hint='<number>', type=token_type.number, stat=correctness.hint_only}
        elseif cspec == param_types.text then
          res[#res + 1] = {val='', hint='<text>', type=token_type.string, stat=correctness.hint_only}
        elseif cspec == param_types.filename then
          res[#res + 1] = {val='', hint='<filename>', type=token_type.string, stat=correctness.hint_only}
        elseif type(cspec) == 'table' then -- Multiple choice
          res[#res + 1] = {val='', hint='<' .. table.concat(cspec, '|') .. '>', type=token_type.choice, stat=correctness.hint_only}
        else -- What even is this, god damn
          res[#res + 1] = last .. {val='', hint='<????>', type=token_type.none, stat=correctness.hint_only}
        end
      else -- Both spec AND token. For each type figure out what the hint is
        if cspec == param_types.string then -- Strings are a single word. Any is fine
          res[#res + 1] = {val=token, hint='', type=token_type.string, stat=correctness.ok}
        elseif cspec == param_types.number then -- Numbers have to be... well, a number
          local num = tonumber(token)
          if num == nil then 
            res[#res + 1] = {val=token, hint='', type=token_type.number, stat=correctness.error} -- NaN >:(
          else
            res[#res + 1] = {val=str and token or num, hint='', type=token_type.number, stat=correctness.ok} -- AN :D
          end
        elseif cspec == param_types.text then -- Literally any number of characters, maybe quoted even
          res[#res + 1] = {val=table.concat(tokens, str and '' or ' ', i+1), hint='', type=token_type.string, stat=correctness.ok}
          i = #tokens+1
        elseif cspec == param_types.filename then -- Oh fuck
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
          local fileInfo = love.filesystem.getInfo(path .. '/' .. file) -- Search the damn filesystem
          if fileInfo and token:utfat(-1) ~= '/' and token:utfat(-1) ~= '\\' then -- It exists, woo!
            res[#res + 1] = {val=token, hint=(fileInfo.type ~= 'file' and file:utfat(-1) ~= ' ' and i + 2 > #tokens) and '/' or '', type=token_type.choice, stat=correctness.ok}
          else -- It does not exist
            local files = love.filesystem.getDirectoryItems(path) -- Get all filenames in here yo
            if not files then -- No files ;-;
              res[#res + 1] = {val=token, hint='', type=token_type.choice, stat=correctness.error}
            else
              local choices = {}
              local t = str and file:trim() or file
              for k, v in ipairs(files) do 
                if #v > #t and v:sub(1, #t) == t then
                  choices[#choices + 1] = v:sub(#t + 1) -- For all files, find the choices that match the entered text already
                end
              end
              if #choices == 0 then -- You're wrong, and you know it
                res[#res + 1] = {val=token, hint='', type=token_type.choice, stat=correctness.error}
              elseif #choices == 1 then -- Exactly one choice, very cool
                fileInfo = love.filesystem.getInfo(token .. choices[1])
                res[#res + 1] = {val=token, hint=choices[1] .. (fileInfo.type ~= 'file' and '/' or ''), type=token_type.choice, stat=correctness.missing}
              else -- More than one choice
                table.sort(choices) -- Pick the first choice. Can be enhanced to find something better, but oh well
                fileInfo = love.filesystem.getInfo(token .. choices[1])
                res[#res + 1] = {val=token, hint=choices[1] .. (fileInfo.type ~= 'file' and '/' or ''), type=token_type.choice, stat=correctness.missing}
              end
            end
          end
        elseif type(cspec) == 'table' then -- Needs to be one of a set of choices
          local choices = {}
          local t = str and token:trim() or token
          for k, v in ipairs(cspec) do
            if v == t then 
              choices = {v:sub(#token + 1)} -- Check possible choices via substring
              break
            elseif #v > #token and v:sub(1, #token) == t then
              choices[#choices + 1] = v:sub(#token + 1)
            end
          end
          if #choices == 0 then -- Wrong, wrong, WRONG
            res[#res + 1] = {val=token, hint='', type=token_type.choice, stat=correctness.error}
          elseif #choices == 1 then -- Perfect
            res[#res + 1] = {val=token, hint=choices[1], type=token_type.choice, stat=#choices[1] > 0 and correctness.missing or correctness.ok}
          else -- Make choice, yes?
            table.sort(choices)
            res[#res + 1] = {val=token, hint=choices[1], type=token_type.choice, stat=correctness.missing}
          end
        else
          res[#res + 1] = last .. {val='', hint='<????>', type=token_type.none, stat=correctness.hint_only}
        end
      end
    end
    i = i + 1 -- Move on to next token/spec item
  end
  local endresult = nil -- Result of this parsing
  for k, v in ipairs(res) do 
    if not endresult then 
      endresult = v.stat -- Take latest if there's no endresult
    elseif v.stat == correctness.error then 
      endresult = correctness.error -- In case of any error, the end result is an error
    elseif v.stat == correctness.missing and endresult == correctness.ok then 
      endresult = correctness.missing -- If anything is missing, then the final result is missing
    end
  end
  res[1].stat = endresult
  return res -- Damn dude
end

--- Runs `text`
function Console:input(text)
  local tokens = Console.tokenize(text) -- True tokenization of the text, no need for showing it
  local res    = self:test(tokens) -- Test
  local name   = res[1]
  local has_error = false
  if name.stat == correctness.error then -- This does fuck-all
    if #res > 1 then 
      self:log("Error: Incorrect command parameters", command_error) -- RIP
      has_error = true
    else
      self:log("Error: Command " .. name.val .. " does not exist", command_error) -- RIP
      has_error = true
    end
  elseif name.stat == correctness.missing then 
    self:log("Error: Missing command parameters", command_error) -- RIP
    has_error = true
  else -- We're fine
    local cres
    cres, has_error = self.commands[name.val].func(res) -- Run command
    if cres and type(cres) == 'string' and #cres > 0 then
      if not has_error then -- It was fine
        self:log(cres)
      else
        self:failure(cres) -- Bad shit happened
      end
    end
  end
  self:updateHistory() -- Show result on console itself
  return not has_error
end

--- Updates history canvas and tables
function Console:updateHistory()
  local font = self._history:getFont()
  local height = font:getHeight()
  local allowed = math.floor(self.h / height) - 2

  local dlines = {}
  local ri = allowed
  for i=#self.history,1,-1 do -- Do wrapping for all the lines
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
    if dlines[i] then -- Add wrapped lines to canvas
      self._history:addf(dlines[i], self.w - 10, 'left', 5, (i - 1) * height + 5)
    end
  end
end

--- Converts text into formatted text with color for printing
-- `parts` is an array gotten from Console:test
-- `fulltext` is just the entire text
-- `textpos` is the position at which to render the text
function Console.formatted(parts, fulltext, textpos)
  local printout = {}
  local hadhint = false -- If there has already been a hint printed
  local hidden = textpos - 1
  for k, v in ipairs(parts) do
    local text = v.val -- Token's text
    if #text > 0 then -- Actual text, not just hint
      local textlen = utf8.len(text)
      local willtext = true -- Text will be shown
      if textlen < hidden then 
        hidden = hidden - textlen
        willtext = false
      elseif hidden ~= 0 then 
        text = text:utfsub(hidden + 1)
        hidden = 0
      end
      if willtext then 
        if v.type == token_type.string then -- Strings always in the same color
          printout[#printout + 1] = {1, 165/255, 0} -- Color
          printout[#printout + 1] = text -- Text
        else -- Set color first
          if v.stat == correctness.ok then
            printout[#printout + 1] = {0, 1, 0}
          elseif v.stat == correctness.missing then 
            printout[#printout + 1] = {1, 1, 0}
          else
            printout[#printout + 1] = {1, 0, 0}
          end
          printout[#printout + 1] = text -- Then text
        end
      end
    end
    local hint = v.hint 
    if #hint > 0 then -- If there is a hint
      if not hadhint then -- First hint, careful with the spaces
        hadhint = true 
        if (fulltext:utfat(-1) ~= ' ' and fulltext:utfat(-1) ~= '\t') and #v.val == 0 then 
          hint = ' ' .. hint
        end
      else  -- Not first hint, always spaces
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
        printout[#printout + 1] = {1, 1, 1, 0.75} -- Hint color
        printout[#printout + 1] = hint -- Hint text
      end
    end
  end
  return printout -- There we go
end

return Console