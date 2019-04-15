local pp = require( 'pp' )
local resourcesList = require( 'resources' ).resourcesList

pp[[
#define ISL_SLEEP_IMPLEMENTATION
#include "isl_sleep/isl_sleep.h"

// Sleeps for microseconds
static int lua_raylib_Sleep(lua_State *L)
{
  int us = luaL_checkinteger(L, -1);
  isl_usleep(us);
  return 0;
}

// Close window and unload OpenGL context
static int lua_raylib_CloseWindow(lua_State *L)
{
  // Make resources not managable by the GC to avoid segfault and let CloseWindow
  // release all resources
]]
for _, resourceName in pairs( resourcesList ) do
pp([[
  luaL_getmetatable(L, "lua_raylib_${resourceName}");
  lua_pushnil(L);
  lua_setfield(L, -2, "__gc");]], {resourceName = resourceName})
end
pp[[
  CloseWindow();
  return 0;
}

// Get filenames in a directory path (memory should be freed)
static int lua_raylib_GetDirectoryFiles(lua_State *L)
{
  int count;
  char **files = GetDirectoryFiles(luaL_checkstring(L, -1), &count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDirectoryFiles();
  return count;
}

// Get dropped files names (memory should be freed)
static int lua_raylib_GetDroppedFiles(lua_State *L)
{
  int count;
  char **files = GetDroppedFiles(&count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDroppedFiles();
  return count;
}

// Detect collision between ray and sphere, returns collision point
static int lua_raylib_CheckCollisionRaySphereEx(lua_State *L)
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

// Load model animations from file
static int lua_raylib_LoadModelAnimations(lua_State *L)
{
  int count = 0;
  ModelAnimation *animations = LoadModelAnimations(luaL_checkstring(L, 1), &count);
  for (int i = 0; i < count; i++) lua_raylib_ModelAnimation_wrap(L, animations+i);
	return count;
}

// Draw a closed polygon defined by points
static int lua_raylib_DrawPolyEx(lua_State *L)
{
  int len = lua_raylib_tablelen(L, 1) / 2;
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

// Draw polygon lines
static int lua_raylib_DrawPolyExLines(lua_State *L)
{
  int len = lua_raylib_tablelen(L, 1) / 2;
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

// Returns the rotation angle and axis for a given quaternion
static int lua_raylib_QuaternionToAxisAngle(lua_State *L)
{
  Quaternion q = (Quaternion) {luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3), luaL_checknumber(L, 4)};
  Vector3 outAxis;
  float outAngle;
  QuaternionToAxisAngle(q, &outAxis, &outAngle);
  lua_pushnumber(L, outAxis.x);
  lua_pushnumber(L, outAxis.y);
  lua_pushnumber(L, outAxis.z);
  lua_pushnumber(L, outAngle);
  return 4;
}

// Orthonormalize provided vectors, makes vectors normalized and orthogonal to each other, Gram-Schmidt function implementation 
static int lua_raylib_Vector3OrthoNormalize(lua_State *L)
{
  Vector3 v1 = (Vector3) {luaL_checknumber(L, 1), luaL_checknumber(L, 2), luaL_checknumber(L, 3)};
  Vector3 v2 = (Vector3) {luaL_checknumber(L, 4), luaL_checknumber(L, 5), luaL_checknumber(L, 6)};
  Vector3OrthoNormalize(&v1, &v2);
  lua_pushnumber(L, v1.x);
  lua_pushnumber(L, v1.y);
  lua_pushnumber(L, v1.z);
  lua_pushnumber(L, v2.x);
  lua_pushnumber(L, v2.y);
  lua_pushnumber(L, v2.z);
  return 6;
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
	'QuaternionToAxisAngle',
	'Vector3OrthoNormalize',
}
