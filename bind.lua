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

local function tolua( T, name, ref )
	name = name or 'result'
	if isInt[T] then
		return 'lua_pushinteger(L, ' .. name .. ');'
	elseif isNumber[T] then
		return 'lua_pushnumber(L, ' .. name .. ');'
	elseif T == 'const char*' or T == 'char*' then
		return 'lua_pushstring(L, ' .. name .. ');'
	elseif T == 'bool' then
		return 'lua_pushboolean(L, ' .. name .. ');'
	elseif  T == 'void*' or T == 'const void*' then
		return 'if (' .. name .. ' == NULL) lua_pushnil(L); else lua_pushlightuserdata(L, ' .. name .. ');'
	else
		local nilcheck = 'if (' .. name .. ' == NULL) lua_pushnil(L); else '
		if ref then
			if ref == 'OPAQUE' then
				return nilcheck .. '{ Opaque' .. T .. ' *userdata = lua_newuserdata(L, sizeof *userdata); userdata->data = ' .. name .. '; luaL_setmetatable(L, "' .. T .. '");}'
			else
				return nilcheck .. '{ ' .. T .. ' userdata = lua_newuserdata(L, sizeof *userdata); *userdata = *' .. name .. '; luaL_setmetatable(L, "' .. ref .. '");}'
			end
		else
			local Tref = T:match( '(%w+)%s*%*' )
			if Tref then
				return nilcheck .. '{ ' .. Tref .. '* userdata = lua_newuserdata(L, sizeof *userdata); *userdata = *' .. name .. '; luaL_setmetatable(L, "' .. Tref .. '");}'
			else
				return T .. '* userdata = lua_newuserdata(L, sizeof *userdata); *userdata = ' .. name .. '; luaL_setmetatable(L, "' .. T .. '");'
			end
		end
	end
end

