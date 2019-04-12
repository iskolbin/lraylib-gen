local fileName = assert( select( 1, ... ))

local pp = require( 'pp' )
local converter = require( 'converter' )

pp[[
// DO NOT EDIT BY HAND, AUTOGENERATED CONTENT
// Bindings for raylib https://github.com/raysan5/raylib
// Generator by iskolbin https://github.com/iskolbin/lraylib-gen

#define LUA_LIB
#include <stdlib.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include "raylib.h"

#if(LUA_VERSION_NUM <= 501)
#define raylua_tablelen lua_objlen
#define raylua_register(L,l) luaL_register((L), NULL, (l))
#else
#define raylua_tablelen lua_rawlen
#define raylua_register(L,l) luaL_setfuncs((L), (l), 0)
#endif
]]


require( 'gen_struct' )( fileName )

local nFuncs, nUnimplemented, nUnimplenentedArgs, nUnimplementedReturns, implementedFunctionNames = require( 'gen_functions' )( fileName )
for _, funcName in ipairs( require( 'gen_handmade' )) do
	implementedFunctionNames[#implementedFunctionNames+1] = funcName
end

pp[[

static const luaL_Reg raylua_functions[] = {]]
for _, funcName in ipairs( implementedFunctionNames ) do
	pp( '  {"${funcName}", raylua_${funcName}},', {funcName = funcName} )
end
  pp[[
  {NULL, NULL}
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

if next( converter.UNIMPLEMETED_ARGS ) then
	pp( '// unimplemented argument conversions: ${nUnimplenentedArgs} functions', {nUnimplenentedArgs = nUnimplenentedArgs} )
end
for name in pairs( converter.UNIMPLEMETED_ARGS ) do
	print( '//', name )
end
if next( converter.UNIMPLEMENTED_RETURNS ) then
	pp( '// unimplemented return conversions: ${nUnimplementedReturns} functions', {nUnimplementedReturns = nUnimplementedReturns} )
end
for name in pairs( converter.UNIMPLEMENTED_RETURNS ) do
	print( '//', name )
end
