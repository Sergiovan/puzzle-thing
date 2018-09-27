-- input/input.lua
local utils = require 'utils.utils'

local InputControl = utils.make_class()

function InputControl:_init()
  self.mouse_position   = {love.mouse.getPosition()} -- Current mouse position
  self.mouse_movement   = {0, 0} -- Mouse movement since last update
  self.mouse_press_pos  = {{0, 0}, {0, 0}, {0, 0}} -- Where the mouse was when clicked for dragging
  self.mouse_down       = {false, false, false} -- Mouse buttons current down
  self.mouse_press      = {false, false, false} -- If the mouse was clicked this update
  self.mouse_release    = {false, false, false} -- If the mouse was released this update

  -- self.text_enabled    = false -- Enable storing of keyboard text input
  self.text_input       = "" -- Text input since last update
  self.keyboard_down    = {} -- Keys that are pressed right now
  self.keyboard_press   = {} -- Keys that were pressed this update
  self.keyboard_release = {} -- Keys that were released this update
  
  self.mouse_moved  = false
  self.key_pressed  = false
  self.key_released = false
end

function InputControl:update(dt)
  local mx, my = love.mouse.getPosition()
  self.mouse_movement[1] = mx - self.mouse_position[1]
  self.mouse_movement[2] = my - self.mouse_position[2]
  self.mouse_position[1] = mx
  self.mouse_position[2] = my
  if self.mouse_movement[1] ~= 0 or self.mouse_movement[2] ~= 0 then
    self.mouse_moved = true
  else
    self.mouse_moved = false
  end
end

function InputControl:clear(dt)
  for k=1,3 do
    self.mouse_press[k] = false
    self.mouse_release[k] = false
  end
  
  for k in pairs(self.keyboard_press) do
    self.keyboard_press[k] = false
  end
  
  for k in pairs(self.keyboard_release) do
    self.keyboard_press[k] = false
  end
  
  self.text_input = ""
  self.key_pressed  = false
  self.key_released = false
end

function InputControl:mouse_button(button, x, y, press)
  -- Note: Button should be in the range 1:3
  if press then
    self.mouse_press[button] = true
  else
    self.mouse_release[button] = true
  end
  self.mouse_down[button] = press
  local c = press and self.mouse_press or self.mouse_release
  c[button] = true
  self.mouse_press_pos[button][1] = press and x or 0
  self.mouse_press_pos[button][2] = press and y or 0
end

function InputControl:keyboard_button(keycode, press)
  self.keyboard_down[keycode] = press
  local c = press and self.keyboard_press or self.keyboard_release
  c[keycode] = true
  if press then
    self.key_pressed = true
  else
    self.key_released = true
  end
end

function InputControl:add_text_input(text)
  -- if self.text_enabled then
  self.text_input = self.text_input .. text -- OPT
  -- end
end

function InputControl:get_mouse_position()
  return unpack(self.mouse_position)
end

local input = InputControl()

return input