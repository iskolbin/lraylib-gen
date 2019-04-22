local isInt = {
	['int'] = true, ['unsigned'] = true, ['unsigned int'] = true,
	['signed int'] = true, ['signed'] = true,
	['short int'] = true, ['unsigned short'] = true, ['unsigned short int'] = true,
	['signed short int'] = true, ['signed short'] = true,
	['char'] = true, ['unsigned char'] = true, ['signed char'] = true,
}

local isNumber = {
	['long'] = true, ['unsigned long'] = true, ['unsigned long int'] = true,
	['signed long'] = true, ['signed long int'] = true,
	['float'] = true, ['double'] = true,
}

local function tolua( T )
	if isInt[T] then
		return 'lua_pushinteger(L, result)'
	elseif isNumber[T] then
		return 'lua_pushnumber(L, result)'
	elseif T == 'const char *' or T == 'char *'  or T == 'const char*' or T == 'char*' then
		return 'lua_pushstring(L, result)'
	elseif T == 'bool' then
		return 'lua_pushboolean(L, result)'
	elseif T == 'void *' or T == 'const void *' or T == 'void*' or T == 'const void*' then
		return 'lua_pushlightuserdata(L, result)'
	else
		local Tref = T:match( '(%w+)%s*%*' )
		if Tref then
			return Tref .. '* userdata = lua_newuserdata(L, sizeof *userdata); *userdata = *result; luaL_setmetatable(L, "' .. Tref .. '")'
		else
			return T .. '* userdata = lua_newuserdata(L, sizeof *userdata); *userdata = result; luaL_setmetatable(L, "' .. T .. '")'
		end
	end
end

local function fromlua( T, index )
	if isInt[T] then
		return 'luaL_checkinteger(L, ' .. index .. ')'
	elseif isNumber[T] then
		return 'luaL_checknumber(L, ' .. index .. ')'
	elseif T == 'const char *' or T == 'char *' then
		return 'luaL_checkstring(L, ' .. index .. ')'
	elseif T == 'bool' then
		return 'luaL_checknumber(L, ' .. index .. ')'
	elseif T == 'void *' or T == 'const void *' or T == 'void*' or T == 'const void*' then
		return 'luaX_checklightuserdata(L, ' .. index .. ', "?")'
	else
		local Tref = T:match( '(%w+)%s*%*' )
		if Tref then
			return '(' .. Tref .. '*)luaL_checkudata(L, ' .. index .. ', "' .. Tref .. '")'
		else
			return '(*(' .. T .. '*)luaL_checkudata(L, ' .. index .. ', "' .. T .. '"))'
		end
	end
end

local function merge( t, tomerge )
	for k, v in pairs( tomerge ) do
		if type( v ) == 'table' and type( t[k] ) == 'table' then
			t[k] = merge( t[k], v )
		else
			t[k] = v
		end
	end
	return t
end

