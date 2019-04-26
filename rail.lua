local raylib = require('raylib')

local oldraylibmt = getmetatable( raylib )
setmetatable( raylib, {__index = error, __newindex = error} )

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

	hsv = raylib.ColorToHSV,
	fade = raylib.Fade,
	time = raylib.GetTime,
	normalize = raylib.ColorNormalize,
	frametime = raylib.GetFrameTime,
	getfps = raylib.GetFPS,
	setfps = raylib.SetTargetFPS,
	openurl = raylib.OpenURL,

	clipboard = {
		set = raylib.SetClipboardText,
		get = raylib.GetClipboardText,
	},

	window = {
		isready = raylib.IsWindowReady,
		isminimized = raylib.IsWindowMinimized,
		isresized = raylib.IsWindowResized,
		isvisible = function() return not raylib.IsWindowHidden() end,
		getwidth = raylib.GetScreenWidth,
		getheight = raylib.GetScreenHeight,
		getsize = function() return raylib.GetScreenWidth(), raylib.GetScreenHeight() end,
		settitle = raylib.SetWindowTitle,
		seticon = raylib.SetWindowIcon,
		setpos = raylib.SetWindowPosition,
		setmonitor = raylib.SetWindowMonitor,
		setvisible = function( visible ) if visible then raylib.UnhideWindow() else raylib.HideWindow() end end,
		setminsize = raylib.SetWindowMinSize,
		setsize = raylib.SetWindowSize,
	},

	monitor = {
		getcount = raylib.GetMonitorCount,
		getname = raylib.GetMonitorName,
		getwidth = raylib.GetMonitorWidth,
		getheight = raylib.GetMonitorHeight,
		getsize = function() return raylib.GetMonitorWidth(), raylib.GetMonitorHeight() end,
		getphysicalwidth = raylib.GetMonitorPhysicalWidth,
		getphysicalheight = raylib.GetMonitorPhysicalHeight,
		getphysicalsize = function() return raylib.GetMonitorPhysicalWidth(), raylib.GetMonitorPhysicalHeight() end,
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
		bezier = raylib.DrawLineBezier,
		strokerect = raylib.DrawRectangleLines,
		strokerectrounded = raylib.DrawRectangleRoundedLines,
		strokecircle = raylib.DrawCircleLines,
		stroketriangle = raylib.DrawTriangleLines,
		strokepoly = raylib.DrawPolyExLines,
		fillrect = raylib.DrawRectangle,
		fillrectrounded = raylib.DrawRectangleRounded,
		fillcircle = raylib.DrawCircle,
		filltriangle = raylib.DrawTriangle,
		fillpoly = raylib.DrawPolyEx,
		fillregularpoly = raylib.DrawPoly,
		gradrect = raylib.DrawRectangleGradientEx,
		hgradrect = raylib.DrawRectangleGradientH,
		vgradrect = raylib.DrawRectangleGradientV,
		gradcircle = raylib.DrawCircleGradient,

		drawtexture = raylib.DrawTexture,
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

	audio = {
		setmastervolume = raylib.SetMasterVolume,
		isready = raylib.IsAudioDeviceReady,
		loadsound = raylib.LoadSound,
		loadmusic = raylib.LoadMusicStream,
	},

	sound = {
		setvolume = raylib.SetSoundVolume,
		setpitch = raylib.SetSoundPitch,
		pause = raylib.PauseSound,
		stop = raylib.StopSound,
		play = raylib.PlaySound,
		isplaying = raylib.IsSoundPlaying,
	},

	music = {
		setvolume = raylib.SetMusicVolume,
		setpitch = raylib.SetMusicPitch,
		pause = raylib.PauseMusicStream,
		stop = raylib.StopMusicStream,
		play = raylib.PlayMusicStream,
		isplaying = raylib.IsMusicPlaying,
		setloopcount = raylib.SetMusicLoopCount,
		getlength = raylib.GetMusicTimeLength,
		getplayed = raylib.GetMusicTimePlayed,
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
		setexit = raylib.SetExitKey,
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
		isexist = raylib.FileExists,
		getext = raylib.GetExtension,
		getfilename = raylib.GetFileName,
		getfilenamenoext = raylib.GetFileNameWithoutExt,
		getdirectorypath = raylib.GetDirectoryPath,
		getworkingdirectory = raylib.GetWorkingDirectory,
		changedirectory = raylib.ChangeDirectory,
		isfiledropped = raylib.IsFileDropped,
		getdroppedfiles = raylib.GetDroppedFiles,
		getdirectoryfiles = raylib.GetDirectoryFiles,
		getfilemodtime = raylib.GetFileModTime,
	},

	storage = {
		set = raylib.StorageSaveValue,
		get = raylib.StorageLoadValue,
	},

	math = {},

	ease = {
		linear = raylib.EaseLinearNone,
	},
}

local function updateMath( funcName, func, subs )
	for typeName, changeTo in pairs( subs ) do
		if funcName:match( k ) then
			rail.math[funcName:gsub( subs )] = func
		end
	end
end

local function updateEasings( funcName, func )
	if funcName:match('^Ease') then
		rail.ease[funcName:sub( 5 ):lower()] = func
	end
end

for k, v in pairs( raylib ) do
	if type( v ) == 'number' then
		rail[k] = v
	else
		updateMath( k, v, { Vector2 = vec2, Vector3 = vec3, Vector4 = vec4, Matrix = mat, Quarterion = quart} )
		updateEasings( k, v )
	end
end

local function updateImageMetaTable()
	local mt = raylib.GetImageMeta()
	for k, v in pairs( rail.image ) do mt[k] = v end
end

function rail.run()
	local conf = rail.conf.window
	raylib.InitWindow( conf.width, conf.height, conf.title )
	raylib.InitAudioDevice()
	updateImageMetaTable()
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
	raylib.CloseAudioDevice()
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

function rail.ctx.mode2d( f, ... )
	raylib.BeginMode2D( ... )
	f( rail.ctx )
	raylib.EndMode2D()
end

function rail.ctx.mode3d( f, ... )
	raylib.BeginMode3D( ... )
	f( rail.ctx )
	raylib.EndMode3D()
end

function rail.ctx.modetexture( f, ... )
	raylib.BeginTextureMode( ... )
	f( rail.ctx )
	raylib.EndTextureMode()
end

setmetatable( raylib, oldraylibmt )

return rail
