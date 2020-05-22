--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

-- We need to create a few class fields to handle showing the powerups
local powerupTimer = 0              -- Set the timer to 0
local showPowerup = 10              -- Set the length of the timer
local switchPowerup = true          -- Toggle between the two powerups (true - split ball; false - key)
local lockedBrickExists = false     -- Set the intial flag for whether a locked brick exists

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    
    -- Add an entry for whether a locked brick exists by checking every brick
    for i, brick in pairs(self.bricks) do
        if brick.isLocked then
            lockedBrickExists = true
        end
    end
    
    -- Change the ball to a table of balls since more than one can be in play
    -- This goes for every case in the code below wherever self.ball is referenced
    self.balls = {params.ball}
    
    self.level = params.level

    self.recoverPoints = params.recoverPoints

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)
    
    -- Since the instructions only state the need to include the split
    -- ball powerup and the key to unlock a locked brick, I've decided 
    -- to use a toggle between the two and so I will assign both to a
    -- Powerup object with the appropriate type now
    self.powerupSplitBall = Powerup(9)
    self.powerupBrickKey = Powerup(10)
    
    
end

function PlayState:update(dt)

    -- Update the timer
    powerupTimer = powerupTimer + dt
    
    -- Once the timer hits the show threshold, then add the powerup
    if powerupTimer >= showPowerup then
        
        -- Alternate between dropping the split ball powerup and the key unless the key
        -- is already possessed, then only display the split ball powerup
        if switchPowerup == false then
            if self.paddle.hasBrickKey == false and lockedBrickExists then
                self.powerupBrickKey.inPlay = true
            else
                self.powerupSplitBall.inPlay = true
            end
        else
            self.powerupSplitBall.inPlay = true
        end
        
        -- Toggle the powerup to the next one
        switchPowerup = not switchPowerup
        
        -- Reset the timer
        powerupTimer = 0
    end
    
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    
    -- Since we may have multiple balls, cycle through them all and update
    for i, ball in pairs(self.balls) do
        ball:update(dt)
    end
    
    -- Update the power and the key
    self.powerupSplitBall:update(dt)
    self.powerupBrickKey:update(dt)
    
    -- Code for if the powerup is collected by the paddle
    if self.powerupSplitBall:collides(self.paddle) then
        gSounds['powerup-collect']:play()
        self.powerupSplitBall:reset()
        
        -- Insert two additional balls originating from the center of the paddle
        table.insert( self.balls, Ball(math.random(7)))
        self.balls[#self.balls]:addBall(self.paddle.x + self.paddle.width / 2, self.paddle.y)
        
        table.insert( self.balls, Ball(math.random(7)))
        self.balls[#self.balls]:addBall(self.paddle.x + self.paddle.width / 2, self.paddle.y)
    end
    
    -- Code for if the key is collected by the paddle
    if self.powerupBrickKey:collides(self.paddle) then
        gSounds['powerup-collect']:play()
        self.powerupBrickKey:reset()
        self.paddle.hasBrickKey = true
    end
    
    -- Update ball collision to account for multiple balls
    for i, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end
    
    -- Updated the code for multiple balls hitting bricks
    -- detect collision across all bricks with the balls
    for i, ball in pairs(self.balls) do    
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- To update the score, first check to see if the brick is locked
                if brick.isLocked then
                
                    -- If it is locked, is the brick key possessed?
                    if self.paddle.hasBrickKey then
                    
                        -- Play the new locked brick explosion
                        gSounds['locked-brick-explode']:play()
                    
                        -- If so then add the score
                        self.score = self.score + 2000
                        
                        -- Take the brick out of play
                        brick:hit()
                        brick.inPlay = false
                        
                        -- Reset the powerupBrickKey boolean
                        lockedBrickExists = false
                        
                    else
                        -- Play the sound for hitting a locked brick
                        gSounds['brick-hit-lock']:play()
                    end
                else
                    
                    -- If the brick is normal, just add the score and take it out of play
                    brick:hit()
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                end

                -- Added code to account for the paddle getting bigger
                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)
                    
                    -- Increase paddle size if possible
                    self.paddle.size = math.min(self.paddle.size + 1, 4)
                    self.paddle.width = self.paddle.size * 32

                    -- Add 20,000 points to the recoverPoints to set the next level
                    self.recoverPoints = math.min(1000000, self.recoverPoints + 20000)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end
                
                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()
                    
                    -- Reset the hasBrickKey boolean 
                    self.paddle.hasBrickKey = false

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        
                        -- If the game is won, this means that there is at least one
                        -- ball still in play so just pass the first ball 
                        ball = self.balls[1],
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- Updated the code to account for multiple balls
    -- if ball goes below bounds, revert to serve state and decrease health
    for i, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
        
            -- First remove the ball
            ball.remove = true
            
            -- Now check to see if it was the last ball
            if #self.balls == 1 then
                self.health = self.health - 1
                gSounds['hurt']:play()
                
                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    -- Decrease the size of the paddle if possible
                    self.paddle.size = math.max(1, self.paddle.size - 1)
                    self.paddle.width = self.paddle.size * 32
                    
                    -- Reset the hasBrickKey boolean
                    self.paddle.hasBrickKey = false
                    lockedBrickExists = false
                    
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints,
                    
                        -- Add the indicator of a locked brick
                        isLocked = self.isLocked
                    })
                end
            end
        end
    end
    
    -- Remove a ball if necessary
    for k, ball in pairs(self.balls) do
        if ball.remove then
            table.remove(self.balls, k)
        end
    end
    
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
    
    
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    
    -- Render the icon for the key in the bottom right corner if 
    -- the key powerup has been collected and a locked brick exists
    if self.paddle.hasBrickKey and lockedBrickExists then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][10], VIRTUAL_WIDTH - 20, VIRTUAL_HEIGHT - 20)
    end
    
    -- Cycle through all balls and render each
    for i, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    
    --Render the split ball or the key
    self.powerupSplitBall:render()
    self.powerupBrickKey:render()
    
    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end