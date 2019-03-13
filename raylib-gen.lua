print('#define LUA_LIB')
print('#include "raylib.h"')
print('#include <lua.h>')
print('#include <lauxlib.h>')
print('#include <lualib.h>')

local function parseTypeName( body )
	local items = {}
	for item in body:gmatch( '%s?([%w%*]+)' ) do
		local frontStars, trimmedItem = item:match('(%**)(.+)')
		if #frontStars > 0 then
			items[#items+1] = frontStars
		end
		items[#items+1] = trimmedItem
	end
	return items[#items], table.concat( items, ' ', 1, #items-1 )
end

local UNIMPLEMETED_ARGS = {}

local function nCheckNumbers( index, n )
	local t = {}
	for i = 1, n do
		t[i] = 'luaL_checknumber(L, ' .. (index+i-1) .. ')'
	end
	return table.concat( t, ', ' )
end

local function argConvert( argType, index )
	if argType == 'int' or
		argType == 'long' or
		argType == 'float' or
		argType == 'double' or
		argType == 'unsigned' or
		argType == 'unsigned int' or
		argType == 'unsigned char' or
		argType == 'char' or
		argType == 'bool' then
		return '(' .. argType .. ')luaL_checknumber(L, ' .. index .. ')'
	elseif argType == 'const char *' or argType == 'char *' then
		return 'luaL_checkstring(L, ' .. index .. ')'
	elseif argType == 'Vector2' then
		return '(' .. argType .. ') {' .. nCheckNumbers(index, 2) .. '}', index+1
	elseif argType == 'Vector3' then
		return '(' .. argType .. ') {' .. nCheckNumbers(index, 3) .. '}', index+2
	elseif argType == 'Rectangle' then
		return '(' .. argType .. ') {' .. nCheckNumbers(index, 4) .. '}', index+3
	elseif argType == 'BoundingBox' or argType == 'Ray' or argType == 'Camera2D' then
		return '(' .. argType .. ') {' .. nCheckNumbers(index, 6) .. '}', index+5
	elseif argType == 'Matrix' then
		return '(' .. argType .. ') {' .. nCheckNumbers(index, 16) .. '}', index+15
	elseif argType == 'Camera' or argType == 'Camera3D' then
		return '(' .. argType .. ') {' .. nCheckNumbers(index, 11) .. '}', index+10
	elseif argType == 'Color' then
		return 'GetColor(luaL_checknumber(L, ' .. index .. '))'
	else
		UNIMPLEMETED_ARGS[argType] = true
		return 'UNIMPLEMENTED_FOR_' .. argType, index, true
	end
end

local UNIMPLEMENTED_RETURNS = {}

local function returnConvert( returnType )	
	if returnType == 'int' or
		returnType == 'long' or
		returnType == 'float' or
		returnType == 'double' or
		returnType == 'unsigned' or
		returnType == 'unsigned int' or
		returnType == 'char' then
		return 'lua_pushnumber(L, result)'
	elseif returnType == 'const char *' or returnType == 'char *' then
		return 'lua_pushstring(L, result)'
	elseif returnType == 'bool' then
		return 'lua_pushboolean(L, result)'
	elseif returnType == 'Color' then
		return 'lua_pushnumber(L, ColorToInt(result))'
	elseif returnType == 'Vector2' then
		return 'lua_pushnumber(L, result.x); lua_pushnumber(L, result.y)'
	elseif returnType == 'Vector3' then
		return 'lua_pushnumber(L, result.x); lua_pushnumber(L, result.y); lua_pushnumber(L, result.z)'
	elseif returnType == 'Vector4' then
		return 'lua_pushnumber(L, result.x); lua_pushnumber(L, result.y); lua_pushnumber(L, result.z); lua_pushnumber(L, result.w)'
	elseif returnType == 'Rectangle' then
		return 'lua_pushnumber(L, result.x); lua_pushnumber(L, result.y); lua_pushnumber(L, result.width); lua_pushnumber(L, result.height)'
	elseif returnType == 'BoundingBox' then
		return 'lua_pushnumber(L, result.min.x); lua_pushnumber(L, result.min.y); lua_pushnumber(L, result.min.z); lua_pushnumber(L, result.max.x); lua_pushnumber(L, result.max.y); lua_pushnumber(L, result.max.z)'
	elseif returnType == 'Ray' then
		return 'lua_pushnumber(L, result.position.x); lua_pushnumber(L, result.position.y); lua_pushnumber(L, result.position.z); lua_pushnumber(L, result.direction.x); lua_pushnumber(L, result.direction.y); lua_pushnumber(L, result.direction.z)'
	elseif returnType == 'Matrix' then
		return 'lua_pushnumber(L, result.m0); lua_pushnumber(L, result.m4); lua_pushnumber(L, result.m8); lua_pushnumber(L, result.m12);' ..
		'lua_pushnumber(L, result.m1); lua_pushnumber(L, result.m5); lua_pushnumber(L, result.m9); lua_pushnumber(L, result.m13);' ..
		'lua_pushnumber(L, result.m2); lua_pushnumber(L, result.m6); lua_pushnumber(L, result.m10); lua_pushnumber(L, result.m14);' ..
		'lua_pushnumber(L, result.m3); lua_pushnumber(L, result.m7); lua_pushnumber(L, result.m11); lua_pushnumber(L, result.m15)'
	elseif returnType == 'RayHitInfo' then
		return 'lua_pushboolean(L, result.hit); lua_pushnumber(L, result.distance); lua_pushnumber(L, result.position.x); lua_pushnumber(L, result.position.y); lua_pushnumber(L, result.position.z); lua_pushnumber(L, result.normal.x); lua_pushnumber(L, result.normal.y); lua_pushnumber(L, result.normal.z)'
	elseif returnType == 'Color' then
		return 'lua_pushnumber(L, ColorToInt(result))'
	else
		UNIMPLEMENTED_RETURNS[returnType] = true
		return 'UNIMPLEMENTED_FOR_' .. returnType .. '(L, result)', 1, true
	end
end

local nFuncs, nUnimplemented, nUnimplenentedArgs, nUnimplementedReturns = 0, 0, 0, 0
local s = nil


local BLACKLIST = {
	GetDirectoryFiles = true, -- returns const char **
	GetDroppedFiles = true, -- returns const char **
	UpdateCamera = true, -- nothing to update actually
	UpdateVrTracking = true, -- nothing to update actually

	SetTraceLogLevel = true,
	SetTraceLogExit = true,
	SetTraceLogCallback = true,
	TraceLog = true,

	DrawPixelV = true,
	DrawLineV = true,
	DrawCircleV = true,
	DrawCubeWiresV = true,
	DrawCubeV = true,
	DrawRectangleV = true,
	DrawRectangleRec = true,
	TextIsEqual = true,
	TextLength = true,
	TextFormat = true,
	TextSubtext = true,
	TextReplace = true,
	TextInsert = true,
	TextJoin = true,
	TextSplit = true,
	TextAppend = true,
	TextFindIndex = true,
	TextToUpper = true,
	TextToLower = true,
	TextToPascal = true,
	TextToInteger = true
}

local implementedFunctionNames = {}
for line in io.lines('raylib.h') do
	-- Multiline support
	if s then
		s = s:sub(1,-2) .. line
	end
	if line:sub(1,5) == 'RLAPI' then
		s = line
	end

	if s and s:match(';') then
		-- Varargs
		s, varargIndex = s:gsub('%,%s%.%.%.', '')
		local funcVararg = varargIndex > 0

		local bodyName, bodyArgs, comment = s:match( 'RLAPI (.+)%((.-)%);%s*//%s*(.+)' )
		local funcName, funcReturnType = parseTypeName( bodyName )
		local funcArgs, funcArgsNames = {}, {}
		if bodyArgs ~= 'void' then
			for bodySingleArg in bodyArgs:gmatch( '([%w%s%*]+)' ) do
				funcArgs[#funcArgs+1] = {parseTypeName( bodySingleArg )}
				funcArgsNames[#funcArgsNames+1] = funcArgs[#funcArgs][1]
			end
		end

		local funcCode = {}
		if not BLACKLIST[funcName] then
			nFuncs = nFuncs + 1
			funcCode[#funcCode+1] = ( '\n// ' .. comment )
			funcCode[#funcCode+1] = ( 'static int raylua_' .. funcName ..'(lua_State *L)' )
			funcCode[#funcCode+1] = ( '{' )
			local i, unimplementedArgConvert, unimplemented = 0, false, false
			for _, arg in ipairs( funcArgs ) do
				i = i + 1
				local argName, argType = arg[1], arg[2]
				local converted, j, unimplementedCurrentArgConvert = argConvert( argType, i )
				if j and j > i then
					i = j
				end
				unimplementedArgConvert = unimplementedArgConvert or unimplementedCurrentArgConvert
				funcCode[#funcCode+1] = ( '  ' .. argType .. ' ' .. argName .. ' = ' .. converted .. ';' )
			end
			local result, resultCount = funcReturnType .. ' result = ', 1
			if funcReturnType == 'void' then
				result, resultCount = '', 0
			end
			funcCode[#funcCode+1] = ( '  ' .. result .. funcName .. '(' .. table.concat( funcArgsNames, ', ' ) .. ');')

			if unimplementedArgConvert then
				nUnimplenentedArgs = nUnimplenentedArgs + 1
				unimplemented = true
			end

			if resultCount > 0 then
				local convertedResult, newCount, unimplementedReturn = returnConvert( funcReturnType )
				if newCount and newCount > 1 then
					resultCount = newCount
				end
				funcCode[#funcCode+1] = ( '  ' .. convertedResult ..';' )

				if unimplementedReturn then
					nUnimplementedReturns = nUnimplementedReturns + 1
					unimplemented = true
				end
			end

			if funcVararg then
				unimplemented = true
			end

			if unimplemented then
				nUnimplemented = nUnimplemented + 1
			end

			funcCode[#funcCode+1] = ( '  return ' .. resultCount .. ';')
			funcCode[#funcCode+1] = ( '}' )
			if unimplemented then
				print('// ' .. funcName .. ' is not implemented' )
			else
				implementedFunctionNames[#implementedFunctionNames+1] = funcName
				print( table.concat( funcCode, '\n' ))
			end
		end
		s = nil
	end
end

print( 'static const luaL_Reg raylua_functions[] = {' )
for _, funcName in ipairs( implementedFunctionNames ) do
	print( '  {"' .. funcName .. '", raylua_' .. funcName .. '},' ) 
end
print( '  {NULL, NULL}' )
print( '};' )

print( 'LUAMOD_API int luaopen_raylib (lua_State *L) {' )
print( '  luaL_newlib(L, raylua_functions);' )
print( '  return 1;' )
print( '}')

print( '// Summary' )
print( '// wrapped functions: ' .. nFuncs .. ', unimplemented: ' .. nUnimplemented )
if next( UNIMPLEMETED_ARGS ) then
	print( '// unimplemented argument conversions: ' .. nUnimplenentedArgs .. ' functions' )
end
for name in pairs( UNIMPLEMETED_ARGS ) do
	print( '//', name )
end
if next( UNIMPLEMENTED_RETURNS ) then
	print( '// unimplemented return conversions: ' .. nUnimplementedReturns .. ' functions' )
end
for name in pairs( UNIMPLEMENTED_RETURNS ) do
	print( '//', name )
end
