local pp = require( 'pp' )
local isResource = require( 'resources' ).isResource
local resourcesList = require( 'resources' ).list
local cToLua = require( 'converter' ).cToLua
local finalizer = require( 'converter' ).finalizer

local function printStruct( structType, structFields )
	pp([[
typedef struct Wrapped${structType} {
  ${structType} content;
  int released;
} Wrapped${structType};
]], {structType = structType, structType = structType})

	for i, type_name in ipairs(structFields) do
		local resultType, name = type_name[1], type_name[2]
		local converter, returnCount = cToLua( resultType )
		returnCount = returnCount or 1

		if resultType == 'Mesh' then
			resultType = 'Mesh*'
		end
		
		pp([[
static int raylua_${structType}_get_${name}(lua_State *L)
{
  Wrapped${contType} *obj = luaL_checkudata(L, 1, "raylua_${structType}");
  if (obj->released) return luaL_error(L, "Resource[${structType}] was released");
  ${resultType} result = obj->content.${name};
  ${converter};
  return ${returnCount};
}
]], {
		structType = structType,
		name = name,
		resultType = resultType,
		returnCount = returnCount,
		converter = converter
	})
 	end

	pp([[
static int raylua_${structType}_metatable__gc(lua_State *L)
{
  Wrapped${structType} *obj = luaL_checkudata(L, 1, "raylua_${structType}");
  if (!obj->released)
  {
    ${finalizer};
		obj->released = 1;
  }
  return 0;
}

static const luaL_Reg raylua_${structType}_metatable[] = {
  {"__gc", raylua_${structType}_metatable__gc},]], {
		structType = structType,
		finalizer = finalizer( structType, 'obj->content' ),
	})

	for i, type_name in ipairs( structFields ) do
		pp([[
  {"${name}", raylua_${structType}_get_${name}},]], {
		name = type_name[2],
		structType = structType,
	})
	end
	pp([[
  {NULL, NULL}
};
]],{})

	pp([[
static void raylua_${structType}_metatable_register(lua_State *L)
{
  luaL_newmetatable(L, "raylua_${structType}");
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
	raylua_register_metatable(L, raylua_${structType}_metatable);
}

static void raylua_${structType}_wrap(lua_State *L, ${structType} *content)
{
  Wrapped${structType} *ud = lua_newuserdata(L, sizeof *ud);
  ud->content = *content;
  ud->released = 0;
  luaL_setmetatable(L, "raylua_${structType}");
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
	local fields = {}
	for _, s in ipairs( strings ) do
		if s:match('%s+%/%*') then
			scomment = true
		else
			if s:match('%s+%*%/') then
				iscomment = nil
			elseif state == nil then
				if s:match('typedef struct ' .. T .. '{') then
					state = 'readstruct'
				end
			elseif state == 'readstruct' then
				if s:match('%s*}%s*' .. t ..'%s*;') then
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
