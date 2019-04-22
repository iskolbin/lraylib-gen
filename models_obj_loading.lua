local r = require('raylib')
local screenWidth, screenHeight = 800, 450
r.InitWindow(screenWidth, screenHeight, "raylib [models] example - obj model loading")

local camera = r.Camera3D()
camera:setPosition(r.Vector3(8,8,8))
camera:setTarget(r.Vector3(0,2.5,0))
camera:setUp(r.Vector3(0,1,0))
camera:setFovy(45)
camera:setType(r.CAMERA_PERSPECTIVE)

local model = r.LoadModel('raylib/examples/models/resources/models/castle.obj')
local texture = r.LoadTexture('raylib/examples/models/resources/models/castle_diffuse.png')
local material = model:getMaterials(0)
local materialMap = material:getMaps(r.MAP_ALBEDO)
materialMap:setTexture(texture)
material:setMaps(r.MAP_ALBEDO,materialMap)
model:setMaterials(0,material)

local position = r.Vector3(0,0,0)

r.SetCameraMode(camera, r.CAMERA_FIRST_PERSON)

r.SetTargetFPS(60)
while not r.WindowShouldClose() do
	r.UpdateCamera(camera)
	r.BeginDrawing()
	do
		r.ClearBackground(r.Color(192,192,192,255))
		r.BeginMode3D(camera)
		do
			r.DrawModel(model, position, 0.2, r.Color(255,255,255,255))
			r.DrawGrid(10, 1)
			r.DrawGizmo(position)
		end
		r.EndMode3D()
		r.DrawText("(c) Castle 3D model by Alberto Cano", screenWidth - 200, screenHeight - 20, 10, r.Color(160,160,160,160))
		r.DrawFPS(10, 10)
	end
	r.EndDrawing()
end

r.UnloadTexture(texture)
r.UnloadModel(model)
r.CloseWindow()
