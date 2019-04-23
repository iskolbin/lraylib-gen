local r = require('raylib')
local screenWidth, screenHeight = 800, 450
r.InitWindow(screenWidth, screenHeight, "raylib [models] example - obj model loading")

local camera = r.Camera3D()
:setPositionU(8,8,8)
:setTargetU(0,2.5,0)
:setUpU(0,1,0)
:setFovy(45)
:setType(r.CAMERA_PERSPECTIVE)

local model = r.LoadModel('raylib/examples/models/resources/models/castle.obj')
local texture = r.LoadTexture('raylib/examples/models/resources/models/castle_diffuse.png')

local material = model:getMaterialAt(0)
local materialMap = material:getMapAt(r.MAP_ALBEDO)
materialMap:setTexture(texture)
material:setMapAt(r.MAP_ALBEDO,materialMap)
model:setMaterialAt(0,material)

r.SetCameraMode(camera, r.CAMERA_FIRST_PERSON)

r.SetTargetFPS(60)
while not r.WindowShouldClose() do
	r.UpdateCamera(camera)
	r.BeginDrawing()
	do
		r.ClearBackgroundU(192,192,192,255)
		r.BeginMode3D(camera)
		do
			r.DrawModelU(model,  0, 0, 0,  0.2,  255, 255, 255, 255)
			r.DrawGrid(10, 1)
			r.DrawGizmoU(0, 0, 0)
		end
		r.EndMode3D()
		r.DrawTextU("(c) Castle 3D model by Alberto Cano", screenWidth - 200, screenHeight - 20, 10,  160,160,160,160)
		r.DrawFPS(10, 10)
	end
	r.EndDrawing()
end

r.UnloadTexture(texture)
r.UnloadModel(model)
r.CloseWindow()
