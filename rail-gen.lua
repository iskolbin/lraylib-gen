local aliases = {
	I = 'Image',
	T = 'Texture2D',
	R = 'RenderTexture2D',
	A = 'AudioStream',
	M = 'Music',
	W = 'Wave',
	S = 'Sound',
	M = 'Model',
	H = 'Mesh',
	E = 'Material',
	D = 'Shader',
}

local convertStructs = {
	Color = 'i>GetColor>ColorToInt',
	Vector2 = 'f x y',
	Vector3 = 'f x y z',
	Vector4 = 'f x y z w',
	Rectangle = 'f x y width height',
	Matrix = 'f m0 m1 m2 m3 m4 m5 m6 m7 m8 m9 m10 m11 m12 m13 m14 m15'
}

local libs = {
	core = {
		fps = '>GetFPS>i',
		time = '>GetTime>f',
		clipboard = '>GetClipboardText>s',
		setclipboard = 's>SetClipboardText>',
	},

	keyboard = {
		ispressed = 'i>IsKeyPressed>b',
		isdown = 'i>IsKeyDown>b',
		isreleased = 'i>IsKeyReleased>b',
		isup = 'i>IsKeyUp>b',
		pressed = '>GetKeyPressed>i',
		setexitkey = 'i>SetExitKey>',
	}

	gamepad = {
		isavailable = 'i>IsGamepadAvailable>b',
		isname = 'is>IsGamepadName>b',
		name = 'i>GetGamepadName>s',
		ispressed = 'ii>IsGamepadButtonPressed>b',
		isdown = 'ii>IsGamepadButtonDown>b',
		isreleased = 'ii>IsGamepadButtonReleased>b',
		isup = 'ii>IsGamepadButtonUp>b',
		pressed = '>GetGamepadButtonPressed>i',
		axiscount = 'i>GetGamepadAxisCount>i',
		axismovement = 'ii>GetGamepadAxisMovement>f',
	},

	mouse = {
		ispressed = 'ii>IsMouseButtonPressed>b',
		isdown = 'ii>IsMouseButtonDown>b',
		isreleased = 'ii>IsMouseButtonReleased>b',
		isup = 'ii>IsMouseButtonUp>b',
		x = '>GetMouseX>i',
		y = '>GetMouseY>i',
		pos = '>GetMousePosition>Vector2',
		setpos = 'ii>SetMousePosition>',
		setoffset = 'ii>SetMouseOffset>',
		setscale = 'ff>SetMouseScale>',
		wheelmove = '>GetMouseWheelMove>i',
	},

	touch = {
		x = '>GetTouchX>i',
		y = '>GetTouchY>i',
		pos = 'i>GetTouchPosition>Vector2',
	}

	window = {
		init = 'i,i,s>InitWindow>',
		close = '>CloseWindow>',
		isready = '>IsWindowReady>b',
		isminimized = '>IsWindowMinimized>b',
		isresized = '>IsWindowResized>b',
		ishidden = '>IsWindowHidden>b',
		togglefullscreen = '>ToggleFullscreen>',
		setvisible = 'b>{@choose 1 UnhideWindow HideWindow}>',
		seticon = 'Image>SetWindowIcon>',
		settitle = 's>SetWindowTitle>',
		setpos = 'i,i>SetWindowPosition>',
		setmonitor = 'i>SetWindowMonitor>',
		setminsize = 'i,i>SetWindowMinSize>',
		setsize = 'i,i>SetWindowSize>',
		screenwidth = '>GetScreenWidth>i',
		screenheight = '>GetScreenHeight>i',
		monitorcount = '>GetMonitorCount>i',
		monitorwidth = '>GetMonitorWidth>i',
		monitorheight = '>GetMonitorHeight>i',
		monitorphysicalwidth = 'i>GetMonitorPhysicalWidth>i',
		monitorphysicalheight = 'i>GetMonitorPhysicalHeight>i',
		monitorname = 'i>GetMonitorName>s',
		setcursorvisible = 'b>{@choose 1 ShowCursor HideCursor}>',
		setcursorvenabled = 'b>{@choose 1 EnableCursor DisableCursor}>',
		iscursorvisible = '>IsCursorHidden>b',
	},

	draw = {
		clear = 'Color>ClearBackground>',
		pixel = 'f,f,Color>DrawPixel>',
		line = 'f,f,f,f,f,Color>DrawLineEx>',
		bezier = 'Vector2,Vector2,f,Color>DrawLineBezier>',
		sector = 'Vector2,f,i,i,Color>DrawCircleSector>',
		gradcircle = 'i,i,f,Color,Color>DrawCircleGradient>',
		gradrect = 'Rectangle,Color,Color,Color,Color>DrawRectangleGradientEx>',
		gradrectv = 'Rectangle,Color,Color>DrawRectangleGradientV>',
		gradrecth = 'Rectangle,Color,Color>DrawRectangleGradientH>',
		circle = 'i,i,f,Color>DrawCircle>',
		rect = 'i,i,i,i,Color>DrawRectangle>',
		triangle = 'Vector2,Vector2,Vector2,Color>DrawTriangle>',
		polygon = '{@array Vector2},{@length 1},Color>DrawPolyEx>',
		strokecircle = 'i,i,f,Color>DrawCircleLines>',
		strokerect = 'Rectangle,f,Color>DrawRectangleLinesEx>',
		stroketriangle = 'Vector2,Vector2,Vector2,Color>DrawTriangleLinesEx>',
		strokepolygon = '{@array Vector2},{@length 1},Color>DrawPolyExLines>',
	},
}

