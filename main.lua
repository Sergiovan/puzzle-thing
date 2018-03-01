package.path = package.path .. ';src/?.lua' -- To skip src folder when including
io.stdout:setvbuf("no") -- To get print statements to work properly

-- All requires here

State = require 'game.state.state'

function love.load(arg)
  current_state = {State()}
  love.mouse.setVisible(false)
  love.window.setTitle "Puzzle thing"
  mouse_img = love.graphics.newImage("img/cursor.png")
end

function love.update(dt)
  local change, new = current_state[1]:update(dt)
  if change then
    if new then
      current_state[#current_state+1] = new
    else
      table.remove(current_state, #current_state)
    end
  end
end

function love.draw()
  current_state[1]:draw()
  mx, my = love.mouse.getPosition()
  love.graphics.draw(mouse_img, mx-5, my-5)
end

function love.conf()
  t.console = true -- Remove later
end
