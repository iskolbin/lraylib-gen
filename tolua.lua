local libname = 'raylib'
local prefix = 'l_' .. libname .. '_'

local function readfile(filename)
	local f = io.open(filename, 'r')
	local s = 'return ' .. f:read('all'):gsub('"(%w+)":', '%1 = '):gsub('%[', '{'):gsub('%]', '}')
	f:close()
	return (loadstring or load)(s)()
end

local defs = readfile(...)

local structsmap, opaquemap = {}, {}
local intsmap = {
	int = true, long = true, short = true, unsigned = true, signed = true,
	uint8_t = true, uint16_t = true, uint32_t = true, uint64_t = true,
	int8_t = true, int16_t = true, int32_t = true, int64_t = true
}
local floatsmap = {
	double = true, float = true
}

for _, conf in pairs(defs.structs) do
	structsmap[conf.name] = conf
end
for _, conf in pairs(defs.opaque) do
	opaquemap[conf.name] = conf
end

local function fromlua(stackidx, type_)
	local typename = type_.type
	if typename == 'bool' then
		return 'lua_toboolean(L, ' .. stackidx .. ')'
	elseif intsmap[typename] then
		return 'lua_pushinteger(L, '.. stackidx .. ')'
	elseif floatsmap[typename] then
		return 'lua_pushnumber(L, ' .. stackidx .. ')'
	elseif structsmap[typename] then
		return 'luaL_checkudata(L, ' .. stackidx .. ', "' .. typename .. '")'
	else
		return 'ERROR' .. tostring(type_.type)
	end
end

local function tolua(name, type_)
	local typename = type_.type
	if typename == 'bool' then
		return 'lua_pushboolean(L, ' .. name .. ');'
	elseif intsmap[typename] then
		return 'lua_pushinteger(L, ' .. name .. ');'
	elseif floatsmap[typename] then
		return 'lua_pushnumber(L, ' .. name .. ');'
	elseif type_ == 'cstring' then
		return 'lua_pushstring(L, ' .. name .. ');'
	elseif structsmap[typename] then
		return typename .. '* udata = lua_newuserdata(L, sizeof *udata); *udata = ' .. name .. '; luaL_setmetatable(L, "' .. typename .. '");'
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
		print('    ' .. fromlua(-1, field)) 
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

--[[
for i, func in ipairs(defs.functions) do
	print('static int l_raylib_' .. func.name .. '(lua_State *L) {')
	--for j, arg in ipairs(func.args) do
	--	print('  ' .. arg.type .. ' ' .. arg.name .. ' = '
	--end
	print('  return ' .. (func.returns and '1' or '0')) 
	print('}')
end
--]]
