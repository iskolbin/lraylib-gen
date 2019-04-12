local raylib = require('raylua')

setmetatable( raylib, {__index = function(...)
	print(...)
	local self, k = ...
	print( rawget(self,k))
	error("") end, __newindex = error} )

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

	time = raylib.GetTime,
	frametime = raylib.GetFrameTime,
	getfps = raylib.GetFPS,

	window = {
		getwidth = raylib.GetScreenWidth,
		getheight = raylib.GetScreenHeight,
		getsize = function() return raylib.GetScreenWidth(), raylib.GetScreenHeight() end,
		settitle = raylib.SetWindowTitle,
		setpos = raylib.SetWindowPosition,
		setminsize = raylib.SetWindowMinSize,
		setmonitor = raylib.SetWindowMonitor,
		isminimized = raylib.IsWindowMinimized,
		isready = raylib.IsWindowReady,
	},

	ctx = {
		clear = raylib.ClearBackground,
		text = raylib.DrawText,
		points = function(...)
			local n = select( '#', ... ) - 1
			local color = select( n+1, ... )
			for i = 1, n, 2 do
				local x, y = select( i, ... )
				raylib.DrawPixel( x, y, color )
			end
		end,
		line = raylib.DrawLine,
		beizer = raylib.DrawLineBezier,
		strokerect = raylib.DrawRectangleLines,
		fillrect = raylib.DrawRectangle,
		gradrect = raylib.DrawRectangleGradientEx,
		hgradrect = raylib.DrawRectangleGradientH,
		vgradrect = raylib.DrawRectangleGradientV,
		strokecircle = raylib.DrawCircleLines,
		fillcircle = raylib.DrawCircle,
		gradcircle = raylib.DrawCircleGradient,

		draw = raylib.DrawTexture,
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

	image = {
		copy = raylib.ImageCopy,
		textimage = function(...)
			local n = select('#', ...)
			if n == 3 then
				raylib.ImageText(...)
			elseif n == 5 then
				raylib.ImageTextEx( ... )
			end
		end,
		topow2 = raylib.ImageToPOT,
		format = raylib.ImageFormat,
		alphamask = raylib.ImageAlphaMask,
		alhpaclear = raylib.ImageAlphaClear,
		alphacrop = raylib.ImageAlphaCrop,
		alphapremultiply = raylib.ImageAlphaPremultiply,
		crop = raylib.ImageCrop,
		resize = raylib.ImageResize,
		resizenn = raylib.ImageResizeNN,
		resizecanvas = raylib.ImageResizeCanvas,
		mipmaps = raylib.ImageMipmaps,
		dither = raylib.ImageDither,
		rect = raylib.ImageDrawRectangle,
		text = function(...)
			local n = select('#', ...)
			if n == 5 then
				raylib.ImageDrawText(...)
			elseif n == 7 then
				raylib.ImageDrawTextEx( ... )
			end
		end,
		vfilp = raylib.ImageFlipVertical,
		hfilp = raylib.ImageFlipHorizontal,
		rotcw = raylib.ImageRotateCW,
		rotccw = raylib.ImageRotateCCW,
		tint = raylib.ImageColorTint,
		invert = raylib.ImageColorInvert,
		grayscale = raylib.ImageColorGrayscale,
		contrast = raylib.ImageColorContrast,
		brightness = raylib.ImageColorBrightness,
		replace = raylib.ImageColorReplace,
	},

	mouse = {
		setvisible = function( visible )
			if visible then
				raylib.ShowCursor()
			else
				raylib.HideCursor()
			end
		end,
		isvisible = function()
			return not raylib.IsCursorHidden()
		end,
		setenabled = function( enabled )
			if enabled then
				raylib.EnableCursor()
			else
				raylib.DisableCursor()
			end
		end,
		ispressed = raylib.IsMouseButtonPressed,
		isreleased = raylib.IsMouseButtonReleased,
		isdown = raylib.IsMouseButtonDown,
		isup = raylib.IsMouseButtonUp,
		getx = raylib.GetMouseX,
		gety = raylib.GetMouseY,
		getpos = function() return raylib.GetMouseX(), raylib.GetMouseY() end,
		setpos = raylib.SetMousePosition,
		getwheel = raylib.GetMouseWheelMove,
	},

	keyboard = {
		ispressed = raylib.IsKeyPressed,
		isreleased = raylib.IsKeyReleased,
		isdown = raylib.IsKeyDown,
		isup = raylib.IsKeyUp,
		getpressed = raylib.GetKeyPressed,
	},

	gamepad = {
		isavailable = raylib.IsGamepadAvailable,
		getname = raylib.GetGamepadName,
		ispressed = raylib.IsGamepadButtonPressed,
		isreleased = raylib.IsGamepadButtonReleased,
		isdown = raylib.IsGamepadButtonDown,
		isup = raylib.IsGamepadButtonUp,
		getpressed = raylib.GetGamepadButtonPressed,
		getaxis = raylib.GetGamepadAxisMovement,
		getaxiscount = raylib.GetGamepadAxisCount,
	},

	touch = {
		getx = raylib.GetTouchX,
		gety = raylib.GetTouchY,
		getpos = raylib.GetTouchPosition,
		getcount = raylib.GetTouchPointsCount,
	},

	fs = {
		getextension = raylib.GetExtension,
		getfilename = raylib.GetFileName,
		getdirectorypath = raylib.GetDirectoryPath,
		getworkingdirectory = raylib.GetWorkingDirectory,
		changedirectory = raylib.ChangeDirectory,
		isfiledropped = raylib.IsFileDropped,
		getdroppedfiles = raylib.GetDroppedFiles,
		getdirectoryfiles = raylib.GetDirectoryFiles,
	}
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
		rail.update(dt, t0)
		raylib.BeginDrawing()
		rail.draw(rail.ctx, dt, t0)
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
	if rail.conf.window.fullscreen and (type(fullscreen) == 'boolean') and fullscreen ~= rail.state.fullscreen then
		rail.state.fullscreen = fullscreen
		raylib.ToggleFullscreen()
	end
end

return rail