local ARGS_PATTERN = '([%w%s*{},_@]*)'
local ARG_PATTERN = '([%w%s*{}_@]+)'
local OPERATOR_PATTERN = '%{%@([%w%s*_]+)%}'
local SIGNATURE_PATTERN = ARGS_PATTERN .. '>' .. ARGS_PATTERN .. '>' .. ARGS_PATTERN

local function convertName( libName, funcName )
	return 'rail_' .. libName .. '_' .. funcName
end

local function genArgs( n )
	local t = {}
	for i = 1, n do
		t[i] = 'arg' .. i
	end
	return '(' .. table.concat( t, ', ' ) .. ')'
end

local convertInput = {
	i = function( i ) return 'lua_Integer arg' .. i .. ' = luaL_checkinteger(L, arg' .. i .. ');' end,
	f = function( i ) return 'lua_Number arg' .. i .. ' = luaL_checknumber(L, arg' .. i .. ');' end,
	s = function( i ) return 'const char *arg' .. i .. ' = luaL_checkstring(L, arg' .. i .. ');' end,
	b = function( i ) return 'int arg'.. i .. ' = lua_toboolean(L, arg' .. i .. ');' end,
	Color = function( i ) return 'Color arg' .. i .. ' = GetColor(luaL_checkinteger(L, arg' .. i .. ');' end,
}

local convertOutput = {
	i = function( i ) return 'lua_Integer' end,
	f = function( i ) return 'lua_Number' end,
	s = function( i ) return 'const char *' end,
	b = function( i ) return 'int' end,
	Color = function( i ) return 'Color' end,
}

local pushOutput = {
	i = function( i ) return 'lua_pushinteger(L, result);' end,
	f = function( i ) return 'lua_pushnumber(L, result);' end,
	s = function( i ) return 'lua_pushstring(L, result);' end,
	b = function( i ) return 'lua_pushboolean(L, result);' end,
	Color = function( i ) return 'lua_pushinteger(L, ColorToInt(result));' end,
}

local inputSimpleStructsConverter = {
	Matrix = '{ffffffffffffffff}',
	Vector2 = '{ff}',
	Vector3 = '{fff}',
	Vector4 = '{ffff}',
	Rectangle = '{ffff}',
	Camera2D = '{{ff}{ff}ff}',
	Camera3D = '{{fff}{fff}{fff}fi}',
	BoundingBox = '{{fff}{fff}}',
	Ray = '{{fff}{fff}}',
	RayHitInfo = '{bf{fff}{fff}}',
	NPatchInfo = '{{ffff}iiiii}',
}

local function parseSignature( libName, funcName, signature )
	local opener = 'int ' .. convertName( libName, funcName ) .. '(lua_State *L)'
	local input, body, output = signature:match( SIGNATURE_PATTERN )
	local nInputArgs = select( 2, input:gsub( ARG_PATTERN, '' ))
	local nOutputArgs = select( 2, output:gsub( ARG_PATTERN, '' ))
	local t = {' {'}
	local index = 0
	for arg in input:gmatch( ARG_PATTERN ) do
		index = index + 1
		local op = arg:match( OPERATOR_PATTERN )
		if op then

		else
			local targ, tindex = convertInput[arg] and convertInput[arg]( index ) or wrapper[arg]
			t[#t+1] = targ
			if tindex then
				index = tindex
			end
		end
	end

	local op = body:match( OPERATOR_PATTERN )
	if op then
		
	else
		if nOutputArgs == 0 then
			t[#t+1] = body .. genArgs( nInputArgs ) .. ';'
		else
			local outputType = convertOutput[output]( index )
			t[#t+1] = outputType .. ' result = ' .. body .. genArgs( nInputArgs ) .. ';'
		end
	end

	if nOutputArgs > 0 then
		op = output:match( OPERATOR_PATTERN )
		if op then
		else
			t[#t+1] = pushOutput[output]( index )
		end
	end

	t[#t+1] = 'return ' .. nOutputArgs .. ';'
	return opener .. table.concat( t, '\n  ' ) .. '\n}'
end

for libName, lib in pairs( libs ) do
	for funcName, signature in pairs( lib ) do
		print( parseSignature( libName, funcName, signature ))
		print()
	end
end
