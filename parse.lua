local function parseType( body )
	local items = {}
	for item in body:gmatch( '%s?([%w%*]+)' ) do
		local frontStars, trimmedItem = item:match('(%**)(.+)')
		if #frontStars > 0 then
			items[#items+1] = frontStars
		end
		items[#items+1] = trimmedItem
	end
	local name, type_ = items[#items], table.concat( items, ' ', 1, #items-1 )
	return name, type_
end

return function( fileName, apiDef, aliases )
	local s = nil
	local alreadyProcessed = {}
	print( 'return {' )
	print( '  header = ' .. ('%q'):format( fileName ) .. ',' )
	print( '  funcs = {' )
	local bodyName, bodyArgs, comment
	for line in io.lines( fileName ) do
		-- Multiline support
		if s then
			s = s:sub( 1, -2 ) .. line
		end
		if line:match( '^(%u+)' ) == apiDef then
			s = line
		end
		if s and s:match( '%)' ) then
			-- Varargs
			local varargIndex
			s, varargIndex = s:gsub( '%,%s%.%.%.', '' )
			local isVararg = varargIndex > 0

			if apiDef == 'RLAPI' then
				bodyName, bodyArgs, comment = s:match( 'RLAPI (.+)%((.-)%);%s*//%s*(.+)' )
			else
				bodyName, bodyArgs = s:match( apiDef .. ' (.-)%((.-)%)' )
			end

			-- Parse function name and return type
			local funcName, returnType = parseType( bodyName )
			if not alreadyProcessed[funcName] then
				alreadyProcessed[funcName] = true
				io.write( '    ' .. funcName .. ' = {' )
				returnType = aliases[returnType] or returnType
				local fields = {}

				-- Parse arguments
				if bodyArgs ~= 'void' then
					local i = 0
					local args = {}
					for arg in bodyArgs:gmatch( '([%w%s%*]+)' ) do
						i = i + 1
						local argName, argType = parseType( arg )
						argName = aliases[argName] or argName
						args[i] = '{"' .. argName .. '", "' .. argType .. '"}'
					end
					if i > 0 then
						fields[#fields+1] = 'args = {' .. table.concat( args, ', ' ) .. '}'
					end
				end

				if isVararg then
					fields[#fields+1] = 'vararg = true'
				end
				if returnType ~= 'void' then
					fields[#fields+1] = 'returns = "' .. returnType .. '"'
				end
				if comment ~= nil and comment ~= '' then
					fields[#fields+1] = 'comment = ' .. ( '%q' ):format( comment )
				end
				io.write( table.concat( fields, ', ' ))
				print( '},' )
				s = nil
			else
				local newComment = line:match('//%s*(.+)')
				if newComment then
					comment = comment and ( comment .. ' ' .. newComment ) or newComment
				else
					comment = nil
				end
			end
		end
	end
	print( '  },' )

	print( '  consts = {' )
	local isReadingEnum = false
	for line in io.lines( fileName ) do
		if not isReadingEnum and line:match( '^typedef enum ' ) then
			local alreadyRead = false
			for enumValue in (line:match( '%{%s*([%w%_%, ]+)%s*%}' ) or ''):gmatch( '([%w%_]+)' ) do
				alreadyRead = true
				print( '    "' .. enumValue .. '",' )
			end
			isReadingEnum = not alreadyRead
		elseif isReadingEnum then
			if line:match( '}' ) then
				isReadingEnum = false
			else
				if not line:match( '%s*//' ) then
					local name = line:match( '%s*([%u%dx_]+)' )
					if name then
						print( '    {"' .. name .. '","int"},' )
					end
				end
			end
		else
			local name, value = line:match( '#define%s+([%u_]+)%s+([%d%.fF%+%-]+)' )
			if name then
				value = value:gsub( 'f', '' )	
				if tonumber( value ) == math.floor( tonumber( value )) then
					print( '    {"' .. name .. '","int"},' )
				else
					print( '    {"' .. name .. '","float"},' )
				end
			end
		end
	end
	print( '  },' )

	print( '  structs = {' )
	local isReadingStruct, isComment = false, false
	for line in io.lines( fileName ) do
		if line:match('%s+%/%*') then
			isComment = true
		else
			if line:match('%s+%*%/') then
				isComment = false
			elseif isReadingStruct then
				local isFinishStruct = line:match( '%s*}%s*([%w %*%,]+)%s*;' )
				if isFinishStruct then
					isReadingStruct = false
					print( '    },' )
				else
					local fieldType, fieldNames, fieldLength = line:match( '%s*([%w %*_]+)%s+([%w%, %*_]+)%s*%[([%w_]+)%];' )
					if not fieldLength then
						fieldType, fieldNames = line:match( '%s*([%w %*_]+)%s+([%w%, %*_]+)%s*;' )
						fieldLength = ''
					else
						fieldLength = tonumber( fieldLength ) and (', %d'):format( fieldLength ) or (', "' .. fieldLength .. '"')
					end
					if fieldType and fieldNames then
						for nameStars in fieldNames:gmatch( '([%w%*]+)' ) do
							local name, stars = nameStars:match( '(%w+)' ), nameStars:match( '(%*+)' ) or ''
							print( '      {"' .. name .. '", "' .. fieldType .. stars .. '"' .. fieldLength .. '},' )
						end
					end
				end
			else
				local T = line:match( 'typedef struct%s-(%w-)%s*{' )
				if T then
					isReadingStruct = true
					print( '    ' .. T .. ' = {' )
				end
			end
		end
	end
	print( '  }' )
	print( '}' )
end
