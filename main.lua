local Camera = require "hump.camera"
local Vector = require "hump.vector"

-- Player variables
local player = {
    x = 100,
    y = 400,
    speed = 400,
    width = 50,
    height = 100,
    yVelocity = 0,
    jumpVelocity = -600,
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
local throwPrimed = false
local throwVelocity = 700
local previewPoints = {}
local DeadZone = 0.1
local fullTiltThreshold = 0.9
local primedX = nil
local primedY = nil

-- Gamepad variables
local gamepad

function love.load()
    cam = Camera(player.x, player.y)
end

function love.joystickadded(joystick)
    gamepad = joystick -- Set the first detected gamepad as the controller
end

function love.joystickremoved(joystick)
    if joystick == gamepad then
        gamepad = nil -- Reset if the gamepad is disconnected
    end
end

function love.update(dt)
    if gamepad then
        -- Left stick controls movement
        local moveX = getAxis(gamepad, 1)
        player.x = player.x + moveX * player.speed * dt

        -- Jump with the A button (button 1 on most gamepads)
        if gamepad:isDown(1) and player.onGround then
            player.yVelocity = player.jumpVelocity
            player.onGround = false
        end

        -- -- Right stick controls aiming and throwing
        local aimX = getAxis(gamepad, 3)
        local aimY = getAxis(gamepad, 4)
        local magnitude = math.sqrt(aimX * aimX + aimY * aimY)

        -- Detect if joystick is tilted close to the edge
        if magnitude >= fullTiltThreshold then
            primedX = aimX
            primedY = aimY
            throwPrimed = true
            calculateArc(aimX, aimY)
        elseif magnitude < 0.1 and throwPrimed then
            throwPrimed = false
            throw(primedX, primedY)
        end
    else
        -- Fallback to keyboard movement if no gamepad is connected
        if love.keyboard.isDown("right") then
            player.x = player.x + player.speed * dt
        elseif love.keyboard.isDown("left") then
            player.x = player.x - player.speed * dt
        end
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

    -- Update camera to follow player
    cam:lookAt(player.x, player.y)

    -- Update balls (apply gravity to each one)
    for _, ball in ipairs(balls) do
        ball.yVelocity = ball.yVelocity + player.gravity * dt
        ball.x = ball.x + ball.xVelocity * dt
        ball.y = ball.y + ball.yVelocity * dt
    end
end

function throw(aimX, aimY)
    local direction = Vector(aimX, aimY):normalized()
    local ball = {
        x = player.x + player.width / 2,
        y = player.y + player.height / 2,
        xVelocity = direction.x * throwVelocity,
        yVelocity = direction.y * throwVelocity
    }
    table.insert(balls, ball)
end

function calculateArc(aimX, aimY)
    previewPoints = {}
    local direction = Vector(aimX, aimY):normalized()
    local initialXVel = direction.x * throwVelocity
    local initialYVel = direction.y * throwVelocity
    local previewTimeStep = 0.1

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

    -- Draw the player
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
    if throwPrimed then
        love.graphics.setColor(0, 1, 0)
        for i = 1, #previewPoints - 1 do
            local p1, p2 = previewPoints[i], previewPoints[i + 1]
            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
        end
    end

    -- Detach the camera for UI
    cam:detach()

    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Use left stick to move, right stick to aim and throw", 10, 20)
end

function getAxis(joystick, axis)
    local value = joystick:getAxis(axis)
    local sign = value < 0 and -1 or 1
    local DynamicRange = 1 - DeadZone
    value = math.min(1 - math.abs(value), DynamicRange)
    return sign * (1 - value / DynamicRange)
end
