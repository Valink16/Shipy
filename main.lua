function love.load()
  initMem = collectgarbage("count")
  debugSys = Debug()
  sys = PartSys()
  drawTime = 0
  updateTime = 0
  gameScale = love.graphics.getWidth() / 512-- Only need x scale because all the images will be squares
  useButtons = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
  print("OS: "..love.system.getOS().." : "..tostring(useButtons))
  -- CONSTANTS
    -- Ships
    ships = {
      -- player's ship
      {
        maxSpeed = 3,
        turnRate = 0.05
      }
    }

    bullets = {
      -- basic bullet
      {
        speed = 4
      }
    }


    local buttons = {
      Button(0, love.graphics.getHeight() - 64 * gameScale, 64, 64, "space"),
      Button(love.graphics.getWidth() - 192 * gameScale, love.graphics.getHeight() - 64 * gameScale, 64, 64, "left"),
      Button(love.graphics.getWidth() - 64 * gameScale, love.graphics.getHeight() - 64 * gameScale, 64, 64, "right"),
      Button(love.graphics.getWidth() - 128 * gameScale, love.graphics.getHeight() - 128 * gameScale, 64, 64, "up")
    }

    -- Metatables
      -- Vector
        m_Vector = {}
        m_Vector.__add = function(a, b)
          return Vector(a.x + b.x, a.y + b.y)
        end
        m_Vector.__sub = function(a, b)
          return Vector(a.x - b.x, a.y - b.y)
        end
        m_Vector.__mul = function(a, nb)
          return Vector(a.x * nb, a.y * nb)
        end
        m_Vector.__div = function(a, nb)
          return Vector(a.x / nb, a.y / nb)
        end
        m_Vector.__eq = function(a, b)
          return a.x == b.x and a.y == b.y
        end

    -- Images
      love.graphics.setDefaultFilter("nearest")
      images = {
        ships = {
          love.graphics.newImage("assets/ship1.png")
        },

        bullets = {
          love.graphics.newImage("assets/missile1.png")
        }
      }

    --for i=12, 360, 16 do
    --table.insert(sys.ships, Ship(240, i, 0, 1))
    --end
    table.insert(sys.ships, Ship(240, 160, 0, 1))
    love.window.setMode(1280, 720)
    love.graphics.setBackgroundColor(0, 0, 32, 0)
    sys.buttons = buttons

end

function Button(x, y, w, h, event)
  local button = {}
  button.x = x
  button.y = y
  button.w = w
  button.h = h
  button.pressed = false

  function button:touchIsIn(touchId)
    local x, y = love.touch.getPosition(touchId)
    if x < button.x or
       x > button.x + button.w or
       y < button.y or
       y > button.y + button.h then
      button.pressed = false
      return false
    else
      button.pressed = true
      return true
    end
  end

  function button:draw()
    if button.pressed then love.graphics.setColor(0, 0, 255, 255) end
    love.graphics.rectangle("fill", button.x, button.y, button.w * gameScale, button.h * gameScale)
  end

  return button
end

function Vector(vx, vy)
    local vector = {}
    vector.x = vx
    vector.y = vy

    function vector:length()
      return math.sqrt(vector.x * vector.x + vector.y * vector.y)
    end

    function vector:limit(limit)
      if vector.length() > limit then
        local d = vector.length() / limit
        vector.x = vector.x / d
        vector.y = vector.y / d
        print(d, vector.x, vector.y)
      end

    end

    setmetatable(vector, m_Vector)
    return vector
end