return function( conf, defs, custom )
	if custom then
		defs = merge( defs, custom )
	end
	local prefix = conf.prefix
	print( '// Autogenerated library bindings ' .. conf.libname .. ' from ' .. defs.header )
	print( '// Generator by iskolbin https://github.com/iskolbin/lraylib-gen' )
	print()
	print( '#include <stdlib.h>' )
	print()
	print( '#define LUA_LIB' )
	print( '#include <lua.h>' )
	print( '#include <lauxlib.h>' )
	print( '#include <lualib.h>' )
	for _, define in ipairs( conf.defines or {} ) do
		print( '#define ' .. define )
	end
	for _, include in ipairs( conf.includes or {} ) do
		print( '#include "' .. include .. '"' )
	end
	print()
	print( '// Lua 5.1 compatibility' )
	print( '#if (LUA_VERSION_NUM <= 501)' )
	print( '#define LUAMOD_API LUALIB_API' )
	print( '#define luaL_newlib(L,lib) luaL_register(L,"' .. conf.libname .. '",lib)' )
	print( '#define luaL_setfuncs(L,l,z) luaL_register(L,NULL,l)' )
	print( '#define luaL_setmetatable(L,mt) luaL_getmetatable(L,mt);lua_setmetatable(L,-2)' )
	print( '#define lua_rawlen lua_objlen' )
	print( '#endif' )
	print()
	print( 'static void * luaX_checklightuserdata(lua_State *L, int index, const char *funcName) {' )
	print( '  if (lua_islightuserdata(L, index)) {' )
	print( '    return lua_touserdata(L, index);' )
	print( '  } else {' )
	print( '    luaL_error(L, "bad argument #%d to %s (lightuserdata expected, got %s)", index, funcName, lua_typename(L, index));' )
	print( '    return NULL;' )
	print( '  }' )
	print( '}' )
	print()
	local funcNames = {}
	for funcName, f in pairs( defs.funcs ) do
		funcNames[#funcNames+1] = funcName
		if f.comment then
			print( '// ' .. f.comment )
		end
		print( 'static int ' .. prefix .. funcName .. '(lua_State *L) {' )
		if f.blacklisted then
			print( 'return luaL_error(L, "' .. funcName .. ' is blacklisted");' )
		elseif f.src then
			print( f.src )
		else
			if (not f.args or #f.args == 0) and not f.returns then
				print( '  (void)L; // Suppress unused warning' )
			end
			local argNames = {}
			for i, name_type in ipairs( f.args or {} ) do
				local argName, argType = name_type[1], name_type[2]
				argNames[i] = argName
				local argConverter = fromlua( argType, i )
				print( '  ' .. argType .. ' ' .. argName .. ' = ' .. argConverter .. ';' )
			end
			if f.returns then
				print( '  ' .. f.returns .. ' result = ' .. funcName .. '(' .. table.concat( argNames, ', ' ) .. ');' )
				local returnConverter, returnCount = tolua( f.returns )
				print( '  ' .. returnConverter .. ';' )
				if (f.resultFinalizer) then
					print( '  ' .. f.resultFinalizer .. ';' )
				end
				print( '  return ' .. (returnCount or 1) .. ';' )
			else
				print( '  ' .. funcName .. '(' .. table.concat( argNames, ', ' ) .. ');' )
				print( '  return 0;' )
			end
		end
		print( '}' )
		print()
	end
	print( 'static const luaL_Reg ' .. prefix .. 'functions[] = {' )
	for _, funcName in ipairs( funcNames ) do
		print( '  {"' .. funcName .. '", ' .. prefix .. funcName .. '},' )
	end
	print( '  {NULL, NULL}' )
	print( '};' )
	print()
	for structName, structFields in pairs( defs.structs ) do
		for _, name_T_length in ipairs( structFields ) do
			local name, T, length = name_T_length[1], name_T_length[2], name_T_length[3]
			local getObj = '  ' .. structName .. '* obj = ' .. 'luaL_checkudata(L, 1, "' .. structName .. '");'
			print( 'static int ' .. prefix .. structName .. '_set_' .. name .. '(lua_State *L) {' )
			print( getObj )
			if length then
				print( '  int idx = luaL_checkinteger(L, 2);' )
				if length == "DYNAMIC" then
					print( '  if (idx < 0) return luaL_error(L, "Index out of bounds %d", idx);' )
				else
					print( '  if (idx < 0 || idx > ' .. length .. ') return luaL_error(L, "Index out of bounds %d (max %d)", idx, ' .. length .. ');' )
				end
				print( '  ' .. T .. ' ' .. name .. 'v = ' .. fromlua( T, 3 ) .. ';' )
				print( '  obj->' .. name .. '[idx] = ' .. name .. 'v;' )
			else
				print( '  ' .. T .. ' ' .. name .. ' = ' .. fromlua( T, 2 ) .. ';' )
				print( '  obj->' .. name .. ' = ' .. name .. ';' )
			end
			print( '  lua_pop(L, 1);' )
			print( '  return 1;' )
			print( '}' )
			print()
			print( 'static int ' .. prefix .. structName .. '_get_' .. name .. '(lua_State *L) {' )
			print( getObj )
			if length then
				print( '  int idx = luaL_checkinteger(L, 2);' )
				print( '  ' .. T .. ' result = obj->' .. name .. '[idx];' )
			else
				print( '  ' .. T .. ' result = obj->' .. name .. ';' )
			end
			print( '  ' .. tolua( T ) .. ';' )
			print( '  return 1;' )
			print( '}' )
			print()
		end
		print( 'static const luaL_Reg ' .. prefix .. structName .. '[] = {' )
		for _, name_T in ipairs( structFields ) do
			local name = name_T[1]
			local uppercasedName = name:sub( 1, 1 ):upper() .. name:sub( 2 )
			print( '  {"get' .. uppercasedName .. '", ' .. prefix .. structName .. '_get_' .. name .. '},' )
			print( '  {"set' .. uppercasedName .. '", ' .. prefix .. structName .. '_set_' .. name .. '},' )
		end
		print( '  {NULL, NULL}' )
		print( '};' )
		print()
		print( 'static void ' .. prefix .. structName .. '_register(lua_State *L) {' )
		print( '  luaL_newmetatable(L, "' .. structName .. '");' )
  	print( '  lua_pushvalue(L, -1);' )
  	print( '  lua_setfield(L, -2, "__index");' )
  	print( '  luaL_setfuncs(L, ' .. prefix .. structName .. ', 0);' )
		print( '  lua_pop(L, 1);' )
		print( '}' )
		print()
	end
	print( 'LUAMOD_API int luaopen_' .. conf.libname .. '(lua_State *L) {' )
	print( '  luaL_newlib(L, ' .. prefix .. 'functions);' )
	for structName in pairs( defs.structs ) do
		print( '  ' .. prefix .. structName .. '_register(L);' )
	end
	for _, const in ipairs( defs.consts ) do
		local name, type_ = const[1], const[2]
		print( '  lua_push' .. (type_ == 'int' and 'integer' or 'number') .. '(L, ' .. name .. '); lua_setfield(L, -2, "' .. name .. '");' ) 
	end
	print( '  return 1;' )
	print( '}' )
end
