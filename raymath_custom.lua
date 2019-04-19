return {
	funcs = {
		QuaternionToAxisAngle = {src = [[
  Quaternion q = (*(Quaternion*)luaL_checkudata(L, 1, "Quaternion"));
  Vector3 *outAxis = lua_newuserdata(L, sizeof *outAxis); luaL_setmetatable(L, "Vector3");
  float outAngle;
  QuaternionToAxisAngle(q, outAxis, &outAngle);
  lua_pushnumber(L, outAngle);
  return 2;]]
		}
	},
	structs = {
		float3 = {
			{"v", "float", 3},
		},
		float16 = {
			{"v", "float", 16},
		},
	},
}			
