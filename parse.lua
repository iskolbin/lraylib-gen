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

	local function unalias( t )
		if not t or not aliases then return t end
		t = t:gsub( '%s+%*', '*' )
		local t, count = t:gsub( '%*', '' )
		return (aliases[t] or t) .. ('*'):rep( count )
	end

	local api = {
		header = fileName,
		funcs = {},
		enums = {},
		consts = {},
		structs = {},
		opaque = {},
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

			bodyName, bodyArgs = s:match( apiDef .. ' (.-)%((.-)%)' )
			comment = line:match('//%s*(.+)')

			-- Parse function name and return type
			local funcName, returnType = parseType( bodyName )
			if not alreadyProcessed[funcName] then
				alreadyProcessed[funcName] = true
				local func = { name = funcName }
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
						args[i] = {name = argName, type = argType}
					end
					if i > 0 then
						func.args = args
					end
				end

				if isVararg then
					func.vararg = true
				end
				if returnType ~= 'void' then
					func.returns = unalias( returnType )
				end
				if comment ~= nil and comment ~= '' then
					func.comment = comment
				end
				func.name = funcName
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

	local isReadingEnum, enum = false, nil
	for line in io.lines( fileName ) do
		if not isReadingEnum and line:match( '^typedef enum ' ) then
			local alreadyRead = false
			for enumValue in (line:match( '%{%s*([%w%_%, ]+)%s*%}' ) or ''):gmatch( '([%w%_]+)' ) do
				alreadyRead = true
			end
			isReadingEnum = not alreadyRead
			enum = {values = {}}
		elseif isReadingEnum then
			local enumName = line:match( '}%s*([%S]+)%s*;')
			if enumName then
				isReadingEnum = false
				enum.name = enumName
				api.enums[#api.enums+1] = enum
				enum = {values = {}}
			else
				if not line:match( '^%s*//' ) then
					local name = line:match( '%s*([%u%dx_]+)' )
					if name then
						local value = line:match( '=%s*([%S]+)%s*,' )
						local newComment = line:match('//%s*(.+)')
						enum.values[#enum.values+1] = {name = name, value = value and tonumber(value) or nil, comment = newComment}
					end
				end
			end
		else
			local name, value = line:match( '#define%s+([%u_]+)%s+([%d%.fF%+%-]+)' )
			if name then
				value = value:gsub( 'f', '' )	
				if tonumber( value ) == math.floor( tonumber( value )) then
					api.consts[#api.consts+1] = {name, "int"}
				else
					api.consts[#api.consts+1] = {name, "float"}
				end
			else
				name, value = line:match( '#define%s+([%u_]+)%s+CLITERAL' )
				if name then
					api.consts[#api.consts+1] = {name, "Color"}
				end
			end
		end
	end

	local function processStructArrayFields( trimmedFieldType, fieldLength )
		local fieldType, starsCount = trimmedFieldType:gsub( '%*', '' )
		if not fieldLength and starsCount > 0 and (fieldType == 'unsigned char' or fieldType == 'int' or fieldType == 'float' or fieldType == 'unsigned short' or fieldType == 'short' or fieldType:sub(1,1):match('%u')) then
			return fieldType .. ('*'):rep(starsCount-1), '?'
		else
			return trimmedFieldType, fieldLength
		end
	end

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
							local field = {name = name, type = fieldType}
							if fieldLength then
								field.length = fieldLength
							end
							local newComment = line:match('//%s*(.+)')
							field.comment = newComment
							struct.fields[#struct.fields+1] = field
						end
					end
				end
			else
				local structName = line:match( 'typedef struct%s-(%w-)%s*{' )
				if structName then
					isReadingStruct = true
					struct = {name = structName, fields = {}}
					api.structs[#api.structs+1] = struct
				else
					local structName, ref = line:match( 'typedef struct%s+(%w+)%s*%*-%s*(%w+)%s*;' )
					if structName and ref then
						api.opaque[#api.opaque+1] = {name = structName}
					end
				end
			end
		end
	end

	for _, struct in ipairs( api.structs ) do
		local structName = struct.name
		local countsMap = {}
		for _, name_count in ipairs( struct.counts or {} ) do
			countsMap[name_count[1]] = name_count[2]
		end
		local fieldsMap, fieldCounts = {}, {}
		for _, field in ipairs( struct.fields ) do
			local fieldName = field.name
			fieldsMap[fieldName] = field
			if fieldName:sub( -5 ) == 'Count' then
				fieldCounts[fieldName] = true
			end
		end
		for nameCount in pairs( fieldCounts ) do
			local singular = nameCount:sub( 1, -6 )
			local field = fieldsMap[singular] or fieldsMap[singular .. 's'] or fieldsMap[singular .. 'es'] or fieldsMap[singular:sub( 1, -3 ) .. 'ices']
			if field then
				local fieldName = field.name
				field.constraint = nameCount
				if not countsMap[fieldName] then
					countsMap[fieldName] = nameCount
				end
			end
		end
		local counts = {}
		for name, count in pairs( countsMap ) do
			counts[#counts+1] = {name, count}
		end
		table.sort( counts, function( a, b ) return a[1] < b[1] end )
		if next( counts ) then
			struct.counts = counts
		end
	end
	return api
end
