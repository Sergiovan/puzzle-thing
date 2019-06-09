-- utils/animator.lua
local utils = require 'utils.utils'

local Animator = utils.make_class()

--- Returns a table with animation data
-- `f` is the value at which the animation starts
-- `t` is the value at which it should end
-- `i` is the time it needs to take in seconds
-- `a` is the name of the function to use, or a custom animation function
-- taking a single parameter, a number in [0,1] that represents
-- how far along the animation is
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
  selection = {linear = linear, cube = cube, rcube = rcube, fse = fse} -- Functions by name, yo
  local func = type(a) == 'string' and selection[a] or a

  -- from = begin value
  -- diff = difference between begin and end values
  -- time = seconds
  -- func = function to run
  return {from = f, diff = t - f, time = i, func = func}
end

--- Kinda self-evident
function Animator:_init(values, changes, start, loop)
  self.values   = values -- Object in which to change values
  self.changes  = changes -- Table of {element: animation data} for members of self.values, or functions or numbers

  self.step = 1 -- Step of the animation
  self.elapsed = 0 -- How long the animation has taken
  self.started = start or false -- If the animation is running
  self.loop = loop or false -- If the animation should loop
  self.stopped = false -- If the animation has been stopped
  self.finished = false -- If the animation has ended
end

--- Updates the animation status. `dt` is delta time since last call
function Animator:update(dt)
  if self.finished or self.stopped or not self.started then 
    return -- Do nothing if stopped, ended or not started
  end

  self.elapsed = self.elapsed + dt

  local changes = self.changes[self.step] -- Load current step
  if type(changes) == 'number' then -- Number indicates a wait
    if self.elapsed > changes then -- If we've waited until x time has passed, continue
      self:skip(changes)
      return self:update(0) -- Tail call, yay
    end
  elseif type(changes) == 'function' then -- Call function, then move on to next step
    changes()
    self:skip(0)
    return self:update(0)
  else -- Actual animation data
    local count = 0
    local done = 0
    local maxelapsed = 0
    for k, v in pairs(changes) do
      count = count + 1
      local x = math.min(self.elapsed / v.time, 1) -- Calculate x for function
      if x == 1 then -- We're done!
        done = done + 1
        maxelapsed = math.max(maxelapsed, v.time)
      end
      self.values[k] = v.from + v.diff * v.func(x) -- Update value
    end

    if done == count then -- All animations done
      self:skip(maxelapsed) -- Skip to next
      return self:update(0)
    end
  end
end

--- Begins the animation
function Animator:start()
  if not self.finished then 
    self.started = true
    self.stopped = false
  end
end

--- Pauses the animation
function Animator:stop()
  if not self.finished then 
    self.stopped = true
  end
end

--- Ends the animation. If `forced` is false,
-- all animation steps complete, else the animation is simply
-- stopped as-is
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

--- Resets the whole animation
function Animator:reset()
  self.started = false
  self.stopped = false
  self.finished = false
  self.step = 1
  self.elapsed = elapsed or 0
end

--- Skips to the next animation step. Ends the animation when at the end
-- `elapsed` is the extra time elapsed past the previous step
-- If `forced` is true the step will be skipped to the end forcibly
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