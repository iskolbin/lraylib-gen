local pp = require( 'pp' )
local resourcesList = require( 'resources' ).list

pp[[
#define ISL_SLEEP_IMPLEMENTATION
#include "isl_sleep/isl_sleep.h"

static int raylua_Sleep(lua_State *L) {
  int us = luaL_checkinteger(L, -1);
  isl_usleep(us);
  return 0;
}

static int raylua_CloseWindow(lua_State *L) {
  // Make resources not managable by the GC to avoid segfault and let CloseWindow
  // release all resources
]]
for _, resourceName in pairs( resourcesList ) do
pp([[
  luaL_getmetatable(L, "raylua_${resourceName}");
  lua_pushnil(L);
  lua_setfield(L, -2, "__gc");]], {resourceName = resourceName})
end
pp[[
  CloseWindow();
  return 0;
}
]]

return {
	'Sleep',
	'CloseWindow',
}
