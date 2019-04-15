local pp = require( 'pp' )
local resourcesList = require( 'resources' ).resourcesList
local cToLua = require( 'converter' ).cToLua
local finalizer = require( 'converter' ).finalizer

local function printStruct( structType, structFields )
	pp([[
typedef struct Wrapped${structType} {
  ${structType} content;
  int unloaded;
} Wrapped${structType};
]], {structType = structType, structType = structType})

	for i, type_name in ipairs(structFields) do
		local fieldType, fieldName = type_name[1], type_name[2]
		local converter, returnCount = cToLua( fieldType )
		returnCount = returnCount or 1

		if fieldType == 'Mesh' then
			fieldType = 'Mesh*'
		end

		pp([[
static int lua_raylib_${structType}_get_${fieldName}(lua_State *L)
{
  Wrapped${structType} *obj = luaL_checkudata(L, 1, "lua_raylib_${structType}");
  if (obj->unloaded) return luaL_error(L, "Resource[${structType}] was unloaded");
  ${fieldType} result = obj->content.${fieldName};
  ${converter};
  return ${returnCount};
}
]], {
		structType = structType,
		fieldName = fieldName,
		fieldType = fieldType,
		returnCount = returnCount,
		converter = converter
	})
 	end

	pp([[
static int lua_raylib_${structType}_unload(lua_State *L)
{
  Wrapped${structType} *obj = luaL_checkudata(L, 1, "lua_raylib_${structType}");
  if (!obj->unloaded)
  {
    ${finalizer}
		obj->unloaded = 1;
  }
  return 0;
}

static const luaL_Reg lua_raylib_${structType}[] = {
  {"__gc", lua_raylib_${structType}_unload},
  {"unload", lua_raylib_${structType}_unload},]], {
		structType = structType,
		finalizer = finalizer( structType, 'obj->content' ),
	})

	for i, type_name in ipairs( structFields ) do
		pp([[
  {"get${name}", lua_raylib_${structType}_get_${name}},]], {
		name = type_name[2],
		structType = structType,
	})
	end
	pp([[
  {NULL, NULL}
};
]],{})

	pp([[
static void lua_raylib_${structType}_register(lua_State *L)
{
  luaL_newmetatable(L, "lua_raylib_${structType}");
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  lua_raylib_register(L, lua_raylib_${structType});
}

static void lua_raylib_${structType}_wrap(lua_State *L, ${structType} *content)
{
  Wrapped${structType} *ud = lua_newuserdata(L, sizeof *ud);
  ud->content = *content;
  ud->unloaded = 0;
  luaL_setmetatable(L, "lua_raylib_${structType}");
}

static int lua_raylib_${structType}_getmetatable(lua_State *L)
{
  luaL_getmetatable(L, "lua_raylib_${structType}");
  return 1;
}
]], {structType = structType})
end

local function parseConstants( strings )
	local constants = {}
	local constName, constValue = s:match('#define%s+([%w_]-)%s+([%d.]+)')
	if constValue then
		constants[constName] = constValue
	end
	return constants
end

local function parseFields( T, strings )
	local iscomment = false
	local fields = {}
	local state = nil
	for _, s in ipairs( strings ) do
		if s:match('%s+%/%*') then
			iscomment = true
		else
			if s:match('%s+%*%/') then
				iscomment = nil
			elseif state == nil then
				if s:match('typedef struct ' .. T .. '%s*{') then
					state = 'readstruct'
				end
			elseif state == 'readstruct' then
				if s:match('%s*}%s*' .. T ..'%s*;') then
					state = nil
					return fields
				else
					local ftype, fname = s:match('%s*(%w+)%s+(%w+)%s*;')
					if ftype and fname then
						fields[#fields+1] = {ftype, fname}
					end
				end
			end
		end
	end
	return fields
end

return function( fileName )
	local constants = {}
	local state, t, iscomment
	local struct, fields
	local strings = {}
	for s in io.lines( fileName ) do
		strings[#strings+1] = s
	end
	for _, T in ipairs( resourcesList ) do
		printStruct( T, parseFields( T, strings ))
	end
end
