-- utils/animator.lua
local utils = require 'utils.utils'

local Animator = utils.make_class()

function Animator.fromToIn(f, t, i, a)
  local function linear(x)
    return x
  end

  local function cube(x)
    return x ^ 3
  end

  local function rcube(x)
    return (x - 1) ^ 3 + 1
  end

  local function fse(x)
    return (math.tan(x*2.5 - 1.25) + 3) / 6 -- ((tan((x*2.5-1.25))+3)/6
  end

  a = a or 'linear'
  selection = {linear = linear, cube = cube, rcube = rcube, fse = fse}
  local func = type(a) == 'string' and selection[a] or a

  return {from = f, diff = t - f, time = i, func = func}
end

function Animator:_init(values, changes, start, loop)
  self.values   = values
  self.changes  = changes

  self.step = 1
  self.elapsed = 0
  self.started = start or false
  self.loop = loop or false
  self.stopped = false
  self.finished = false
end

function Animator:update(dt)
  if self.finished or self.stopped or not self.started then 
    return 
  end

  self.elapsed = self.elapsed + dt

  local changes = self.changes[self.step]
  if type(changes) == 'number' then
    if self.elapsed > changes then
      self:skip(changes)
      return self:update(0) -- Tail call, yay
    end
  elseif type(changes) == 'function' then
    changes()
    self:skip(0)
    return self:update(0)
  else
    local count = 0
    local done = 0
    local maxelapsed = 0
    for k, v in pairs(changes) do
      count = count + 1
      local x = math.min(self.elapsed / v.time, 1)
      if x == 1 then
        done = done + 1
        maxelapsed = math.max(maxelapsed, v.time)
      end
      self.values[k] = v.from + v.diff * v.func(x)
    end

    if done == count then
      self:skip(maxelapsed)
      return self:update(0)
    end
  end
end

function Animator:start()
  if not self.finished then 
    self.started = true
    self.stopped = false
  end
end

function Animator:stop()
  if not self.finished then 
    self.stopped = true
  end
end

function Animator:terminate(forced)
  if not forced then
    for i=self.step,#self.changes do 
      local changes = self.changes[i]
      if type(changes) == 'function' then
        changes()
      elseif type(changes) == 'table' then
        for k, v in pairs(changes) do
          self.values[k] = v.from + v.diff
        end
      end
    end
  end
  self.finished = true
end

function Animator:reset()
  self.started = false
  self.stopped = false
  self.finished = false
  self.step = 1
  self.elapsed = elapsed or 0
end

function Animator:skip(elapsed, forced)
  forced = forced or false
  self.step = self.step + 1
  local nelapsed = not forced and self.elapsed - elapsed or 0
  if self.step > #self.changes then
    self:reset()
    if self.loop then 
      self.finished = false
      self.started = true
    else
      return
    end
  end
  self.elapsed = nelapsed
  local changes = self.changes[self.step]
  if type(changes) == 'table' then
    for k, v in pairs(changes) do 
      self.values[k] = v['from']
    end
  end
end

return Animator