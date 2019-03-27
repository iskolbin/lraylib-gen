local resources = {
	'Image',
	'Texture2D',
--[[	'RenderTexture2D',
	'Shader',
	'Font',
	'AudioStream',
	'Sound',
	'Music',
	'Mesh',
	'Model',
	'Material',
	'Wave'
	--]]
}

local function pp( str, substitutesTable )
	local s = (str:gsub( '%$%{(%w-)%}', substitutesTable))
--	print(s)
end


local function getReleaseFunction( t, v )
	t = aliases[t] or t
	if t ~= 'Mesh' then
		v = '*' .. v
	end
	if t == 'AudioStream' then
		return 'CloseAudioStream(' .. v .. ');'
	elseif t == 'Music' then
		return 'UnloadMusicStream(' .. v .. ');'
	else
		return'Unload' .. t:gsub( '2D', '' ) .. '(' .. v .. ');'
	end
end

local function isResource( t )
	for _, t_ in pairs( resources ) do
		if t_ == t then
			return true
		end
	end
	return false
end

local UNIMPLEMENTED_RETURNS = {}

local function pushNumbers( ... )
	local t = {}
	for i, arg in ipairs{...} do
		t[i] = 'lua_pushnumber(L, result.' .. arg ..')'
	end
	return table.concat( t, '; ' ), #t
end

local function returnConvert( returnType )
	if returnType == 'int' or
		returnType == 'unsigned' or
		returnType == 'unsigned int' or
		returnType == 'char' then
		return 'lua_pushinteger(L, result)'
	elseif returnType == 'long' or
		returnType == 'float' or
		returnType == 'double' then
		return 'lua_pushnumber(L, result)'
	elseif returnType == 'const char *' or returnType == 'char *' then
		return 'lua_pushstring(L, result)'
	elseif returnType == 'bool' then
		return 'lua_pushboolean(L, result)'
	elseif returnType == 'Color' then
		return 'lua_pushinteger(L, ColorToInt(result))'
	elseif returnType == 'Vector2' then
		return pushNumbers( 'x', 'y' )
	elseif returnType == 'Vector3' then
		return pushNumbers( 'x', 'y', 'z' )
	elseif returnType == 'Vector4' then
		return pushNumbers( 'x', 'y', 'z', 'w' )
	elseif returnType == 'Rectangle' then
		return pushNumbers('x', 'y', 'width', 'height')
	elseif returnType == 'BoundingBox' then
		return pushNumbers( 'min.x', 'min.y', 'min.z', 'max.x', 'max.y', 'max.z' )
	elseif returnType == 'Ray' then
		return pushNumbers( 'position.x', 'position.y', 'position.z', 'direction.x', 'direction.y', 'direction.z' )
	elseif returnType == 'Matrix' then
		return pushNumbers(
		'm0', 'm4', 'm8', 'm12',
		'm1', 'm5', 'm9', 'm13',
		'm2', 'm6', 'm10', 'm14',
		'm3', 'm7', 'm11', 'm15' )
	elseif returnType == 'RayHitInfo' then
		return pushNumbers( 'hit', 'distance', 'position.x', 'position.y', 'position.z', 'normal.x', 'normal.y', 'normal.z' )
	else
		UNIMPLEMENTED_RETURNS[returnType] = true
		return 'UNIMPLEMENTED_FOR_' .. returnType .. '(L, result)', 1, true
	end
end

local UNIMPLEMETED_ARGS = {}

local function nCheckNumbers( index, n )
	local t = {}
	for i = 1, n do
		t[i] = 'luaL_checknumber(L, ' .. (index+i-1) .. ')'
	end
	return table.concat( t, ', ' )
end

local function formatResourceType( res )
	return res:match('%s*%*?%s*(%w+)')
end

