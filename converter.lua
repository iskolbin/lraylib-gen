local isResource = require( 'resources' ).isResource
local aliases = require( 'aliases' )

local UNIMPLEMETED_ARGS = {}
local UNIMPLEMENTED_RETURNS = {}

local function pushnumbers( ... )
	local t = {}
	for i, arg in ipairs{...} do
		t[i] = 'lua_pushnumber(L, result.' .. arg ..')'
	end
	return table.concat( t, '; ' ), #t
end

local function checknumbers( index, n )
	local t = {}
	for i = 1, n do
		t[i] = 'luaL_checknumber(L, ' .. (index+i-1) .. ')'
	end
	return table.concat( t, ', ' )
end

return {
	UNIMPLEMETED_ARGS = UNIMPLEMETED_ARGS,
	UNIMPLEMENTED_RETURNS = UNIMPLEMENTED_RETURNS,

	finalizer = function( T, v )
		T = aliases[T] or T
		if T == 'Mesh' then
			v = '&' .. v
		end
		if T == 'AudioStream' then
			return 'CloseAudioStream(' .. v .. ');'
		elseif T == 'Music' then
			return 'UnloadMusicStream(' .. v .. ');'
		else
			return'Unload' .. T:gsub( '2D', '' ) .. '(' .. v .. ');'
		end
	end,

	parseType = function( body )
		local items = {}
		for item in body:gmatch( '%s?([%w%*]+)' ) do
			local frontStars, trimmedItem = item:match('(%**)(.+)')
			if #frontStars > 0 then
				items[#items+1] = frontStars
			end
			items[#items+1] = trimmedItem
		end
		return items[#items], table.concat( items, ' ', 1, #items-1 )
	end,

	formatResourceType = function( res )
		return res:match('%s*%*?%s*(%w+)')
	end,

	luaToC = function( T, index )
		if T == 'int' or T == 'unsigned' or T == 'unsigned int' or T == 'unsigned char' then
			return '(' .. T .. ') luaL_checkinteger(L, ' .. index .. ')'
		elseif T == 'long' or T == 'float' or T == 'double' or T == 'char' or T == 'bool' then
			return '(' .. T .. ') luaL_checknumber(L, ' .. index .. ')'
		elseif T == 'const char *' or T == 'char *' then
			return '(' .. T .. ') luaL_checkstring(L, ' .. index .. ')'
		elseif T == 'Vector2' then
			return '(' .. T .. ') {' .. checknumbers(index, 2) .. '}', index+1
		elseif T == 'Vector3' then
			return '(' .. T .. ') {' .. checknumbers(index, 3) .. '}', index+2
		elseif T == 'Rectangle' then
			return '(' .. T .. ') {' .. checknumbers(index, 4) .. '}', index+3
		elseif T == 'Camera2D' then
			return '(' .. T .. ') {{' .. checknumbers(index, 2) .. '},{' .. checknumbers(index+2, 2) ..'},' .. checknumbers(index+4, 2) ..'}', index+5
		elseif T == 'BoundingBox' or T == 'Ray'then
			return '(' .. T .. ') {{' .. checknumbers(index, 3) .. '},{' .. checknumbers(index+3, 3) ..'}}', index+5
		elseif T == 'Matrix' then
			return '(' .. T .. ') {' .. checknumbers(index, 16) .. '}', index+15
		elseif T == 'Camera' or T == 'Camera3D' then
			return '(' .. T .. ') {{' .. checknumbers(index, 3) .. '},{' .. checknumbers(index+3,3) .. '},{' .. checknumbers(index+6,3) .. '},' .. checknumbers(index+9,1) .. ',luaL_checkinteger(L, ' .. (index+10) .. ')}', index+10
		elseif T == 'Color' then
			return 'GetColor(luaL_checkinteger(L, ' .. index .. '))'
		elseif isResource( T ) then
			return '((Wrapped' .. T .. ' *) luaL_checkudata(L, ' .. index .. ', "raylua_' .. T .. '"))->content'
		else
			UNIMPLEMETED_ARGS[T] = true
			return 'UNIMPLEMENTED_FOR_' .. T, index, true
		end
	end,

	cToLua = function( T )
		if T == 'int' or T == 'unsigned' or T == 'unsigned int' or T == 'char' then
			return 'lua_pushinteger(L, result)'
		elseif T == 'long' or T == 'float' or T == 'double' then
			return 'lua_pushnumber(L, result)'
		elseif T == 'const char *' or T == 'char *' then
			return 'lua_pushstring(L, result)'
		elseif T == 'bool' then
			return 'lua_pushboolean(L, result)'
		elseif T == 'Color' then
			return 'lua_pushinteger(L, ColorToInt(result))'
		elseif T == 'Vector2' then
			return pushnumbers( 'x', 'y' )
		elseif T == 'Vector3' then
			return pushnumbers( 'x', 'y', 'z' )
		elseif T == 'Vector4' then
			return pushnumbers( 'x', 'y', 'z', 'w' )
		elseif T == 'Rectangle' then
			return pushnumbers('x', 'y', 'width', 'height')
		elseif T == 'BoundingBox' then
			return pushnumbers( 'min.x', 'min.y', 'min.z', 'max.x', 'max.y', 'max.z' )
		elseif T == 'Ray' then
			return pushnumbers( 'position.x', 'position.y', 'position.z', 'direction.x', 'direction.y', 'direction.z' )
		elseif T == 'Matrix' then
			return pushnumbers( 'm0', 'm1', 'm2', 'm3', 'm4', 'm5', 'm6', 'm7', 'm8', 'm9', 'm10', 'm11', 'm12', 'm13', 'm14', 'm15' )
		elseif T == 'RayHitInfo' then
			return pushnumbers( 'hit', 'distance', 'position.x', 'position.y', 'position.z', 'normal.x', 'normal.y', 'normal.z' )
		elseif isResource( T ) then
			return 'raylua_' .. T .. '_wrap(L, &result)' 
			--return 'lua_pushinteger(L, raylua_Assoc' .. T .. 'Handler(L, &result))'
		else
			UNIMPLEMENTED_RETURNS[T] = true
			return 'UNIMPLEMENTED_FOR_' .. T .. '(L, result)', 1, true
		end
	end,
}
