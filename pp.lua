return function ( str, substitutesTable )
	if substitutesTable then
		print(( str:gsub( '%$%{(%w-)%}', substitutesTable )))
	else
		print( str )
	end
end
