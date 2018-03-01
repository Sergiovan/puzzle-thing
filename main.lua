package.path = package.path .. ';src/?.lua'
State = require 'game.state'
Cell = require 'game.cell'

function love.load(arg)
  current_state = {State()}
  cell = Cell()
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
  cell:draw(4, 20) -- Blaze it
end

print("Hello, Löve")