function Ship(x, y, r, id)
  local ship = {}
  ship.x = x or 0
  ship.y = y or 0
  ship.r = r or 0
  ship.id = id or 1

  ship.vel = Vector(0, 0)

  function ship:draw()
    love.graphics.draw(images.ships[ship.id], ship.x, ship.y, ship.r, gameScale, gameScale, 8, 8)
  end

  function ship:control()
    if love.keyboard.isDown("up") then ship.thrust() end
    if love.keyboard.isDown("left") then ship.r = ship.r - 0.1 end
    if love.keyboard.isDown("right") then ship.r = ship.r + 0.1 end
    if love.keyboard.isDown("space") then ship.shoot() end
  end

  function ship:update()
    ship.x = ship.x + ship.vel.x
    ship.y = ship.y + ship.vel.y
  end

  function ship:thrust()
    ship.vel = Vector(math.cos(ship.r), math.sin(ship.r)) / 10 + ship.vel
    ship.vel:limit(ships[ship.id].maxSpeed)
  end

  function ship:shoot()
    table.insert(sys.bullets, Bullet(ship.x, ship.y, Vector(math.cos(ship.r), math.sin(ship.r)), ship.r, 1))
  end

  function ship:debug()
    return "x: "..tostring(ship.x).." y: "..tostring(ship.y).." vx: "..tostring(ship.vel.x).." vy: "..tostring(ship.vel.y)
  end

  return ship
end

function Bullet(x, y, vel, r, id)
  local bullet = {}
  bullet.x = x
  bullet.y = y
  bullet.r = r
  bullet.id = id
  bullet.vel = vel * bullets[bullet.id].speed

  function bullet:update()
    bullet.x = bullet.x + bullet.vel.x
    bullet.y = bullet.y + bullet.vel.y
  end

  function bullet:draw()
    love.graphics.draw(images.bullets[bullet.id], bullet.x, bullet.y, bullet.r, gameScale, gameScale, 8, 8)
  end

  return bullet
end


function Debug()
  local debug = {}

  function debug:getMemUsage()
    return tostring(collectgarbage("count") - initMem).."KBs"
  end

  function debug:getFps()
    return love.timer.getFPS()
  end
  return debug
end

function PartSys() -- To manage every drawed object
  local sys = {}
  sys.ships = {}
  sys.bullets = {}
  sys.particles = {}
  sys.buttons = {}

  function sys:updateAll()
    sys.updateShips()
    sys.updateBullets()
    sys.updateParticles()
  end

  function sys:drawAll()
    sys.drawShips()
    sys.drawBullets()
    sys.drawParticles()
    if useButtons then sys.drawButtons() end
  end

  function sys:updateShips()
    for i, s in pairs(sys.ships) do
      s.update()
      s.control()
    end
  end

  function sys:updateBullets()
    for i, b in pairs(sys.bullets) do
      b.update()
    end
  end

  function sys:updateParticles()
    for i, p in pairs(sys.particles) do
      p.update()
    end
  end

  function sys:drawButtons()
    for i, b in pairs(sys.buttons) do
      b.draw()
    end
  end

  function sys:drawShips()
    for i, s in pairs(sys.ships) do
      s.draw()
    end
  end

  function sys:drawBullets()
    for i, b in pairs(sys.bullets) do
      b.draw()
    end
  end

  function sys:drawParticles()
    for i, p in pairs(sys.particles) do
      p.draw()
    end
  end
  return sys
end


function love.update(dt)
  updateTime = love.timer.getTime()
  -- Update objects
  sys.updateAll()

  -- Touch controls
  if useButtons then
    for i, id in pairs(love.touch.getTouches()) do
      for a, b in pairs(sys.buttons) do
        if b:touchIsIn(id) then
          love.event.push(b.event)
        end
      end
    end
  end

  updateTime = love.timer.getTime() - updateTime
end

function love.draw()
  oldDrawTime = love.timer.getTime()
  sys.drawAll()
  love.graphics.print(debugSys:getMemUsage(), 0, 0)
  love.graphics.print("dt: "..tostring(drawTime), 0, 12)
  love.graphics.print("ut: "..tostring(updateTime), 0, 24)
  love.graphics.print(love.timer.getFPS(), 0, 36)
  love.graphics.print(tostring(useButtons), 0, 48)
  drawTime = love.timer.getTime() - oldDrawTime
end
