local fileName = assert( select( 1, ... ))

local pp = require( 'pp' )
local converter = require( 'converter' )

require( 'gen_intro' )
require( 'gen_struct' )( fileName )

local nFuncs, nUnimplemented, nUnimplenentedArgs, nUnimplementedReturns, implementedFunctionNames = require( 'gen_functions' )( fileName )
pp[[

static const luaL_Reg raylua_functions[] = {
  {"Sleep", isl_Sleep},]]
for _, funcName in ipairs( implementedFunctionNames ) do
	pp( '  {"${funcName}", raylua_${funcName}},', {funcName = funcName} )
end

pp[[
  {NULL, NULL}
};

LUAMOD_API int luaopen_raylib (lua_State *L) {
  luaL_newlib(L, raylua_functions);]]
for _, struct in ipairs( require( 'resources' ).list ) do
  pp('  raylua_' .. struct .. '_metatable_register(L);' )
end
	require( 'gen_constants' )( fileName )
pp([[
  return 1;
}

// Summary
// wrapped functions: ${nFuncs}, unimplemented: ${nUnimplemented}]], {nFuncs = nFuncs, nUnimplemented = nUnimplemented} )

require( 'gen_outro' )( converter.UNIMPLEMETED_ARGS, converter.UNIMPLEMENTED_RETURNS, nUnimplenentedArgs, nUnimplementedReturns )
