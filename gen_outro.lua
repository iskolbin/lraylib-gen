local pp = require( 'pp' )

return function( UNIMPLEMETED_ARGS, UNIMPLEMENTED_RETURNS, nUnimplenentedArgs, nUnimplementedReturns )
if next( UNIMPLEMETED_ARGS ) then
	pp( '// unimplemented argument conversions: ${nUnimplenentedArgs} functions', {nUnimplenentedArgs = nUnimplenentedArgs} )
end
for name in pairs( UNIMPLEMETED_ARGS ) do
	print( '//', name )
end
if next( UNIMPLEMENTED_RETURNS ) then
	pp( '// unimplemented return conversions: ${nUnimplementedReturns} functions', {nUnimplementedReturns = nUnimplementedReturns} )
end
for name in pairs( UNIMPLEMENTED_RETURNS ) do
	print( '//', name )
end
end
