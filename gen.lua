local fileName = assert( select( 1, ... ))

local pp = require( 'pp' )
local converter = require( 'converter' )

require( 'gen_intro' )
require( 'gen_struct' )( fileName )

local nFuncs, nUnimplemented, nUnimplenentedArgs, nUnimplementedReturns, implementedFunctionNames = require( 'gen_functions' )( fileName )
for _, funcName in ipairs( require( 'gen_hand_functions' )) do
	implementedFunctionNames[#implementedFunctionNames+1] = funcName
end

pp[[

static const luaL_Reg raylua_functions[] = {]]
for _, funcName in ipairs( implementedFunctionNames ) do
	pp( '  {"${funcName}", raylua_${funcName}},', {funcName = funcName} )
end
  pp[[{NULL, NULL}
};

LUAMOD_API int luaopen_raylua (lua_State *L) {]]
for _, struct in ipairs( require( 'resources' ).resourcesList ) do
  pp('  raylua_' .. struct .. '_register(L);' )
end
  pp[[
  luaL_newlib(L, raylua_functions);]]
	require( 'gen_constants' )( fileName )
pp([[
  return 1;
}

// Summary
// wrapped functions: ${nFuncs}, unimplemented: ${nUnimplemented}]], {nFuncs = nFuncs, nUnimplemented = nUnimplemented} )

require( 'gen_outro' )( converter.UNIMPLEMETED_ARGS, converter.UNIMPLEMENTED_RETURNS, nUnimplenentedArgs, nUnimplementedReturns )
