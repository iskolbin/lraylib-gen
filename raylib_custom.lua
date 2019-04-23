return {
	funcs = {
		GetDirectoryFiles = { src = [[
  int count;
  char **files = GetDirectoryFiles(luaL_checkstring(L, -1), &count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDirectoryFiles();
  return count;]]},

		GetDroppedFiles = { src = [[
  int count;
  char **files = GetDroppedFiles(&count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDroppedFiles();
  return count;
		]]},

		--GetDirectoryFiles = { resultFinalizer = 'ClearDirectoryFiles()' },

		--GetDroppedFiles = { resultFinalizer = 'ClearDroppedFiles()' },

		GetFileNameWithoutExt = { resultFinalizer = 'free((void*)result)' },

		CheckCollisionRaySphereEx = { src = [[
  Ray ray = (*(Ray*)luaL_checkudata(L, 1, "Ray"));
  Vector3 spherePosition = (*(Vector3*)luaL_checkudata(L, 2, "Vector3"));
  float sphereRadius = luaL_checknumber(L, 3);
  Vector3 *collisionPoint = lua_newuserdata(L, sizeof *collisionPoint);
	if (CheckCollisionRaySphereEx(ray, spherePosition, sphereRadius, collisionPoint)) {
    return 1;
	} else {
		lua_pop(L, 1);
  	return 0;
	}
	]]},

		LoadModelAnimations = { src = [[
  int count = 0;
  ModelAnimation *animations = LoadModelAnimations(luaL_checkstring(L, 1), &count);
  for (int i = 0; i < count; i++) {
    ModelAnimation *anim = lua_newuserdata(L, sizeof *anim); *anim = animations[i]; luaL_setmetatable(L, "ModelAnimation");
  }
  return count;]]},

		DrawPolyEx = { src = [[
  int len = lua_rawlen(L, 1) / 2;
  Color *color = luaL_checkudata(L, 2, "Color");
  Vector2 *points = malloc(len * sizeof * points);
  for (int i = 0; i < len; i += 2)
  {
    lua_rawgeti(L, 1, i);
		points[i].x = luaL_checknumber(L, -1);
    lua_rawgeti(L, 2, i);
		points[i].y = luaL_checknumber(L, -1);
  }
  DrawPolyEx(points, len, *color);
	free(points);
	return 0;
		]]},
	
		DrawPolyExLines = { src = [[
  int len = lua_rawlen(L, 1) / 2;
  Color *color = luaL_checkudata(L, 2, "Color");
  Vector2 *points = malloc(len * sizeof * points);
  for (int i = 0; i < len; i += 2)
  {
    lua_rawgeti(L, 1, i);
		points[i].x = luaL_checknumber(L, -1);
    lua_rawgeti(L, 2, i);
		points[i].y = luaL_checknumber(L, -1);
  }
  DrawPolyExLines(points, len, *color);
	free(points);
	return 0;
		]]},
	
		LoadMaterials = { src = [[
  int count;
  Material *materials = LoadMaterials(luaL_checkstring(L,1), &count);
	for (int i = 0; i < count; i++) {
    Material *material = lua_newuserdata(L, sizeof *material);
    *material = materials[i];
    luaL_setmetatable(L, "Material");
  }
  return count;
		]]},

		TextJoin = { returnsArgs = {{'count', 'int'}}, blacklisted = true },
		TextSplit = { blacklisted = true },
		TextAppend = { updatesArgs = {{'position', 'int'}}, blacklisted = true },
		TextReplace = { resultFinalizer = 'free((void*)result)' },
		TextInsert = { resultFinalizer = 'free((void*)result)' },
		DrawTextRecEx = { args = {
			{"font", "Font"}, {"text", "const char *"}, {"rec", "Rectangle"}, {"fontSize", "float"},
			{"spacing", "float"}, {"wordWrap", "bool"}, {"tint","Color"}, {"selectStart", "int"}, 
			{"selectLength", "int"}, {"selectText", "Color"}, {"selectBack", "Color"}},
		},
	},

	aliases = {
		Camera = "Camera3D",
		Texture = "Texture2D",
		Quaternion = "Vector4",
	},
}
