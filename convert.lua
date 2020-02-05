print('{')

local defs = require('raylib_defs')

local function sorted(tt)
	local t = {}
	for name, conf in pairs(tt) do
		if not conf.name then conf.name = name end
		t[#t+1] = conf
	end
	table.sort(t, function(a, b) return a.name < b.name end)
	return t
end

local function converttype(type_)
	local t = {}
	local const = type_:match('const%s+'); if const then type_ = type_:gsub(const, ''); t[#t+1] = '"const": true' end
	local volatile = type_:match('volatile'); if volatile then type_ = type_:gsub(volatile, ''); t[#t+1] = '"volatile": true' end
	local unsigned = type_:match('unsigned%s+'); if unsigned then type_ = type_:gsub(unsigned, ''); t[#t+1] = '"unsigned": true' end
	local signed = type_:match('signed%s+'); if signed then type_ = type_:gsub(signed, ''); t[#t+1] = '"signed": true' end
	local longlong = type_:match('long%s+long%s+'); if longlong then type_ = type_:gsub(longlong, ''); t[#t+1] = '"longlong": true' end
	local long = type_:match('long%s+'); if long then type_ = type_:gsub(long, ''); t[#t+1] = '"long": true' end
	local short = type_:match('short%s+'); if short then type_ = type_:gsub(short, ''); t[#t+1] = '"short": true' end
	type_ = type_:gsub(' ', '')
	table.insert(t, 1, '"type": "' .. type_ .. '"')
	return table.concat(t, ', ')
end

local structs = sorted(defs.structs)
print('  "structs": [')
for i, conf in ipairs(structs) do
	print('    {')
	print('      "name": "' .. conf.name .. '",')
	print('      "fields": [')
	for j, field in ipairs(conf.fields) do
		local type_ = field[2]
		print('        {"name": "' .. field[1] .. '", ' .. converttype(field[2]) .. '}' .. (j == #conf.fields and '' or ','))
	end
	print('      ]')
	print('    }' .. (i == #structs and '' or ','))
end
print('  ],')

print('  "functions": [')
local funcs = sorted(defs.funcs)
for i, conf in ipairs(funcs) do
	print('    {')
	print('      "name": "' .. conf.name .. '",')
	if conf.args then
		print('      "args": [')
		for j, arg in ipairs(conf.args) do
			print('        {"name": "' .. arg[1] .. '", ' .. converttype(arg[2]) .. '}' .. (j==#conf.args and '' or ','))
		end
		print('      ],')
	end
	if conf.returns then
		print('      "returns": {' .. converttype(conf.returns) .. '},')
	end
	if conf.vararg then
		print('      "vararg": true,')
	end
	print('      "comment": "' .. (conf.comment or ''):gsub('\\', '\\\\') .. '"')
	print('    }' .. (i==#funcs and '' or ','))
end
print('  ]')
print('}')