local function argConvert( argType, index )
	if argType == 'int' or
		argType == 'unsigned' or
		argType == 'unsigned int' or
		argType == 'unsigned char' then
		return '(' .. argType .. ')luaL_checkinteger(L, ' .. index .. ')'
	elseif
		argType == 'long' or
		argType == 'float' or
		argType == 'double' or
		argType == 'char' or
		argType == 'bool' then
		return '(' .. argType .. ')luaL_checknumber(L, ' .. index .. ')'
	elseif argType == 'const char *' or argType == 'char *' then
		return '(' .. argType .. ') luaL_checkstring(L, ' .. index .. ')'
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
		return 'GetColor(luaL_checkinteger(L, ' .. index .. '))'
	elseif isResource( argType ) then
		return '*raylua_Deref' .. argType .. 'Handler(L, luaL_checkinteger(L, ' .. index .. '))'
	elseif isResourceReference( argType ) then
		return 'raylua_Deref' .. formatResourceType( argType ) .. 'Handler(L, luaL_checkinteger(L, ' .. index .. '))'
	else
		UNIMPLEMETED_ARGS[argType] = true
		return 'UNIMPLEMENTED_FOR_' .. argType, index, true
	end
end

local function printStruct( structName, structFields )
	pp([[
typedef struct Wrapped${structName} {
  ${structName} content;
  int released;
} Wrapped${structName};
]], {structName = structName})

	for i, type_name in ipairs(structFields) do
		local resultType, name = type_name[1], type_name[2]
		local converter, returnCount = returnConvert( resultType )
		returnCount = returnCount or 1
		
		pp([[
static int raylua_${structName}_get_${name}(lua_State *L)
{
  Wrapped${structName} *obj = luaL_checkudata(L, 1, "raylua_${structName}");
  if (obj->content == NULL) return luaL_error(L, "Resource[${structName}] was released");
  ${resultType} result = obj->content.${name};
  ${converter};
  return ${returnCount};
}
]], {
		structName = structName,
		name = name,
		resultType = resultType,
		returnCount = returnCount,
		converter = converter
	})
 	end

	pp([[
static int raylua_${structName}_metatable_gc(lua_State *L)
{
  Wrapped${structName} *obj = luaL_checkudata(L, 1, "raylua_${structName}");
  if (!obj->released)
  {
    Unload${structName}(obj->content);
    obj->released = 1;
  }
  return 0;
}

static const luaL_Reg raylua_${structName}_metatable = {
  {"__gc", raylua_${structName}_metatable_gc},]], {structName = structName})

	for i, type_name in ipairs(structFields) do
		pp([[
  {"${name}", raylua_${structName}_get_${name}},]], {
		name = type_name[2],
		structName = structName
	})
	end
	pp([[
  {NULL, NULL}
};
]],{})

	pp([[
static void raylua_${structName}_metatable_register(lua_State *L)
{
  luaL_newmetatable(L, "raylua_${structName}");
  lua_pushvalue(L, -1):
  lua_setfield(L, -2, "__index")
  luaL_register(L, NULL, raylua_${structName}_metatable);
}

static void raylua_${structName}_wrap(lua_State *L, ${structName} *content)
{
  Wrapped${structName} *ud = lua_newuserdata(L, sizeof *ud);
  ud->content = *content;
  ud->released = 0;
  luaL_setmetatable(L, "raylua_${structName}");
}
]], {structName = structName})
end

local constants = {}
local state, t, iscomment
local struct, fields
for s in io.lines('raylib/src/raylib.h') do
	if s:match('%s+%/%*') then
		scomment = true
	else
		if s:match('%s+%*%/') then
			iscomment = nil
		elseif state == nil then
			t = s:match('typedef struct (%w+) {')
			if t and isResource( t ) then
				state = 'readstruct'
				struct, fields = t, {}
			end
			if not t then
				-- parse numeric const
				local constName, constValue = s:match('#define%s+([%w_]-)%s+([%d.]+)')
				if constValue then
					constants[constName] = constValue
				end
			end
		elseif state == 'readstruct' then
			if s:match('%s*}%s*' .. t ..'%s*;') then
				state = nil
				printStruct( struct, fields )
			else
				local ftype, fname = s:match('%s*(%w+)%s+(%w+)%s*;')
				if ftype and fname then
					fields[#fields+1] = {ftype, fname}
				end
			end
		end
	end
end
