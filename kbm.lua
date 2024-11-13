local Camera = require "hump.camera"
local Vector = require "hump.vector" -- We’ll use vectors to manage directions

-- Player variables
local player = {
    x = 100,
    y = 400,
    speed = 200,
    width = 50,
    height = 100,
    yVelocity = 0,
    jumpVelocity = -400,
    gravity = 800,
    onGround = false
}

-- Ground variables
local ground = {
    x = 0,
    y = 500,
    width = 2000,
    height = 100
}

-- Camera variable
local cam

-- Ball variables
local balls = {}
local throwCharge = false
local throwVelocity = 700 -- Initial speed of the ball
local previewPoints = {}

function love.load()
    cam = Camera(player.x, player.y)
end

function love.update(dt)
    -- Player controls (left and right)
    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    elseif love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end

    -- Gravity for the player
    if not player.onGround then
        player.yVelocity = player.yVelocity + player.gravity * dt
    else
        player.yVelocity = 0
    end
    player.y = player.y + player.yVelocity * dt

    -- Check collision with ground
    if player.y + player.height > ground.y then
        player.y = ground.y - player.height
        player.onGround = true
    else
        player.onGround = false
    end

    -- Jumping
    if love.keyboard.isDown("space") and player.onGround then
        player.yVelocity = player.jumpVelocity
        player.onGround = false
    end

    -- Update camera to follow player
    cam:lookAt(player.x, player.y)

    -- Calculate the throw arc while holding the mouse button
    if love.mouse.isDown(1) then
        throwCharge = true
        calculateThrowArc()
    end

    -- Update balls (apply gravity to each one)
    for i, ball in ipairs(balls) do
        ball.yVelocity = ball.yVelocity + player.gravity * dt
        ball.x = ball.x + ball.xVelocity * dt
        ball.y = ball.y + ball.yVelocity * dt
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        throwCharge = true -- Start charging throw
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and throwCharge then
        throwCharge = false
        throwBall()
    end
end

function throwBall()
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = cam:worldCoords(mouseX, mouseY)

    -- Calculate direction vector towards the mouse
    local direction = Vector(mouseX - player.x, mouseY - player.y):normalized()
    local ball = {
        x = player.x + player.width / 2,
        y = player.y + player.height / 2,
        xVelocity = direction.x * throwVelocity,
        yVelocity = direction.y * throwVelocity
    }
    table.insert(balls, ball)
end

function calculateThrowArc()
    previewPoints = {}
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = cam:worldCoords(mouseX, mouseY)

    local direction = Vector(mouseX - player.x, mouseY - player.y):normalized()
    local initialXVel = direction.x * throwVelocity
    local initialYVel = direction.y * throwVelocity
    local previewTimeStep = 0.1 -- Time steps for the preview

    for i = 1, 20 do
        local t = i * previewTimeStep
        local x = player.x + player.width / 2 + initialXVel * t
        local y = player.y + player.height / 2 + initialYVel * t + 0.5 * player.gravity * t * t
        table.insert(previewPoints, { x = x, y = y })
    end
end

function love.draw()
    -- Attach the camera
    cam:attach()

    -- Draw the player (simple rectangle for now)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    -- Draw the ground
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("fill", ground.x, ground.y, ground.width, ground.height)

    -- Draw balls
    love.graphics.setColor(0, 0, 1)
    for _, ball in ipairs(balls) do
        love.graphics.circle("fill", ball.x, ball.y, 10)
    end

    -- Draw the preview arc if charging
    if throwCharge then
        love.graphics.setColor(0, 1, 0)
        for i = 1, #previewPoints - 1 do
            local p1, p2 = previewPoints[i], previewPoints[i + 1]
            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
        end
    end

    -- Detach the camera for UI elements
    cam:detach()

    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Arrow keys to move, space to jump, hold left click to aim, release to throw", 10, 10)
end
