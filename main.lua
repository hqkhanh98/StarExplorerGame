-----------------------------------------------------------------------------------------
-- Star Explorer Game 
-- Project : Chapter 2
-- Name file : main.lua
-- Author : Huynh Quoc Khanh
-- Reason create : learn Lua scripts
-- Date : 01/06/2019 (dd/mm/YYYY)
-- Version : v0.1
-- Update version : none
-- Date update : none
-- Reason update : none
-----------------------------------------------------------------------------------------

-- Initialize variables
local lives = 3
local score = 0
local died = false

local asteroidsTable = {}

local ship
local gameLoopTimer
local livesText
local scoreText

-- Set physical
local physics = require("physics")
physics.start()
physics.setGravity(0,0) -- none gravity because in the space galaxy

-- Seed the random number generator
math.randomseed( os.time() )

-- Configure image sheet
local sheetOptions = 
{
	frames = 
	{
		{	-- Obj asteroid 1
			x = 0,
			y = 0,
			width = 102,
			height = 85
		},
		{	-- Obj asteroid 2
			x = 0,
			y = 0,
			width = 90,
			height = 83
		},
		{	-- Obj asteroid 3
			x = 0,
			y = 0,
			width = 100,
			height = 97
		},
		{	-- Obj ship 
			x = 0,
			y = 265,
			width = 98,
			height = 79
		},
		{	-- Obj laser
			x = 98,
			y = 265,
			width = 14,
			height = 40
		},
	},
}
-- Sheet of frames
local  objSheet = graphics.newImageSheet("Asset/gameObjects.png", sheetOptions)

-- Set up display groups
local backGroup = display.newGroup() -- Display group for the background image
local mainGroup = display.newGroup() -- Display group for the ship, asteroids, lasers, etc..
local uiGroup = display.newGroup() -- Display group for user interface objects like the score

-- Load the background in backGroup
local background = display.newImageRect( backGroup, "Asset/background.png", 800, 1400)
background.x = display.contentCenterX
background.y = display.contentCenterY

-- Load the ship in mainGroup
ship = display.newImageRect( mainGroup, objSheet, 4, 98, 79) -- obj at frame[4]
ship.x = display.contentCenterX
ship.y = display.contentHeight - 100

physics.addBody( ship, { radius = 30, isSensor = true } ) -- Add physics to ship
-- radius is the box around the ship
-- isSensor is enable detect collision with another objects but it's not produce a physical response
ship.myName = "ship" -- name use to determined type collision

-- Display label lives and label score
livesText = display.newText( uiGroup, "Lives: " .. lives, 192, 80, native.systemFont, 36 )
scoreText = display.newText( uiGroup, "Scores: " .. score, 576, 80, native.systemFont, 36 )

-- Hide the status bar if exist
display.setStatusBar( display.HiddenStatusBar )

local function updateText()
	livesText.text = "Lives: " .. lives -- Set text for label lives
	scoreText.text = "Scores: " .. score -- Set text for label score
end -- End updateText function 

local function createAsteroid()
	-- Load the asteroid in mainGroup
	local newAsteroid = display.newImageRect( mainGroup, objSheet, 1, 102, 85 ) -- obj at frame[1]
	table.insert( asteroidsTable, newAsteroid ) -- Insert asteroid into asteroidsTable
	physics.addBody( newAsteroid, "dynamic", { radius = 40, bounce = 0.8 } ) -- Add physics to ship
	-- dynamic is mode that obj to be affected by gravity and physical
	newAsteroid.myName = "asteroid" -- name use to determined type collision

	local pointAsteroid = math.random( 3 ) -- Random to 1,2,3

	if ( pointAsteroid == 1 ) then -- From the left screen
		newAsteroid.x = -60
		newAsteroid.y = math.random( 500 ) -- Random y
		newAsteroid:setLinearVelocity( math.random( 40, 120 ), math.random( 20, 60 ) )
	elseif ( pointAsteroid == 2 ) then -- From the top screen
		newAsteroid.x = math.random( display.contentWidth )
		newAsteroid.y = -60
		newAsteroid:setLinearVelocity( math.random( -40, 40 ), math.random( 40, 120 ) )
	elseif ( pointAsteroid == 3 ) then -- From the right screen
		newAsteroid.x = display.contentWidth + 60
		newAsteroid.y = math.random( 500 )
		newAsteroid:setLinearVelocity( math.random( -120, -40 ), math.random( 20, 60 ) )
	end -- End pointAsteroid

	newAsteroid:applyTorque( math.random( -6, 6 ) ) -- rotational force
