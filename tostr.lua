local type, tostring, pairs = _G.type, _G.tostring, _G.pairs
local CONF = {
	indent = '  ',
	recursive = function( tbl, tables )
		return '"recursive ' .. tostring( tbl ) .. '"'
	end,
	array = '{%s}',
	arraysep = ', ',
	arraylimit = 120,
	table = '{%s}',
	tablesep = ',\n',
	keyvalue = ' = '
}

local function tostr( v, conf, indent, tables )
	conf = conf or CONF
	local T = type( v )
	if T == 'string' then
		return ( "%q" ):format( v )
	elseif T == 'number' or T == 'boolean' then
		return tostring( v )
	elseif T == 'table' then
		tables = tables or {}
		local indentation = (conf.indent or CONF.indent):rep( (indent or 0) + 1 )
		if tables[v] then
			return (conf.recursive or CONF.recursive)( v )
		end
		tables[v] = true
		local nkeys = 0
		for _ in pairs( v ) do
			nkeys = nkeys + 1
		end
		local buffer = {}
		local tables_ = setmetatable( {}, {__index = tables} )
		if nkeys == #v then
			for i = 1, #v do
				buffer[i] = tostr( v[i], conf, indent or 0, tables_ )
			end
			local str = table.concat( buffer, (conf.arraysep or CONF.arraysep))
			if #str <= (conf.arraylimit or CONF.arraylimit) then
				for k, v in pairs( tables_ ) do
					tables[k] = v
				end
				return (conf.array or CONF.array):format( str )
			else
				for i = 1, #v do
					buffer[i] = indentation .. tostr( v[i], conf, (indent or 0) + 1, tables )
				end
				return (conf.array or CONF.array):format( '\n' .. table.concat( buffer, (conf.tablesep or CONF.tablesep)) .. '\n' .. (conf.indent or CONF.indent):rep( indent or 0 ))
			end
		else
			for k, w in pairs( v ) do
				local line
				if type( k ) == 'string' and k:match( '^[%a_][%w_]*$' ) then
					line = k .. (conf.keyvalue or CONF.keyvalue).. tostr( w, conf, (indent or 0) + 1, tables )
				else
					line = '[' .. tostr( k, conf, (indent or 0) + 1, tables ) .. ']' .. (conf.keyvalue or CONF.keyvalue) .. tostr( w, conf, (indent or 0) + 1, tables )
				end
				buffer[#buffer+1] = indentation .. line
			end
			return (conf.table or CONF.table):format( '\n' .. table.concat( buffer, (conf.tablesep or CONF.tablesep)) .. '\n' .. (conf.indent or CONF.indent):rep( indent or 0 ))
		end
	else
		return ( "%q" ):format( v )
	end
end

return tostr
