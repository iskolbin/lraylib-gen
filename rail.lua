local raylib = require('raylib')

local rail = {
	conf = {
		window = {
			title = 'Untitled',
			icon = nil,
			width = 800,
			height = 600,
			minwidth = 1,
			minheight = 1,
			fullscreen = false,
			x = nil,
			y = nil,
			fps = 60,
		},
	},

	window = {
		getwidth = raylib.GetScreenWidth,
		getheight = raylib.GetScreenHeight,
		getsize = function() return raylib.GetScreenWidth(), raylib.GetScreenHeight() end,
	},

	ctx = {
		clear = raylib.ClearBackground,
		text = raylib.DrawText,
		pixel = raylib.DrawPixel,
		line = raylib.DrawLine,
		beizer = raylib.DrawLineBezier,
		strokerect = raylib.DrawRectangleLines,
		fillrect = raylib.DrawRectangle,
		gradrect = raylib.DrawRectangleGradientEx,
		hgradrect = raylib.DrawRectangleGradientH,
		vgradrect = raylib.DrawRectangleGradientV,
		strokecircle = raylib.DrawCircleLines,
		fillcircle = raylib.DrawCircle,
		gradcircle = raylib.CircleGradient,

		texture = raylib.DrawTexture,
	},

	gfx = {
		loadimage = raylib.LoadImage,
		loadtexture = function( v )
			if type(v) == 'string' then
				return raylib.LoadTexture( v )
			else
				return raylib.LoadTextureFromImage( v )
			end
		end,
		genfill = raylib.GenImageColor,
		genvgrad = raylib.GenImageGradientV,
		genhgrad = raylib.GenImageGradientV,
		genrgrad = raylib.GenImageGradientRadial,
		genchecked = raylib.GenImageChecked,
		genwhitenoise = raylib.GenImageWhiteNoise,
		genperlinnoise = raylib.GenImagePerlinNoise,
		gencelluar = raylib.GenImageCellular,
	},

	state = {
		fullscreen = false,
	},

	load = function() end,

	update = function() end,

	draw = function() end,

	keyboard = {
		ispressed = raylib.IsKeyPressed,
		isdown = raylib.IsKeyDown,
	},
}

for k, v in pairs( raylib ) do
	if type( v ) == 'number' then
		rail[k] = v
	end
end

local function updateImageMetatable()
	local img = raylib.GenImageColor(0, 0, 0)
	local mt = getmetatable( img )
	mt.resize = function(...) raylib.ImageResize( ... ) end
	print( mt, mt.resize )
end

function rail.run()
	local conf = rail.conf.window
	raylib.InitWindow( conf.width, conf.height, conf.title )
	updateImageMetatable()
	rail.load()
	if conf.icon then
		raylib.SetIcon( conf.icon )
	end
	if conf.x and conf.y then
		raylib.SetWindowPosition( conf.x, conf.y )
	end
	if conf.minwidth and conf.minheight then
		raylib.SetWindowMinSize( conf.minwidth, conf.minheight )
	end
	
	raylib.SetTargetFPS( conf.fps )
	local t0 = raylib.GetTime()
	local t1 = t0
	local dt = 0
	local dt_needed = 1/conf.fps
	while not raylib.WindowShouldClose() do
		rail.update(dt, t)
		raylib.BeginDrawing()
		rail.draw(rail.ctx, dt, t)
		raylib.EndDrawing()
		t0 = t1
		t1 = raylib.GetTime()
		dt = t1 - t0
		local sleep_t = dt_needed - dt
		if sleep_t > 0 then
			raylib.Sleep( math.floor( 1000000 * sleep_t ))
		end
	end
	raylib.CloseWindow()
end

function rail.isfullscreen()
	return rail.state.fullscreen
end

function rail.setfullscreen( fullscreen )
	if rail.conf.window.fullscreen and (fullscreen == true or fullscreen == false) and fullscreen ~= rail.state.fullscreen then
		rail.state.fullscreen = fullscreen
		raylib.ToggleFullscreen()
	end
end

return rail
