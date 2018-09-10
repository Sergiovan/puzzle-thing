-- utils/animator.lua
local utils = require 'utils.utils'

local Animator = utils.make_class()

function Animator.valueChange(c, l)
  return {change = c, limit = l}
end

function Animator.fromToIn(f, t, i)
  return {change = (t - f) / i, limit = t}
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

  local function finish()
    if self.loop then 
      self:reset()
      self.started = true
    else
      self.finished = true
    end
  end

  self.elapsed = self.elapsed + dt
  local cchange = self.changes[self.step]

  if self.step % 2 == 0 then
    self.elapsed = self.elapsed + dt
    if self.elapsed >= cchange then 
      dt = dt - self.elapsed
      self.step = self.step + 1
      self.elapsed = 0
      if self.step > #self.changes then
        finish()
        if not self.loop then
          return
        end
      end
      cchange = self.changes[self.step]
    else
      return
    end
  end
  
  local count = 0
  local atlimit = 0
  for k, v in pairs(cchange) do
    count = count + 1
    if self.values[k] ~= v['limit'] then
      if v['change'] < 0 then
        self.values[k] = math.max(v['limit'], self.values[k] + v['change'] * dt)
      else
        self.values[k] = math.min(v['limit'], self.values[k] + v['change'] * dt)
      end
    else
      atlimit = atlimit + 1
    end
  end

  if atlimit == count then 
    self.step = self.step + 1
    self.elapsed = 0
    if self.step > #self.changes then
      finish()
      if not self.loop then
        return
      end
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

function Animator:reset()
  self.started = false
  self.stopped = false
  self.finished = false
  self.step = 1
  self.elapsed = 0
end

return Animator