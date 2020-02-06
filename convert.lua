print('{')

local defs = require(...)

local function converttype(type_, length, constraint)
	local t = {}
	local const = type_:match('const%s+'); if const then type_ = type_:gsub(const, ''); t[#t+1] = '"const": true' end
	local volatile = type_:match('volatile'); if volatile then type_ = type_:gsub(volatile, ''); t[#t+1] = '"volatile": true' end
	local unsigned = type_:match('unsigned%s+'); if unsigned then type_ = type_:gsub(unsigned, ''); t[#t+1] = '"unsigned": true' end
	local signed = type_:match('signed%s+'); if signed then type_ = type_:gsub(signed, ''); t[#t+1] = '"signed": true' end
	local longlong = type_:match('long%s+long%s+'); if longlong then type_ = type_:gsub(longlong, ''); t[#t+1] = '"longlong": true' end
	local long = type_:match('long%s*'); if long then type_ = type_:gsub(long, ''); t[#t+1] = '"long": true' end
	local short = type_:match('short%s*'); if short then type_ = type_:gsub(short, ''); t[#t+1] = '"short": true' end
	local indirection = 0
	if length then if length ~= '?' then t[#t+1] = '"length": ' .. length else indirection = indirection + 1 end end
	if constraint then t[#t+1] = '"constraint": "' .. constraint .. '"' end
	type_ = type_:gsub(' ', '')
	local stars = type_:match('%*+'); if stars then type_ = type_:gsub(stars, ''); indirection = indirection + #stars end
	if type_ == 'void' and indirection > 0 then type_ = 'untyped' end--; indirection = indirection - 1 end
	if type_ == 'char' and indirection > 0 and not unsigned and not signed then type_ = 'cstring' end--; indirection = indirection - 1 end
	if indirection > 0 then t[#t+1] = '"indirection": ' .. indirection end
	if type_ == '' then type_ = 'int' end
	table.insert(t, 1, '"type": "' .. type_ .. '"')
	return table.concat(t, ', ')
end

local consts = defs.consts
if consts then
print('  "constants": [')
for i, conf in ipairs(consts) do
	print('    {"name": "' .. conf[1] .. '", "type": ' .. (tonumber(conf[2]) and conf[2] or ('"' .. tostring(conf[2]) .. '"')) .. '}' .. (i == #consts and '' or ','))
end
print('  ],')
else
print('  "constants": [],')
end

local opaque = defs.opaque
if opaque then
print('  "opaque": [')
for i, conf in ipairs(opaque) do
	print('    {"name": "' .. conf.name .. '"}' .. (i == #opaque and '' or ','))
end
print('  ],')
else
print('  "opaque": [],')
end

local enums = defs.enums
if enums then
print('  "enums": [')
for i, conf in ipairs(enums) do
	print('    {')
	print('      "name": "' .. conf.name .. '",')
	if conf.comment then print('      "comment": "' .. conf.comment .. '",') end
	print('      "values": [')
	for j, value in ipairs(conf.values) do
		print('        {"name": "' .. value.name .. '"' .. (value.value and (', "value": ' .. value.value) or '') .. (value.comment and (', "comment": "' .. value.comment .. '"') or '') .. '}' .. (j == #conf.values and '' or ','))
	end
	print('      ]')
	print('    }' .. (i == #enums and '' or ','))
end
print('  ],')
else
print('  "enums": [],')
end

local structs = defs.structs
if structs then
print('  "structs": [')
for i, conf in ipairs(structs) do
	print('    {')
	print('      "name": "' .. conf.name .. '",')
	if conf.comment then print('      "comment": "' .. conf.comment .. '",') end
	print('      "fields": [')
	for j, field in ipairs(conf.fields) do
		print('        {"name": "' .. field.name .. '", ' .. converttype(field.type, field.length, field.constraint) .. '}' .. (j == #conf.fields and '' or ','))
	end
	print('      ]')
	print('    }' .. (i == #structs and '' or ','))
end
print('  ],')
else
print('  "structs": [],')
end

print('  "functions": [')
local funcs = defs.funcs
if funcs then
for i, conf in ipairs(funcs) do
	print('    {')
	io.write('      "name": "' .. conf.name .. '"')
	if conf.comment then io.write(',\n      "comment": "' .. (conf.comment or ''):gsub('\\', '\\\\') .. '"') end
	if conf.args then
		io.write(',\n      "args": [')
		for j, arg in ipairs(conf.args) do
			io.write('\n        {"name": "' .. arg.name .. '", ' .. converttype(arg.type) .. '}' .. (j==#conf.args and '' or ','))
		end
		io.write('\n      ]')
	end
	if conf.returns then
		io.write(',\n      "returns": {' .. converttype(conf.returns) .. '}')
	end
	if conf.vararg then
		io.write(',\n      "vararg": true,')
	end
	print('\n    }' .. (i==#funcs and '' or ','))
end
print('  ]')
else
print('  "functions": []')
end

print('}')
