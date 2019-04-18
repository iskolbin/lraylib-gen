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

return {
	tolua = function( T )
		if isInt[T] then
			return 'lua_pushinteger(L, result)'
		elseif isNumber[T] then
			return 'lua_pushnumber(L, result)'
		elseif T == 'const char *' or T == 'char *' then
			return 'lua_pushstring(L, result)'
		elseif T == 'bool' then
			return 'lua_pushboolean(L, result)'
		else
			return T .. '* userdata = lua_newuserdata(L, sizeof *' .. T .. '); *userdata = result; luaL_setmetatable(L, "' .. T .. '")'
		end
	end,

	fromlua = function( T, index )
		if isInt[T] then
			return 'luaL_checkinteger(L, ' .. index .. ')'
		elseif isNumber[T] then
			return 'luaL_checknumber(L, ' .. index .. ')'
		elseif T == 'const char *' or T == 'char *' then
			return 'luaL_checkstring(L, ' .. index .. ')'
		elseif T == 'bool' then
			return 'luaL_checknumber(L, ' .. index .. ')'
		else
			return 'luaL_checkudata(L, ' .. index .. ', "' .. T .. '")'
		end
	end,
}
