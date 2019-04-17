local converter = require( 'converter' )

return function( conf, defs )
	local prefix = conf.prefix
	print( '// Autogenerated library bindings ' .. conf.libname .. ' from ' .. defs.header )
	print( '// Generator by iskolbin https://github.com/iskolbin/lraylib-gen' )
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
	local funcNames = {}
	for i, f in ipairs( defs.funcs ) do
		funcNames[i] = f.name
		if f.comment then
			print( '// ' .. f.comment )
		end
		print( 'static int ' .. prefix .. f.name .. '(lua_State *L) {' )	
		if (not args or #args == 0) and not f.returns then
			print( '  (void)L; // Suppress unused warning' )
		end
		local argNames = {}
		for i, name_type in ipairs( f.args or {} ) do
			local argName, argType = name_type[1], name_type[2]
			argNames[i] = argName
			local argConverter = converter.luaToC( argType, i )
			print( '  ' .. argType .. ' ' .. argName .. ' = ' .. argConverter .. ';' )
		end
		if f.returns then
			print( '  ' .. f.returns .. ' result = ' .. f.name .. '(' .. table.concat( argNames, ', ' ) .. ');' )
			local returnConverter, returnCount = converter.cToLua( f.returns )
			print( '  ' .. returnConverter .. ';' )
			print( '  return ' .. (returnCount or 1) .. ';' )
		else
			print( '  ' .. f.name .. '(' .. table.concat( argNames, ', ' ) .. ');' )
			print( '  return 0;' )
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
	print( '// Lua 5.1 compatibility' )
	print( '#if (LUA_VERSION_NUM <= 501)' )
	print( '#define LUAMOD_API LUALIB_API' )
	print( '#define luaL_newlib(L,lib) luaL_register(L,"' .. conf.libname .. '",lib)' )
	print( '#endif' )
	print()
	print( 'LUAMOD_API int luaopen_' .. conf.libname .. '(lua_State *L) {' )
	print( '  luaL_newlib(L, ' .. prefix .. 'functions);' )
	print( '  return 1;' )
	print( '}' )
end
