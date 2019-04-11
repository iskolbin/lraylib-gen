local pp = require('pp')
local parseType = require( 'converter' ).parseType
local luaToC = require( 'converter' ).luaToC
local cToLua = require( 'converter' ).cToLua
local isBlacklisted = require( 'blacklisted' ).isBlacklisted

return function( fileName )
	local nFuncs, nUnimplemented, nUnimplenentedArgs, nUnimplementedReturns, implementedFunctionNames = 0, 0, 0, 0, {}
	local s = nil
	for line in io.lines( fileName ) do
		-- Multiline support
		if s then
			s = s:sub(1,-2) .. line
		end
		if line:sub(1,5) == 'RLAPI' then
			s = line
		end

		if s and s:match(';') then
			-- Varargs (not implemented)
			local varargIndex
			s, varargIndex = s:gsub('%,%s%.%.%.', '')
			local funcVararg = varargIndex > 0

			local bodyName, bodyArgs, comment = s:match( 'RLAPI (.+)%((.-)%);%s*//%s*(.+)' )
			-- Parse function name and return type
			local funcName, funcReturnType = parseType( bodyName )

			local funcCode = {}
			if not isBlacklisted( funcName ) then
				-- Parse function arguments and their types
				local funcArgs, funcArgsNames = {}, {}
				if bodyArgs ~= 'void' then
					for bodySingleArg in bodyArgs:gmatch( '([%w%s%*]+)' ) do
						funcArgs[#funcArgs+1] = {parseType( bodySingleArg )}
						funcArgsNames[#funcArgsNames+1] = funcArgs[#funcArgs][1]
					end
				end
				nFuncs = nFuncs + 1
				-- (void)L added to silence unused warnings
				funcCode[#funcCode+1] = ( '\n// %s\nstatic int raylua_%s(lua_State *L)\n{\n  (void)L;' ):format( comment, funcName )
				local i, unimplementedArgConvert, unimplemented = 0, false, false
				for _, arg in ipairs( funcArgs ) do
					i = i + 1
					local argName, argType = arg[1], arg[2]
					local converted, j, unimplementedCurrentArgConvert = luaToC( argType, i )
					if j and j > i then
						i = j
					end
					unimplementedArgConvert = unimplementedArgConvert or unimplementedCurrentArgConvert
					funcCode[#funcCode+1] = ( '  %s %s = %s;'):format( argType, argName, converted )
				end
				local result, resultCount = funcReturnType .. ' result = ', 1
				if funcReturnType == 'void' then
					result, resultCount = '', 0
				end

				funcCode[#funcCode+1] = ( '  %s %s(%s);' ):format( result, funcName, table.concat( funcArgsNames, ', ' ))

				if unimplementedArgConvert then
					nUnimplenentedArgs = nUnimplenentedArgs + 1
					unimplemented = true
				end

				if resultCount > 0 then
					local convertedResult, newCount, unimplementedReturn = cToLua( funcReturnType )
					if newCount and newCount > 1 then
						resultCount = newCount
					end
					funcCode[#funcCode+1] = ( '  ' .. convertedResult ..';' )

					if unimplementedReturn then
						nUnimplementedReturns = nUnimplementedReturns + 1
						unimplemented = true
					end
				end

				if funcVararg then
					unimplemented = true
				end

				if unimplemented then
					nUnimplemented = nUnimplemented + 1
				end

				funcCode[#funcCode+1] = ( '  return ' .. resultCount .. ';')
				funcCode[#funcCode+1] = ( '}' )
				if unimplemented then
					pp('// ${funcName} is not implemented', {funcName = funcName} )
				else
					implementedFunctionNames[#implementedFunctionNames+1] = funcName
					print( table.concat( funcCode, '\n' ))
				end
			end
			s = nil
		end
	end
	return nFuncs, nUnimplemented, nUnimplenentedArgs, nUnimplementedReturns, implementedFunctionNames
end
