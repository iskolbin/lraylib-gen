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

static int raylua_CheckCollisionRaySphereEx(lua_State *L)
{
  Ray ray = (Ray) {{luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3)},{luaL_checknumber(L, 4), luaL_checknumber(L, 5), luaL_checknumber(L, 6)}};
  Vector3 spherePosition = (Vector3) {luaL_checknumber(L, 7), luaL_checknumber(L, 8), luaL_checknumber(L, 9)};
  float sphereRadius = (float) luaL_checknumber(L, 10);
  Vector3 collisionPoint;
	if (CheckCollisionRaySphereEx(ray, spherePosition, sphereRadius, &collisionPoint))
  {
    lua_pushnumber(L, collisionPoint.x);
    lua_pushnumber(L, collisionPoint.y);
    lua_pushnumber(L, collisionPoint.z);
    return 3;
	}
  return 0;
}

static int raylua_LoadModelAnimations(lua_State *L)
{
  int count = 0;
  ModelAnimation *animations = LoadModelAnimations(luaL_checkstring(L, 1), &count);
  for (int i = 0; i < count; i++) raylua_ModelAnimation_wrap(L, animations+i);
	return count;
}

static int raylua_DrawPolyEx(lua_State *L)
{
  int len = raylua_tablelen(L, 1) / 2;
  Color color = GetColor(luaL_checkinteger(L, 2));
	Vector2 *points = malloc( len * sizeof * points );
	for (int i = 0; i < len; i += 2)
  {
    lua_rawgeti(L, 1, i);
		points[i].x = luaL_checknumber(L, -1);
    lua_rawgeti(L, 2, i);
		points[i].y = luaL_checknumber(L, -1);
  }
  DrawPolyEx(points, len, color);
	free(points);
	return 0;
}

static int raylua_DrawPolyExLines(lua_State *L)
{
  int len = raylua_tablelen(L, 1) / 2;
  Color color = GetColor(luaL_checkinteger(L, 2));
	Vector2 *points = malloc( len * sizeof * points );
	for (int i = 0; i < len; i += 2)
  {
    lua_rawgeti(L, 1, i);
		points[i].x = luaL_checknumber(L, -1);
    lua_rawgeti(L, 2, i);
		points[i].y = luaL_checknumber(L, -1);
  }
  DrawPolyExLines(points, len, color);
	free(points);
	return 0;
}
]]

return {
	'Sleep',
	'CloseWindow',
	'GetDroppedFiles',
	'GetDirectoryFiles',
	'CheckCollisionRaySphereEx',
	'LoadModelAnimations',
	'DrawPolyEx',
	'DrawPolyExLines',
}
