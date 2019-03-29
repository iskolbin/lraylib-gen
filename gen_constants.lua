local pp = require('pp')

return function( fileName )
	local prevValue
	for line in io.lines( fileName ) do
		local name, value = line:match( '%s*([%u%d_]+)%s*=%s*(%d+)' )
		if name and value then
			prevValue = tonumber(value)
			pp( '  lua_pushnumber(L, ${value}); lua_setfield(L, -2, "${name}");', {value = tonumber(value), name = name} )
		elseif prevValue and not line:match(';') then
			name = line:match( '([%u%d_]+)' )
			if name then
				prevValue = prevValue + 1
				pp( '  lua_pushnumber(L, ${prevValue}); lua_setfield(L, -2, "${name}");', {prevValue = prevValue, name = name} )
			else
				prevValue = nil
			end
		end
		local colorName, r, g, b, a = line:match( '#define%s+([%u_]+)%s+CLITERAL%{ (%d+), (%d+), (%d+), (%d+) }' )
		if colorName then
			local rgba = math.floor( tonumber(r) * 2^24 + tonumber(g) * 2^16 + tonumber(b) * 2^8 + tonumber(a))
			pp( '  lua_pushinteger(L, ${rgba}); lua_setfield(L, -2, "${colorName}");', {rgba = rgba, colorName = colorName} )
		end
	end
end
