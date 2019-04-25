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

local function OrderedTable()
	local content = {}
	return setmetatable( {}, {
		__index = function( self, k )
			for i = 1, #content do
				if content[i][1] == k then
					return content[i][2]
				end
			end
		end,
		__newindex = function( self, k, v )
			for i = 1, #content do
				if content[i][1] == k then
					if k == nil then
						table.remove( content, i )
					else
						content[i][2] = v
					end
					return
				end
				table.insert( content, {k, v} )
			end
		end,
		__pairs = function( self )
			local idx = 0
			return function()
				idx = idx + 1
				return content[idx][1], content[idx][2]
			end
		end,
	})
end

return function( fileName, apiDef, aliases )
	local s = nil
	local alreadyProcessed = {}

	local function unalias( t )
		if not t or not aliases then return t end
		t = t:gsub( '%s+%*', '*' )
		local t, count = t:gsub( '%*', '' )
		return (aliases[t] or t) .. ('*'):rep( count )
	end

	local api = {
		header = ('%q'):format( fileName ),
		funcs = {},
		consts = {},
	}

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
				local func = { name = funcName }
				--io.write( '    ' .. funcName .. ' = {' )
				returnType = unalias( returnType )

				local fields = {}
				-- Parse arguments
				if bodyArgs ~= 'void' then
					local i = 0
					local args = {}
					for arg in bodyArgs:gmatch( '([%w%s%*]+)' ) do
						i = i + 1
						local argName, argType = parseType( arg )
						argType = unalias( argType )
						args[i] = {argName, argType}
						--args[i] = '{"' .. argName .. '", "' .. argType .. '"}'
					end
					if i > 0 then
						func.args = args
						--fields[#fields+1] = 'args = {' .. table.concat( args, ', ' ) .. '}'
					end
				end

				if isVararg then
					func.vararg = true
					--fields[#fields+1] = 'vararg = true'
				end
				if returnType ~= 'void' then
					--returnType = unalias( returnType )
					func.returns = unalias( returnType )
					--fields[#fields+1] = 'returns = "' .. returnType .. '"'
				end
				if comment ~= nil and comment ~= '' then
					func.comment = comment
					--fields[#fields+1] = 'comment = ' .. ( '%q' ):format( comment )
				end
				--io.write( table.concat( fields, ', ' ))
				--print( '},' )
				api.funcs[#api.funcs+1] = func
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
	--print( '  },' )

	--print( '  consts = {' )
	local isReadingEnum = false
	for line in io.lines( fileName ) do
		if not isReadingEnum and line:match( '^typedef enum ' ) then
			local alreadyRead = false
			for enumValue in (line:match( '%{%s*([%w%_%, ]+)%s*%}' ) or ''):gmatch( '([%w%_]+)' ) do
				alreadyRead = true
				
				--print( '    "' .. enumValue .. '",' )
			end
			isReadingEnum = not alreadyRead
		elseif isReadingEnum then
			if line:match( '}' ) then
				isReadingEnum = false
			else
				if not line:match( '^%s*//' ) then
					local name = line:match( '%s*([%u%dx_]+)' )
					if name then
						api.consts[#api.consts+1] = {name, "int"}
						--print( '    {"' .. name .. '", "int"},' )
					end
				end
			end
		else
			local name, value = line:match( '#define%s+([%u_]+)%s+([%d%.fF%+%-]+)' )
			if name then
				value = value:gsub( 'f', '' )	
				if tonumber( value ) == math.floor( tonumber( value )) then
					api.consts[#api.consts+1] = {name, "int"}
					--print( '    {"' .. name .. '", "int"},' )
				else
					api.consts[#api.consts+1] = {name, "float"}
					--print( '    {"' .. name .. '", "float"},' )
				end
			end
		end
	end
	--print( '  },' )

	local function processStructArrayFields( trimmedFieldType, fieldLength )
		local fieldType, starsCount = trimmedFieldType:gsub( '%*', '' )
		if fieldLength == '' and starsCount > 0 and (fieldType == 'unsigned char' or fieldType == 'int' or fieldType == 'float' or fieldType == 'unsigned short' or fieldType == 'short' or fieldType:sub(1,1):match('%u')) then
			return fieldType .. ('*'):rep(starsCount-1), ', "DYNAMIC"'
		else
			return trimmedFieldType, fieldLength
		end
	end

	--print( '  structs = {' )
	local struct = {}
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
					--print( '    },' )
				else
					local fieldType, fieldNames, fieldLength = line:match( '%s*([%w %*_]+)%s+([%w%, %*_]+)%s*%[([%w_]+)%];' )
					if not fieldLength then
						fieldType, fieldNames = line:match( '%s*([%w %*_]+)%s+([%w%, %*_]+)%s*;' )
					else
						fieldLength = tonumber( fieldLength ) and tonumber( fieldLength ) or fieldLength
					end
					if fieldType and fieldNames then
						for nameStars in fieldNames:gmatch( '([%w%*]+)' ) do
							local name, stars = nameStars:match( '(%w+)' ), nameStars:match( '(%*+)' ) or ''
							local trimmedFieldType = (fieldType .. stars):gsub( '%s+%*', '*' )
							fieldType, fieldLength = processStructArrayFields( trimmedFieldType, fieldLength )
							fieldType = unalias( fieldType )
							local field = {name, fieldType}
							if fieldLength then
								field[#field+1] = fieldLength
							end
							struct.fields[#struct.fields+1] = field
						end
					end
				end
			else
				local T = line:match( 'typedef struct%s-(%w-)%s*{' )
				if T then
					isReadingStruct = true
					struct = {
						name = T,
						fields = {}
					}
				end
			end
		end
	end
	return api
	--print( '  }' )
	--print( '}' )
end
