local raylib = require('raylib')
local physac = require('physac')

local screenWidth = 800
local screenHeight = 450

raylib.SetConfigFlags( raylib.FLAG_MSAA_4X_HINT )
raylib.InitWindow(screenWidth, screenHeight, "Physac [raylib] - Physics demo");

-- Physac logo drawing position
local logoX = screenWidth - raylib.MeasureText("Physac", 30) - 10
local logoY = 15
local needsReset = false

physac.InitPhysics()
local floor = physac.CreatePhysicsBodyRectangleU( screenWidth/2, screenHeight/2, 500, 100, 10 )
floor:setEnabled( false )

local circle = physac.CreatePhysicsBodyCircleU( screenWidth/2, screenHeight/2, 45, 10 )
circle:setEnabled( false )

raylib.SetTargetFPS( 60 )

while not raylib.WindowShouldClose() do
	physac.RunPhysicsStep()

	if needsReset then
		floor = raylib.CreatePhysicsBodyRectangleU( screenWidth/2, screenHeight, 500, 100, 10 )
		floor:setEnabled( false )
		circle = raylib.CreatePhysicsBodyCircleU( screenWidth/2, screenHeight/2, 45, 10 )
		circle:setEnabled( false )
		needsReset = false
	end

	-- Reset physics input
	if raylib.IsKeyPressed( raylib.KEY_R ) then
		physac.ResetPhysics()
		needsReset = true
	end

	-- Physics body creation inputs
	if raylib.IsMouseButtonPressed( raylib.MOUSE_LEFT_BUTTON ) then
		raylib.CreatePhysicsBodyPolygon( raylib.GetMousePosition(), raylib.GetRandomValue(20, 80), raylib.GetRandomValue(3, 8), 10 )
	elseif raylib.IsMouseButtonPressed( raylib.MOUSE_RIGHT_BUTTON ) then
		raylib.CreatePhysicsBodyCircle( raylib.GetMousePosition(), raylib.GetRandomValue(10, 45), 10 )
	end

	-- Destroy falling physics bodies
	local bodiesCount = physac.GetPhysicsBodiesCount()
	for i = bodiesCount - 1, 0, -1 do
		local body = physac.GetPhysicsBody( i )
		print( body )
		if body:getPosition():getY() > screenHeight*2 then
			physac.DestroyPhysicsBody(body);
		end
	end

	raylib.BeginDrawing()
	do
		raylib.ClearBackgroundU( 0, 0, 0, 255 )
		raylib.DrawFPS( screenWidth - 90, screenHeight - 30 )

		-- Draw created physics bodies
		bodiesCount = physac.GetPhysicsBodiesCount()
		for i = 0, bodiesCount-1 do
			local body = physac.GetPhysicsBody( i )

			local vertexCount = physac.GetPhysicsShapeVerticesCount( i )
			for j = 0, vertexCount-1 do
				-- Get physics bodies shape vertices to draw lines
				-- Note: GetPhysicsShapeVertex() already calculates rotation transformations
				local vertexA = physac.GetPhysicsShapeVertex( body, j )

				local jj = (((j + 1) < vertexCount) and (j + 1) or 0)   -- Get next vertex or first to close the shape
				local vertexB = physac.GetPhysicsShapeVertex( body, jj )

				raylib.DrawLineV( vertexA, vertexB, raylib.Color(0,255,0,255))     -- Draw a line between two vertex positions
			end
		end

		raylib.DrawTextU( "Left mouse button to create a polygon", 10, 10, 10, 255, 255, 255, 255 )
		raylib.DrawTextU( "Right mouse button to create a circle", 10, 25, 10, 255, 255, 255, 255 )
		raylib.DrawTextU( "Press 'R' to reset example", 10, 40, 10, 255, 255, 255, 255 )
		raylib.DrawTextU( "Physac", logoX, logoY, 30, 255, 255, 255, 255 )
		raylib.DrawTextU( "Powered by", logoX + 50, logoY - 7, 10, 255, 255, 255, 255 )
	end
	raylib.EndDrawing()
end
