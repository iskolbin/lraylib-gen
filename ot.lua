return function()
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
		__len = function( self )
			return 0
		end,
	})
end
