-- game/pause_state.lua
local utils = require 'utils.utils'
local input = require 'input.input'
local gui   = require 'gui.gui'
local game  = require 'game.game'

local PauseState = utils.make_class()

--- Shader
local shader_code = [[
  extern vec3 rand;
  extern number width;
  extern number height;
  extern Image prev;
  vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
  {      
    vec4 texturecolor = Texel(texture, texture_coords);
    
    vec3 col = vec3(0.0);
    
    for(int i = -1; i < 2; ++i) {
      for(int j = -1; j < 2; ++j) {
        vec3 pcol = Texel(prev, texture_coords + vec2(i / width, j / height)).rgb;
        col += vec3(pcol.r - 0.002 * rand.r, pcol.g - 0.002 * rand.g, pcol.b - 0.002 * rand.b);
      }
    }
    
    col /= 9.0;
    
    return vec4(vec3(min(col.r, texturecolor.r), min(col.g, texturecolor.g), min(col.b, texturecolor.b)), texturecolor.a);
  }
]] 

local debug_shader_code = [[
  //extern vec3 rand;
  extern number width;
  extern number height;
  extern Image MainTex;
  extern Image prev;
  void effect()
  {      
    vec4 texturecolor = Texel(MainTex, VaryingTexCoord.xy);
    
    vec3 col = vec3(0.0);
    
    for(int i = -1; i < 2; ++i) {
      for(int j = -1; j < 2; ++j) {
        vec3 pcol = Texel(prev, VaryingTexCoord.xy + vec2(i / width, j / height)).rgb;
        col += vec3(pcol.r - 0.001, pcol.g - 0.001, pcol.b - 0.001);
      }
    }
    
    col /= 9.0;
    
    love_Canvases[0] = vec4(vec3(min(col.r, texturecolor.r), min(col.g, texturecolor.g), min(col.b, texturecolor.b)), texturecolor.a);
    love_Canvases[1] = Texel(prev, VaryingTexCoord.xy);
  }
]]

local pause_shader = love.graphics.newShader(shader_code)

function PauseState:_init()
  self.prev_canvas = nil -- Previous canvas. Needed for fancy shader shenanigans
  self.canvas = love.graphics.newCanvas() -- Current canvas to draw on
  --self.canvas_debug = love.graphics.newCanvas()
  self.text = gui.Label(0, 0, 'PAUSED')
end

function PauseState:draw()
  if self.prev_canvas == nil then -- Set up canvas
    self.prev_canvas = love.graphics.newCanvas()
    --love.window.setMode(love.graphics.getWidth() * 2, love.graphics.getHeight())
    local c = love.graphics.getCanvas()
    love.graphics.setCanvas(self.prev_canvas)
      game.states[#game.states - 1]:draw()
    love.graphics.setCanvas(c)
    pause_shader:send('prev', self.prev_canvas)
    local w, h = self.prev_canvas:getPixelDimensions()
    pause_shader:send('width', w)
    pause_shader:send('height', h)
  end
  local rand = {math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1}
  pause_shader:send('rand', rand) -- Random number to randomize visuals
  local s = love.graphics.getShader()
  local c = love.graphics.getCanvas()
  love.graphics.setColor({1, 1, 1, 1})
  love.graphics.setCanvas(self.canvas)
    love.graphics.clear({0, 0, 0, 1})
    love.graphics.setShader(pause_shader)
    love.graphics.draw(self.prev_canvas) -- Draw previous canvas to canvas
    love.graphics.setColor({1, 1, 1, 1})
    love.graphics.setShader(s)
  love.graphics.setCanvas(self.prev_canvas)
    love.graphics.draw(self.canvas) -- And then draw the current canvas onto the old one
    pause_shader:send('prev', self.prev_canvas)
  love.graphics.setCanvas(self.canvas)
    self.text:draw()
  love.graphics.setCanvas(c)
  love.graphics.setColor({1, 1, 1, 1})
  love.graphics.draw(self.canvas)
  --love.graphics.draw(self.canvas_debug, 0, 0)
end

--- Update pause state. Simply unpauses when P is pressed
function PauseState:update(dt)
  if input.keyboard_press['p'] then
    --love.window.setMode(love.graphics.getWidth() / 2, love.graphics.getHeight())
    return true
  end
end

return PauseState