local function fromlua( T, index, ref )
	if T == 'char *' or T == 'void *' or T == 'const void *' then error('!!') end
	if isInt[T] then
		return 'luaL_checkinteger(L, ' .. index .. ')'
	elseif isNumber[T] then
		return 'luaL_checknumber(L, ' .. index .. ')'
	elseif T == 'const char*' then
		return 'luaL_checkstring(L, ' .. index .. ')'
	elseif T == 'char*' then
		return '(char*)luaL_checkstring(L, ' .. index .. ')'
	elseif T == 'bool' then
		return 'lua_toboolean(L, ' .. index .. ')'
	elseif T == 'void*' or T == 'const void*' then
		return 'luaX_checklightuserdata(L, ' .. index .. ', "?")'
	else
		if ref then
			if ref == 'OPAQUE' then
				return '((Opaque' .. T .. '*)luaL_checkudata(L, ' .. index .. ', "' .. T .. '"))->data'
			else
				return '(' .. T .. ')luaL_checkudata(L, ' .. index .. ', "' .. ref .. '")'
			end
		else
			local Tref = T:match( '(%w+)%s*%*' )
			if Tref then
				return '(' .. Tref .. '*)luaL_checkudata(L, ' .. index .. ', "' .. Tref .. '")'
			else
				return '(*(' .. T .. '*)luaL_checkudata(L, ' .. index .. ', "' .. T .. '"))'
			end
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

	-- Primitive sturcts are structs with primitive fields only, Vector2 for instance
	local isPrimitiveStruct = {}
	for structName, struct in pairs( defs.structs ) do
		local primitive = true
		for _, name_T_length in ipairs( struct.fields ) do
			local name, T, length = name_T_length[1], name_T_length[2], name_T_length[3]
			if length or (not isInt[T] and not isNumber[T]) then
				primitive = false
			end
		end
		if primitive then
			isPrimitiveStruct[structName] = struct.fields
		end
	end
	local prefix = conf.prefix
	print( '// Autogenerated library bindings ' .. conf.libname .. ' from ' .. defs.header )
	print( '// Generator by iskolbin https://github.com/iskolbin/lraylib-gen' )
	print()
	print( '#include <stdlib.h>' )
	print( '#if (defined(PLATFORM_DESKTOP) || defined(PLATFORM_UWP)) && defined(_WIN32) && (defined(_MSC_VER) || defined(__TINYC__))' )
	print( '#include "external/dirent.h"    // Required for: DIR, opendir(), closedir() [Used in GetDirectoryFiles()]' )
	print( '#else' )
	print( '#include <dirent.h>             // Required for: DIR, opendir(), closedir() [Used in GetDirectoryFiles()]')
	print( '#endif' )
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
	print( 'static void *luaX_checklightuserdata(lua_State *L, int index, const char *funcName) {' )
	print( '  if (lua_islightuserdata(L, index)) {' )
	print( '    return lua_touserdata(L, index);' )
	print( '  } else {' )
	print( '    luaL_error(L, "bad argument #%d to %s (lightuserdata expected, got %s)", index, funcName, lua_typename(L, index));' )
	print( '    return NULL;' )
	print( '  }' )
	print( '}' )
	for refName, structName in pairs( defs.refs ) do
		if structName == 'OPAQUE' then
			print( 'typedef struct { void *data; } Opaque' .. refName .. ';' )
		end
	end
	print()
	for structName, struct in pairs( defs.structs ) do
		if not struct.pass and struct.typedef then
			print( 'typedef struct ' .. structName .. '{' )
			for _, field in ipairs( struct.fields ) do
				if field[3] then
					if field[3] == '?' then
						print( '  ' .. field[2] .. ' *' .. field[1] .. ';' )
					else
						print( '  ' .. field[2] .. ' ' .. field[1] .. '[' .. field[3] .. '];' )
					end
				else
					print( '  ' .. field[2] .. ' ' .. field[1] .. ';' )
				end
			end
			print( '} ' .. structName .. ';' )
		end
	end
	local funcNames = {}
	local unpackedFuncNames = {}
	local refs = conf.refs

	local function deref( T )
		if refs[T] then
			return refs[T] .. '*'
		else
			return T
		end
	end
	
	for funcName, f in pairs( defs.funcs ) do
		local returns = f.returns
		local hasPrimitives = isPrimitiveStruct[returns]
		funcNames[#funcNames+1] = funcName
		if f.comment then
			print( '// ' .. f.comment )
		end
		print( 'static int ' .. prefix .. funcName .. '(lua_State *L) {' )
		if f.pass then
			print( 'return luaL_error(L, "' .. funcName .. ' is pass");' )
		elseif f.src then
			print( f.src )
		else
			if (not f.args or #f.args == 0) and not returns then
				print( '  (void)L; // Suppress unused warning' )
			end
			local argNames = {}
			for i, name_type in ipairs( f.args or {} ) do
				local argName, argType = name_type[1], name_type[2]
				if isPrimitiveStruct[argType] then
					hasPrimitives = true
				end
				argNames[i] = argName
				local argConverter = fromlua( argType, i, defs.refs[argType] )
				print( '  ' .. argType .. ' ' .. argName .. ' = ' .. argConverter .. ';' )
			end
			if returns then
				if f.wrap then
					print( '  ' .. returns .. ' result = ' .. f.wrap.name .. '(' .. table.concat( f.wrap.args or {}, ', ' ) .. ');' )
				else
					print( '  ' .. returns .. ' result = ' .. funcName .. '(' .. table.concat( argNames, ', ' ) .. ');' )
				end
				local returnConverter = tolua( returns, nil, defs.refs[returns] )
				print( '  ' .. returnConverter )
				if f.resultFinalizer then
					print( '  ' .. f.resultFinalizer .. ';' )
				end
				print( '  return 1;' )
			else
				if f.wrap then
					print( '  ' .. f.wrap.name .. '(' .. table.concat( f.wrap.args or {}, ', ' ) .. ');' )
				else
					print( '  ' .. funcName .. '(' .. table.concat( argNames, ', ' ) .. ');' )
				end
				print( '  return 0;' )
			end
		end
		print( '}' )
		print()

		-- Unpacked primitive arguments/returns version
		if hasPrimitives then
			local funcNameU = funcName .. 'U'
			unpackedFuncNames[#unpackedFuncNames+1] = funcNameU
			if f.comment then
				print( '// ' .. f.comment .. ' (unpacked version)' )
			end
			print( 'static int ' .. prefix .. funcNameU .. '(lua_State *L) {' )
			if f.pass then
				print( 'return luaL_error(L, "' .. funcNameU .. ' is pass");' )
			elseif f.src then
				print( f.src )
			else
				if (not f.args or #f.args == 0) and not returns then
					print( '  (void)L; // Suppress unused warning' )
				end
				local argNames = {}
				local index = 0
				for _, name_type in ipairs( f.args or {} ) do
					index = index + 1
					local argName, argType = name_type[1], name_type[2]
					argNames[#argNames+1] = argName
					if isPrimitiveStruct[argType] then
						local argsU = {}
						for i, name_type in ipairs( isPrimitiveStruct[argType] ) do
							argsU[#argsU+1] = fromlua( name_type[2], index + i - 1, defs.refs[name_type[2]] )
						end
						print( '  ' .. argType .. ' ' .. argName .. ' = {' .. table.concat( argsU, ',' ) .. '};' )
						index = index + #isPrimitiveStruct[argType] - 1
					else
						local argConverter = fromlua( argType, index, defs.refs[argType] )
						print( '  ' .. argType .. ' ' .. argName .. ' = ' .. argConverter .. ';' )
					end
				end
				if returns then
					if f.wrap then
						print( '  ' .. returns .. ' result = ' .. f.wrap.name .. '(' .. table.concat( f.wrap.args or {}, ', ' ) .. ');' )
					else
						print( '  ' .. returns .. ' result = ' .. funcName .. '(' .. table.concat( argNames, ', ' ) .. ');' )
					end
					local returnConverter = tolua( returns, nil, defs.refs[returns] )
					print( '  ' .. returnConverter )
					if f.resultFinalizer then
						print( '  ' .. f.resultFinalizer .. ';' )
					end
					if isPrimitiveStruct[returns] then
						local argsU = {}
						for i, name_type in ipairs( isPrimitiveStruct[returns] ) do
							argsU[#argsU+1] = tolua( name_type[2], 'result.' .. name_type[1], defs.refs[name_type[2]] )
						end
						print( '  ' .. table.concat( argsU ))
						print( '  return ' .. #argsU .. ';' )
					else
						print( '  return 1;' )
					end
				else
					if f.wrap then
						print( '  ' .. f.wrap.name .. '(' .. table.concat( f.wrap.args or {}, ', ' ) .. ');' )
					else
						print( '  ' .. funcName .. '(' .. table.concat( argNames, ', ' ) .. ');' )
					end
					print( '  return 0;' )
				end
			end
			print( '}' )
			print()
		end
	end

	-- Constructors for structs, for any structs zero constructor is exposed
	for structName, struct in pairs( defs.structs ) do
		if not struct.pass then
			print( 'static int ' .. prefix .. structName .. '_new(lua_State *L) {' )
			print( '  ' .. structName .. '* obj = lua_newuserdata(L, sizeof *obj); luaL_setmetatable(L, "' .. structName .. '");' )
			print( '  if (lua_gettop(L) == 1) {' )
			print( '   ' .. structName .. ' temp = {};' )
			print( '    *obj = temp;' )
			-- for primitive structs init-all-fields consturctor is also possible
			if isPrimitiveStruct[structName] then
				print( '  } else {' )
				for i, fieldName_Type in ipairs( struct.fields ) do
					local fieldName, fieldType = fieldName_Type[1], fieldName_Type[2]
					print( '    obj->' .. fieldName .. ' = ' .. fromlua( fieldType, i ) .. ';' )
				end
			end
			print( '  }' )
			print( '  return 1;' )
			print( '}' )
			print()
			print( 'static int ' .. prefix .. structName .. '_meta(lua_State *L) {' )
			print( '  luaL_getmetatable(L, "' .. structName .. '");' )
			print( '  return 1;' )
			print( '}' )
		end
	end

	print( 'static const luaL_Reg ' .. prefix .. 'functions[] = {' )
	-- Add module functions
	for _, funcName in ipairs( funcNames ) do
		print( '  {"' .. funcName .. '", ' .. prefix .. funcName .. '},' )
	end
	-- Add unpacked primitive args/return functions
	for _, funcName in ipairs( unpackedFuncNames ) do
		print( '  {"' .. funcName .. '", ' .. prefix .. funcName .. '},' )
	end
	-- Add constructors and metatable accessor for structs
	for structName, struct in pairs( defs.structs ) do
		if not struct.pass then
			print( '  {"' .. structName .. '", ' .. prefix .. structName .. '_new},' )
			print( '  {"' .. structName .. 'Meta", ' .. prefix .. structName .. '_meta},' )
		end
	end
	print( '  {NULL, NULL}' )
	print( '};' )
	print()

	-- Generate metatables for structs
	for structName, struct in pairs( defs.structs ) do
		if not struct.pass then
			local primitiveFields = isPrimitiveStruct[structName]
			if primitiveFields then
				-- Primitive structs have proper equality check
				print( 'static int ' .. prefix .. structName .. '__eq(lua_State *L) {' )
				print( '  lua_getmetatable(L, 1); lua_getmetatable(L, 2);' )
				print( '  if (lua_rawequal(L, -1, -2) == 0) {' )
				print( '    lua_pushboolean(L, 0);' )
				print( '  } else {' )
				print( '    ' .. structName .. ' *self = lua_touserdata(L, 1);' )
				print( '    ' .. structName .. ' *other = lua_touserdata(L, 2);' )
				io.write(   '    lua_pushboolean(L, ' )
				for i, fieldName_Type in ipairs( primitiveFields ) do
					io.write( i > 1 and ' && ' or '', 'self->', fieldName_Type[1], ' == other->', fieldName_Type[1] )
				end
				print( ');' )
				print( '  }' )
				print( '  return 1;' )
				print( '}' )
				print()
				-- Primitive structs have unpack method
				print( 'static int ' .. prefix .. structName .. '_unpack(lua_State *L) {' )
				print( '  ' .. structName .. ' *self = luaL_checkudata(L, 1, "' .. structName .. '");' )
				for i, fieldName_Type in ipairs( primitiveFields ) do
					local name, T = fieldName_Type[1], fieldName_Type[2]
					print( '  ' .. tolua( T, 'self->' .. name, defs.refs[T] ))
				end
				print( '  return ' .. #primitiveFields .. ';' )
				print( '}' )
				print()
			end

			local function plurify( name )
				if name:match( 'ices$' ) then
					return name:sub( 1, -5 ) .. 'ixAt'
				elseif name:match( 'es$' ) then
					return name:sub( 1, -3 ) .. 'At'
				elseif name:match( 's$' ) then
					return name:sub( 1, -2 ) .. 'At'
				else
					return name .. 'At'
				end
			end

			-- Generate setters and getters for structs as metamethods
			-- For array-like fields generate indexed getter/setter with boundary checking
			for _, name_T_length in ipairs( struct.fields ) do
				local name, T, length, lengthField = name_T_length[1], name_T_length[2], name_T_length[3], name_T_length[4]
				local getObj = '  ' .. structName .. '* obj = ' .. 'luaL_checkudata(L, 1, "' .. structName .. '");'
				local getIdx = '  int idx = luaL_checkinteger(L, 2);' 
				if length == "?" then
					if lengthField then
						getIdx = getIdx .. '\n  if (idx < 0 || idx >= obj->' .. lengthField .. ') return luaL_error(L, "Index out of bounds %d", idx);'
					else
						getIdx = getIdx .. '\n  if (idx < 0) return luaL_error(L, "Index out of bounds %d", idx);'
					end
				elseif length then
					getIdx = getIdx .. '\n  if (idx < 0 || idx >= ' .. length .. ') return luaL_error(L, "Index out of bounds %d", idx, ' .. length .. ');'
				end

				local name_ = length and plurify( name ) or name
				-- Setter
				print( 'static int ' .. prefix .. structName .. '_set_' .. name_ .. '(lua_State *L) {' )
				print( getObj )
				if length then
					print( getIdx )
					print( '  ' .. T .. ' ' .. name .. 'v = ' .. fromlua( T, 3, defs.refs[T]) .. ';' )
					print( '  obj->' .. name .. '[idx] = ' .. name .. 'v;' )
				else
					print( '  ' .. T .. ' ' .. name .. ' = ' .. fromlua( T, 2, defs.refs[T]) .. ';' )
					print( '  obj->' .. name .. ' = ' .. name .. ';' )
				end
				print( '  lua_pop(L, 1);' )
				print( '  return 1;' )
				print( '}' )
				print()

				-- Getter
				print( 'static int ' .. prefix .. structName .. '_get_' .. name_ .. '(lua_State *L) {' )
				print( getObj )
				if length then
					print( getIdx )
					print( '  ' .. T .. ' result = obj->' .. name .. '[idx];' )
				else
					print( '  ' .. T .. ' result = obj->' .. name .. ';' )
				end
				print( '  ' .. tolua( T, nil, defs.refs[T] ))
				print( '  return 1;' )
				print( '}' )
				print()

				if isPrimitiveStruct[T] then
					-- Setter unpacked
					print( 'static int ' .. prefix .. structName .. '_set_' .. name_ .. 'U(lua_State *L) {' )
					print( getObj )
					local argsU = {}
					if length then
						print( getIdx )
						local argsU = {}
						for i, name_type in ipairs( isPrimitiveStruct[T] ) do
							argsU[#argsU+1] = fromlua( name_type[2], i + 2, defs.refs[name_type[2]] )
						end
						print( '  ' .. T .. ' ' .. name .. 'v = {' .. table.concat( argsU, ', ' ) .. '};' )
						print( '  obj->' .. name .. '[idx] = ' .. name .. 'v;' )
					else
						for i, name_type in ipairs( isPrimitiveStruct[T] ) do
							argsU[#argsU+1] = fromlua( name_type[2], i + 1, defs.refs[name_type[2]] )
						end
						print( '  ' .. T .. ' ' .. name .. ' = {' .. table.concat( argsU, ', ' ) .. '};' )
						print( '  obj->' .. name .. ' = ' .. name .. ';' )
					end
					print( '  lua_pop(L, ' .. #argsU .. ');' )
					print( '  return 1;' )
					print( '}' )
					print()

					-- Getter unpacked
					print( 'static int ' .. prefix .. structName .. '_get_' .. name_ .. 'U(lua_State *L) {' )
					print( getObj )
					if length then
						print( getIdx )
						print( '  ' .. T .. ' result = obj->' .. name .. '[idx];' )
					else
						print( '  ' .. T .. ' result = obj->' .. name .. ';' )
					end
					local argsU = {}
					for i, name_type in ipairs( isPrimitiveStruct[T] ) do
						argsU[#argsU+1] = tolua( name_type[2], 'result.' .. name_type[1], defs.refs[name_type[2]] )
					end
					print( '  ' .. table.concat( argsU ))
					print( '  return ' .. #argsU .. ';' )
					print( '}' )
					print()
				end
			end

			print( 'static const luaL_Reg ' .. prefix .. structName .. '[] = {' )
			for _, name_T_length in ipairs( struct.fields ) do
				local name = name_T_length[1]
				local T = name_T_length[2]
				local length = name_T_length[3]
				name = length and plurify( name ) or name
				local uppercasedName = name:sub( 1, 1 ):upper() .. name:sub( 2 )
				print( '  {"get' .. uppercasedName .. '", ' .. prefix .. structName .. '_get_' .. name .. '},' )
				print( '  {"set' .. uppercasedName .. '", ' .. prefix .. structName .. '_set_' .. name .. '},' )
				if isPrimitiveStruct[T] then
					print( '  {"get' .. uppercasedName .. 'U", ' .. prefix .. structName .. '_get_' .. name .. 'U},' )
					print( '  {"set' .. uppercasedName .. 'U", ' .. prefix .. structName .. '_set_' .. name .. 'U},' )
				end
			end
			if isPrimitiveStruct[structName] then
				print( '  {"__eq", ' .. prefix .. structName .. '__eq},' )
				print( '  {"unpack", ' .. prefix .. structName .. '_unpack},' )
			end
			print( '  {NULL, NULL}' )
			print( '};' )
			print()
			print( 'static void ' .. prefix .. structName .. '_register(lua_State *L, const char *ref) {' )
			print( '  luaL_newmetatable(L, ref ? ref : "' .. structName .. '");' )
			print( '  lua_pushvalue(L, -1);' )
			print( '  lua_setfield(L, -2, "__index");' )
			print( '  luaL_setfuncs(L, ' .. prefix .. structName .. ', 0);' )
			print( '  lua_pop(L, 1);' )
			print( '}' )
			print()
		end
	end

	print( 'LUAMOD_API int luaopen_' .. conf.libname .. '(lua_State *L) {' )
	print( '  luaL_newlib(L, ' .. prefix .. 'functions);' )
	for structName, struct in pairs( defs.structs ) do
		if not struct.pass then
			print( '  ' .. prefix .. structName .. '_register(L, NULL);' )
		end
	end
	for refName, structName in pairs( defs.refs ) do
		if defs.structs[structName] ~= nil then
			print( '  ' .. prefix .. structName .. '_register(L, "' .. refName .. '");' )
		end
	end
	for _, const in ipairs( defs.consts ) do
		local name, type_ = const[1], const[2]
		if type_ == 'integer' then
			print( '  lua_pushinteger(L, ' .. name .. ');' )
		elseif type_ == 'number' then
			print( '  lua_pushnumber(L, ' .. name .. ');' )
		elseif type_ == 'Color' then
			print( '  *((Color *)lua_newuserdata(L, sizeof(Color))) = ' .. name .. '; luaL_setmetatable(L, "Color");' )
		else
			print( '  lua_pushnil(L);' )
		end
		print( '  lua_setfield(L, -2, "' .. name .. '");' )
	end
	print( '  return 1;' )
	print( '}' )
end
