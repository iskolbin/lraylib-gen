return {
	funcs = {
		USleep = {
			name = 'USleep',
			args = {{'us', 'long'}},
			wrap = { name = 'isl_usleep', args = {'us'}}
		},

		GetDirectoryFiles = { src = [[
  int count;
  char **files = GetDirectoryFiles(luaL_checkstring(L,1), &count);
  for (int i = 0; i < count-1; i++) lua_pushstring(L, files[i]);
  ClearDirectoryFiles();
  return count;]]},

		GetDroppedFiles = { src = [[
  int count;
  char **files = GetDroppedFiles(&count);
  for (int i = 0; i < count; i++) lua_pushstring(L, files[i]);
  ClearDroppedFiles();
  return count;]]},

		--GetDirectoryFiles = { resultFinalizer = 'ClearDirectoryFiles()' },

		--GetDroppedFiles = { resultFinalizer = 'ClearDroppedFiles()' },

		GetFileNameWithoutExt = { resultFinalizer = 'free((void*)result)' },

		CheckCollisionRaySphereEx = { src = [[
  Ray ray = (*(Ray*)luaL_checkudata(L, 1, "Ray"));
  Vector3 spherePosition = (*(Vector3*)luaL_checkudata(L, 2, "Vector3"));
  float sphereRadius = luaL_checknumber(L, 3);
  Vector3 *collisionPoint = lua_newuserdata(L, sizeof *collisionPoint); luaL_setmetatable(L, "Vector3");
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

		DrawTriangleFan = { src = [[
  int len = lua_rawlen(L, 1);
  Color *color = luaL_checkudata(L, 2, "Color");
  if (len < 6) return 0;
  if (rlCheckBufferLimit((len/2 - 2)*4)) rlglDraw();
#if defined(SUPPORT_FONT_TEXTURE)
  Texture2D texShapes = GetFontDefault().texture;
  Rectangle rec = GetFontDefault().chars[95].rec;
  Rectangle recTexShapes = (Rectangle){ rec.x + 1, rec.y + 1, rec.width - 2, rec.height - 2 };
#else
  Texture2D texShapes = GetTextureDefault();
  Rectangle recTexShapes = (Rectangle){ 0.0f, 0.0f, 1.0f, 1.0f };
#endif
  rlEnableTexture(texShapes.id);
  rlBegin(RL_QUADS);
  {
    float x0, y0, x1, y1, x2, y2;
    rlColor4ub(color->r, color->g, color->b, color->a);
    lua_rawgeti(L, 1, 1); x0 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 1, 2); y0 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 1, 3); x1 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 1, 4); y1 = luaL_checknumber(L, -1);
    for (int i = 5; i <= len; i += 2)
    {
      lua_rawgeti(L, 1, i); x2 = luaL_checknumber(L, -1);
      lua_rawgeti(L, 1, i+1); y2 = luaL_checknumber(L, -1);
      rlTexCoord2f(recTexShapes.x/texShapes.width, recTexShapes.y/texShapes.height);
      rlVertex2f(x0, y0);

      rlTexCoord2f(recTexShapes.x/texShapes.width, (recTexShapes.y + recTexShapes.height)/texShapes.height);
      rlVertex2f(x1, y1);

      rlTexCoord2f((recTexShapes.x + recTexShapes.width)/texShapes.width, (recTexShapes.y + recTexShapes.height)/texShapes.height);
      rlVertex2f(x2, y2);

      rlTexCoord2f((recTexShapes.x + recTexShapes.width)/texShapes.width, recTexShapes.y/texShapes.height);
      rlVertex2f(x2, y2);
      x1 = x2; y1 = y2;
    }
    rlEnd();
    rlDisableTexture();
  }
  return 0;]]},
	
		DrawLineStrip = { src = [[
  int len = lua_rawlen(L, 1);
  Color *color = luaL_checkudata(L, 2, "Color");
  if (len < 4) return 0;
  if (rlCheckBufferLimit(len/2)) rlglDraw();
  rlBegin(RL_LINES);
  {
    float x0, y0, x1, y1;
    rlColor4ub(color->r, color->g, color->b, color->a);
    lua_rawgeti(L, 1, 1); x0 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 1, 2); y0 = luaL_checknumber(L, -1);
    for (int i = 3; i <= len; i += 2)
    {
      lua_rawgeti(L, 1, i); x1 = luaL_checknumber(L, -1);
      lua_rawgeti(L, 1, i+1); y1 = luaL_checknumber(L, -1);
      rlVertex2f(x0, y0);
      rlVertex2f(x1, y1);
      x0 = x1; y0 = y1;
    }
  }
  rlEnd();
	return 0;]]},
	
		LoadMaterials = { src = [[
  int count;
  Material *materials = LoadMaterials(luaL_checkstring(L,1), &count);
	for (int i = 0; i < count; i++) {
    Material *material = lua_newuserdata(L, sizeof *material);
    *material = materials[i];
    luaL_setmetatable(L, "Material");
  }
  return count;]]},

		TextJoin = { returnsArgs = {{'count', 'int'}}, pass = true },
		TextSplit = { pass = true },
		TextAppend = { updatesArgs = {{'position', 'int'}}, pass = true },
		TextReplace = { resultFinalizer = 'free((void*)result)' },
		TextInsert = { resultFinalizer = 'free((void*)result)' },
		DrawTextRecEx = { args = {
			{"font", "Font"}, {"text", "const char *"}, {"rec", "Rectangle"}, {"fontSize", "float"},
			{"spacing", "float"}, {"wordWrap", "bool"}, {"tint","Color"}, {"selectStart", "int"}, 
			{"selectLength", "int"}, {"selectText", "Color"}, {"selectBack", "Color"}},
		},

		SetShaderValueFloat = {
      name = 'SetShaderValueFloat',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "float"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_FLOAT"}},
		},

		SetShaderValueVec2 = {
      name = 'SetShaderValueVec2',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "Vector2"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_VEC2"}},
		},

		SetShaderValueVec3 = {
      name = 'SetShaderValueVec3',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "Vector3"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_VEC3"}},
		},

		SetShaderValueVec4 = {
      name = 'SetShaderValueVec4',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "Vector4"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_VEC4"}},
		},

		SetShaderValueInt = {
      name = 'SetShaderValueInt',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "int"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_INT"}},
		},

		SetShaderValueIVec2 = {
      name = 'SetShaderValueIVec2',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "IVector2"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_IVEC2"}},
		},

		SetShaderValueIVec3 = {
      name = 'SetShaderValueIVec3',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "IVector3"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_IVEC3"}},
		},

		SetShaderValueIVec4 = {
      name = 'SetShaderValueIVec4',
      args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "IVector4"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_IVEC4"}},
		},

		SetShaderValueSampler2D = {
      name = 'SetShaderValueSampler2D',
			args = {{"shader", "Shader"}, {"uniformLoc", "int"}, {"value", "int"}},
			wrap = { name = "SetShaderValue", args = {"shader", "uniformLoc", "&value", "UNIFORM_SAMPLER2D"}},
		},
	},

	structs = {
    IVector2 = {
			typedef = true,
      fields = {{"x", "int"}, {"y", "int"}}
    },
    IVector3 = {
			typedef = true,
      fields = {{"x", "int"}, {"y", "int"}, {"z", "int"}}
    },
    IVector4 = {
			typedef = true,
      fields = {{"x", "int"}, {"y", "int"}, {"z", "int"}, {"w", "int"}}
    },
	},
}