end -- End createAsteroid function

local function fireLaser()
	local newLaser = display.newImageRect( mainGroup, objSheet, 5, 14, 40 ) -- obj at frame[5]
	physics.addBody( newLaser, "dynamic", { isSensor = true } )
	newLaser.isBullet = true
	-- this will help ensure that it doesn't "pass through" any asteroids without registering a collision.
	newLaser.myName = "laser"
	-- Set position laser = position ship
	newLaser.x = ship.x
	newLaser.y = ship.y
	newLaser:toBack() -- Set laser to back ship ( in mainGroup )
	-- Move laser (1s = 1000time)
	transition.to( newLaser, { y = -40, time = 500, 
		onComplete = function() display.remove( newLaser ) end -- remove obj if done
	} )
end -- End fireLaser function

ship:addEventListener( "tap", fireLaser ) -- action fire

local function dragShip( event )

	local ship = event.target
	local check = event.phase

	if ( "began" == check ) then
		display.currentStage:setFocus( ship ) -- Set touch focus on the ship
		ship.touchOffsetX = event.x - ship.x -- Store initial offset position

	elseif ( "moved" == check ) then
		-- Move the ship to the new touch position
		ship.x = event.x - ship.touchOffsetX
	
	elseif ( "ended" == check or "cancelled" == check ) then
		-- Release touch focus on the ship
		display.currentStage:setFocus( nil )
	end -- End if check
	return true -- Prevents touch propagation to underlying objects
end -- End function

ship:addEventListener( "touch", dragShip )

local function gameLoop()
	
	-- Create new asteroid
	createAsteroid()
	-- Remove asteroids which have drifted off screen
	for i = #asteroidsTable, 1, -1 do
		local  thisAsteroid = asteroidsTable[i] -- Current asteroid

		if ( thisAsteroid.x < -100 or
			 thisAsteroid.x > display.contentWidth + 100 or
			 thisAsteroid.y < -100 or
			 thisAsteroid.y > display.contentHeight + 100 )
		then
			display.remove( thisAsteroid )
			table.remove( asteroidsTable, i )
		end -- End if remove
	end -- End for 
end -- End gameLoop function

gameLoopTimer = timer.performWithDelay( 500, gameLoop, 0 )


local function restoreShip()
	
	ship.isBodyActive = false -- Inactive ship
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100

	-- Fade in the ship 
	transition.to( ship, { alpha = 1, time = 4000,
		onComplete = function ()
			ship.isBodyActive = true
			died = false
		end -- End function
	} )
end -- End restoreShip function

local function onCollision( event )
	if ( event.phase == "began" ) then
		
		local obj1 = event.object1
		local obj2 = event.object2

		if( ( obj1.myName == "laser" and obj2.myName == "asteroid" ) or
			( obj1.myName == "asteroid" and obj2.myName == "laser" ) )
		then
			-- Remove both the laser and asteroid
			display.remove( obj1 )
			display.remove( obj2 )

			for i = #asteroidsTable, 1, -1 do
				if( asteroidsTable[i] == obj1 or asteroidsTable[i] == obj2 ) then
					table.remove( asteroidsTable, i )
					break
				end-- end of asteroidsTable remove
			end -- end of for 

			-- Increase score
			score = score + 100
			scoreText.text = "Score: " .. score

		elseif( ( obj1.myName == "ship" and obj2.myName == "asteroid" ) or
				( obj1.myName == "asteroid" and obj2.myName == "ship" ) ) 
			then
				if ( died == false ) then
					died = true

					-- Update lives
					lives = lives - 1
					livesText.text = "Lives: " .. lives

					if ( lives == 0 ) then
						display.remove( ship )
					else
						ship.alpha = 0
						timer.performWithDelay( 1000, restoreShip )
					end -- end of if lives
				end -- end of if died
				
		end -- end of obj name 
	end -- end of check event
end -- end of function

Runtime:addEventListener( "collision", onCollision )