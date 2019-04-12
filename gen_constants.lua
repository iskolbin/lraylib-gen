local pp = require('pp')

return function( fileName )
	local isReadEnum = false
	for line in io.lines( fileName ) do
		if not isReadEnum and line:match( '^typedef enum {$' ) then
			isReadEnum = true
		elseif isReadEnum then
			if line:match('}') then
				isReadEnum = false
			else
				if not line:match('%s*//') then
					local name = line:match( '%s*([%u%dx_]+)' )
					if name then
						pp( '  lua_pushnumber(L, ${name}); lua_setfield(L, -2, "${name}");', {name = name} )
					end
				end
			end
		else
			local name = line:match( '#define%s+([%u%d_x]+)%s+CLITERAL' )
			if name then
				pp( '  lua_pushinteger(L, ColorToInt(${name})); lua_setfield(L, -2, "${name}");', {name = name} )
			end
		end
	end
	for _, name in ipairs{'MAX_TOUCH_POINTS', 'MAX_SHADER_LOCATIONS', 'MAX_MATERIAL_MAPS'} do
		pp('  lua_pushinteger(L, ${name}); lua_setfield(L, -2, "${name}");', {name = name})
	end
end
