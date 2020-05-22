--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Lonnie Elrod Jr.
    elrodl@tncc.edu or lonnie.elrod@as.edu
    
    Modeled from the Ball.lua file

    Represents a powerup which will either split the ball into two additional
    balls or unlocks a brick that is locked.
]]

Powerup = Class{}

-- Single parameter which is the powerup type
function Powerup:init(powerType)
    -- simple positional and dimensional variables
    self.width = 16
    self.height = 16

    -- this variable is for keeping track of our velocity on the
    -- Y axis since the powerup can only move downward
    self.dy = 60
        
    -- The x and y values will be random using a 20 unit cushion on the
    -- top, left, and right sides and at least 1/3 of the height for the
    -- bottom
    self.x = math.random(20, VIRTUAL_WIDTH - 20)
    self.y = math.random(20, VIRTUAL_HEIGHT / 3)

    -- this is a toggle representing whether a powerup is in play
    self.inPlay = false
    
    -- Set the type of powerup to the parameter value passed to the function
    self.type = powerType
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Resets the powerup properties to their initial settings.
]]
function Powerup:reset()
    self.x = math.random(20, VIRTUAL_WIDTH - 20)
    self.y = math.random(20, VIRTUAL_HEIGHT / 3)
    self.dy = 60
    self.inPlay = false
end

function Powerup:update(dt)
    -- Only update if the powerup is in play by checking the 
    -- inPlay field value
    if self.inPlay then
        self.y = self.y + self.dy * dt
    end

    -- If the powerup goes beyond the bottom (meaning it was not
    -- collected) reset the powerup
    if self.y > VIRTUAL_HEIGHT + self.width then
        self:reset()
    end
    
end

function Powerup:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual powerup skin in the texture
    if self.inPlay == true then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type],
            self.x, self.y)
    end
end