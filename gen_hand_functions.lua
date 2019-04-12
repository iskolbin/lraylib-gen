local pp = require( 'pp' )
local resourcesList = require( 'resources' ).resourcesList

pp[[
#define ISL_SLEEP_IMPLEMENTATION
#include "isl_sleep/isl_sleep.h"

static int raylua_Sleep(lua_State *L)
{
  int us = luaL_checkinteger(L, -1);
  isl_usleep(us);
  return 0;
}

static int raylua_CloseWindow(lua_State *L)
{
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

static int raylua_GetDirectoryFiles(lua_State *L)
{
  int count;
  char **files = GetDirectoryFiles(luaL_checkstring(L, -1), &count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDirectoryFiles();
  return count;
}

static int raylua_GetDroppedFiles(lua_State *L)
{
  int count;
  char **files = GetDroppedFiles(&count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDroppedFiles();
  return count;
}
]]

return {
	'Sleep',
	'CloseWindow',
	'GetDroppedFiles',
	'GetDirectoryFiles',
}
