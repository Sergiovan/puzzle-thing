package.path = package.path .. ';src/?.lua' -- To skip src folder when including
io.stdout:setvbuf("no") -- To get print statements to work properly

-- All requires here

local State = require 'game.state.state'
local input = require 'input.input'
local gui   = require 'gui.gui'

local love = love

function love.load(arg)
  current_state = {State()}
  current_state[1].gui[1] = gui.Label(0, 0, "Fancy")
  love.mouse.setVisible(false)
  love.window.setTitle "Puzzle thing"
  mouse_img = love.graphics.newImage "img/cursor.png"
end

function love.update(dt)
  input:update(dt)
  local change, new = current_state[1]:update(dt)
  if change then
    if new then
      current_state[#current_state+1] = new
    else
      table.remove(current_state, #current_state)
    end
  end
  input:clear(dt)
end

function love.draw()
  current_state[1]:draw(0, 0)
  local mx, my = input:get_mouse_position()
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(mouse_img, mx-5, my-5)

  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, love.graphics.getHeight() - 15)
end

function love.keypressed(key, scancode, isrepeat)
  input:keyboard_button(scancode, true)
end

function love.keyreleased(key, scancode)
  input:keyboard_button(scancode, false)
end

function love.textinput(text)
  input:add_text_input(text)
end

function love.mousepressed(x, y, button, istouch)
  if button >=1 and button <= 3 then
    input:mouse_button(button, x, y, true)
  end
end

function love.mousereleased(x, y, button, istouch)
  if button >=1 and button <= 3 then
    input:mouse_button(button, x, y, false)
  end
end

function love.focus(focus)
  -- TODO
end

function love.mousefocus(focus)
  -- TODO?
end

function love.conf(t)
  t.console = true -- Remove later
end

function love.resize(w, h)
  -- TODO?
end

-- function love.errhand(msg)
  -- TODO
-- end

function love.quit()
  -- TODO
end