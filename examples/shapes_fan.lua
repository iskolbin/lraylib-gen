local r = require('raylib')
local screenWidth, screenHeight = 800, 450
r.InitWindow(screenWidth, screenHeight, "raylib [shapes] example - fan")

r.SetTargetFPS(60)

while not r.WindowShouldClose() do
	r.BeginDrawing()
	do
		r.ClearBackground(r.Color(255,255,255,255))
		r.DrawText("some basic shapes available on raylib", 20, 20, 20, r.Color(30,30,30,255))
		r.DrawLineStrip({screenWidth/4*3, 160,  screenWidth/4*3 - 20, 230,  screenWidth/4*3 + 20, 230}, r.Color(0,0,120,255));
    r.DrawTriangleFan({screenWidth/4*1, 160,  screenWidth/4*1 - 20, 230,  screenWidth/4*1 + 20, 230}, r.Color(0,120,120,255));
	end
	r.EndDrawing()
end

r.CloseWindow()
