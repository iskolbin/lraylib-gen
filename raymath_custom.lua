return {
	funcs = {
		QuaternionToAxisAngle = {src = [[
  Quaternion q = (*(Quaternion*)luaL_checkudata(L, 1, "Quaternion"));
  Vector3 *outAxis = lua_newuserdata(L, sizeof *outAxis); luaL_setmetatable(L, "Vector3");
  float outAngle;
  QuaternionToAxisAngle(q, outAxis, &outAngle);
  lua_pushnumber(L, outAngle);
  return 2;]]
		},

		Vector3OrthoNormalize = {src = [[
  Vector3 *v1 = luaL_checkudata(L, 1, "Vector3");
  Vector3 *v2 = luaL_checkudata(L, 2, "Vector3");
  Vector3OrthoNormalize(v1, v2);
  return 0;]]
		},
	},

	structs = {
		float3 = {
			fields = {{"v", "float", 3}},
		},
		float16 = {
			fields = {{"v", "float", 16}},
		},
	},
}			
