local state, t, iscomment
for s in io.lines('raylib/src/raylib.h') do
	if s:match('%s+%/%*') then
		scomment = true
	else
		if s:match('%s+%*%/') then
			iscomment = nil
		elseif state == nil then
			t = s:match('typedef struct (%w+) {')
			if t then
				state = 'readstruct'
				--print(t)
			end
		elseif state == 'readstruct' then
			if s:match('%s*}%s*' .. t ..'%s*;') then
				state = nil
			else
				local ftype, fname = s:match('%s*(%w+)%s+(%w+)%s*;')
				if ftype and fname then
					print('Get' .. t .. fname:sub(1,1):upper() .. fname:sub(2))
				end
			end
		end
	end
end
