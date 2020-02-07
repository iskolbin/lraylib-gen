local libname = 'raylib'
local prefix = 'l_' .. libname .. '_'

local function readfile(filename)
	local f = io.open(filename, 'r')
	local s = 'return ' .. f:read('all'):gsub('"(%w+)":', '%1 = '):gsub('%[', '{'):gsub('%]', '}')
	f:close()
	return (loadstring or load)(s)()
end

local defs = readfile(...)

local integersmap = {
	char = true, int = true, long = true, short = true, unsigned = true, signed = true,
	uint8_t = true, uint16_t = true, uint32_t = true, uint64_t = true,
	int8_t = true, int16_t = true, int32_t = true, int64_t = true
}

local numbersmap = {
	double = true, float = true
}

local structsmap = {}
for _, conf in pairs(defs.structs) do
	structsmap[conf.name] = conf
end

local opaquemap = {}
for _, conf in pairs(defs.opaque) do
	opaquemap[conf.name] = conf
end

local function fromlua(stackidx, type_)
	local typename = type_.type
	if typename == 'cstring' and indirection == 1 then
		return 'luaL_checkstring(L, ' .. stackidx .. ');'
	elseif type_.indirection then
		return 'luaL_error("Cannot index indirect fields");'
	elseif typename == 'char' and not type_.unsigned and not type_.signed and #(type_.length or {}) == 1 then
		return 'luaL_checkstring(L, ' .. stackidx .. ');'
	elseif type_.length then
		return 'luaL_error("Cannot index arrays");'
	elseif typename == 'bool' then
		return 'lua_toboolean(L, ' .. stackidx .. ')'
	elseif integersmap[typename] then
		return 'luaL_checkinteger(L, '.. stackidx .. ')'
	elseif numbersmap[typename] then
		return 'luaL_checknumber(L, ' .. stackidx .. ')'
	elseif typename == 'cstring' then
		return 'luaL_checkstring(L, ' .. stackidx .. ')'
	elseif structsmap[typename] then
		return 'luaL_checkudata(L, ' .. stackidx .. ', "' .. typename .. '")'
	elseif opaquemap[typename] or typename == 'untyped' then
		return 'lua_touserdata(L, ' .. stackidx .. ')' 
	else
		return 'luaL_error(L, "Unsupported type");'
	end
end

local function tolua(name, type_)
	local typename = type_.type
	if typename == 'bool' then
		return 'lua_pushboolean(L, ' .. name .. ');'
	elseif integersmap[typename] then
		return 'lua_pushinteger(L, ' .. name .. ');'
	elseif numbersmap[typename] then
		return 'lua_pushnumber(L, ' .. name .. ');'
	elseif typename == 'cstring' then
		return 'lua_pushstring(L, ' .. name .. ');'
	elseif structsmap[typename] then
		return typename .. '* userdata = lua_newuserdata(L, sizeof *userdata); *userdata = ' .. name .. '; luaL_setmetatable(L, "' .. typename .. '");'
	elseif opaquemap[typename] or typename == 'untyped' then
		return 'if (' .. name .. ' == NULL) lua_pushnil(L); else lua_pushlightuserdata(L, ' .. name .. ');'
	else
		return 'lua_pushnil(L);'
	end
end

for i, struct in ipairs(defs.structs) do
	print('static int ' .. prefix .. struct.name .. '__index(lua_State *L) {')
	print('  ' .. struct.name .. ' *obj = ' .. fromlua(-2, {type = struct.name}) .. ';')
	print('  const char *name = luaL_checkstring(L, -1);')
	for j, field in ipairs(struct.fields) do
		print('  if (strlen(name, "' .. field.name .. '") == 0) {')
		print('    ' .. tolua('obj->' .. field.name, field))
		print('    return 1;')
		print('  }')
	end
	print('  return 0;')
	print('}')
	print()
	print('static int ' .. prefix .. struct.name .. '__newindex(lua_State *L) {')
	print('  ' .. struct.name .. ' *obj = ' .. fromlua(-3, {type = struct.name}) .. ';')
	print('  const char *name = luaL_checkstring(L, -2);')
	for j, field in ipairs(struct.fields) do
		print('  if (strlen(name, "' .. field.name .. '") == 0) {')
		print('    obj->' .. field.name .. ' = ' .. fromlua(-1, field) .. ';')
		print('    return 0;')
		print('  }')
	end
	print('  return 0;')
	print('}')
	print()
end

for i, struct in ipairs(defs.structs) do
	print('static const luaL_Reg ' .. prefix .. struct.name .. '[] = {')
	for j, field in ipairs(struct.fields) do
	end
	print('  {"__index", ' .. prefix .. struct.name .. '__index},')
	print('  {"__newindex", ' .. prefix .. struct.name .. '__newindex},')
	print('  {NULL, NULL}')
	print('};')
	print()
end

for i, func in ipairs(defs.functions) do
	print('static int l_raylib_' .. func.name .. '(lua_State *L) {')
	if not func.args and not func.returns then
		print( '  (void)L; // Suppress unused warning' )
	end
	local strargs = {}
	if func.args then
		for j, arg in ipairs(func.args) do
			print('  ' .. arg.type .. ' ' .. arg.name .. ' = ' .. fromlua(-#func.args+j-1, arg) .. ';')
			strargs[j] = arg.name
		end
	end
	print('  ' .. (func.returns and (func.returns.type .. ' result = ') or '') .. func.name .. '(' .. table.concat(strargs, ', ') .. ');')
	if func.returns then
		print('  ' .. tolua('result', func.returns))
	end
	print('  return ' .. (func.returns and '1' or '0') .. ';') 
	print('}')
	print()
end
