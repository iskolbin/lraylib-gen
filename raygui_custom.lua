return {
	funcs = {
		GuiSpinner = {src = [[
  Rectangle bounds = (*(Rectangle*)luaL_checkudata(L, 1, "Rectangle"));
  int value = luaL_checkinteger(L, 2);
  int minValue = luaL_checkinteger(L, 3);
  int maxValue = luaL_checkinteger(L, 4);
  bool editMode = lua_toboolean(L, 5);
  bool result = GuiSpinner(bounds, &value, minValue, maxValue, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, value);
  return 2;]]
		},

		GuiSpinnerU = {src = [[
  Rectangle bounds = {luaL_checkinteger(L, 1),luaL_checkinteger(L, 2),luaL_checkinteger(L, 3),luaL_checkinteger(L, 4)};
  int value = luaL_checkinteger(L, 2);
  int minValue = luaL_checkinteger(L, 3);
  int maxValue = luaL_checkinteger(L, 4);
  bool editMode = lua_toboolean(L, 5);
  bool result = GuiSpinner(bounds, &value, minValue, maxValue, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, value);
  return 2;]]
		},

		GuiValueBox = {src = [[
  Rectangle bounds = (*(Rectangle*)luaL_checkudata(L, 1, "Rectangle"));
  int value = luaL_checkinteger(L, 2);
  int minValue = luaL_checkinteger(L, 3);
  int maxValue = luaL_checkinteger(L, 4);
  bool editMode = lua_toboolean(L, 5);
  bool result = GuiValueBox(bounds, &value, minValue, maxValue, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, value);
  return 2;]]
		},

		GuiValueBoxU = {src = [[
  Rectangle bounds = {luaL_checkinteger(L, 1),luaL_checkinteger(L, 2),luaL_checkinteger(L, 3),luaL_checkinteger(L, 4)};
  int value = luaL_checkinteger(L, 2);
  int minValue = luaL_checkinteger(L, 3);
  int maxValue = luaL_checkinteger(L, 4);
  bool editMode = lua_toboolean(L, 5);
  bool result = GuiValueBox(bounds, &value, minValue, maxValue, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, value);
  return 2;]]
		},

		GuiDropdownBox = {src = [[
  Rectangle bounds = (*(Rectangle*)luaL_checkudata(L, 1, "Rectangle"));
  const char* text = luaL_checkstring(L, 2);
  int active = lua_checkinteger(L, 3);
  bool editMode = lua_toboolean(L, 4);
  bool result = GuiDropdownBox(bounds, text, active, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, active);
  return 2;]]
		},

		GuiDropdownBoxU = {src = [[
  Rectangle bounds = {luaL_checkinteger(L, 1),luaL_checkinteger(L, 2),luaL_checkinteger(L, 3),luaL_checkinteger(L, 4)};
  const char* text = luaL_checkstring(L, 2);
  int active = lua_checkinteger(L, 3);
  bool editMode = lua_toboolean(L, 4);
  bool result = GuiDropdownBox(bounds, text, active, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, active);
  return 2;]]
		},
	
		GuiListView = {src = [[
  Rectangle bounds = (*(Rectangle*)luaL_checkudata(L, 1, "Rectangle"));
  bool editMode = lua_toboolean(L, 2);
  const char* text = luaL_checkstring(L, 3);
  int active;
  int scrollIndex;
  bool result = GuiListView(bounds, text, &active, &scrollIndex, editMode);
  lua_pushboolean(L, result);
	lua_pushinteger(L, active);
	lua_pushinteger(L, scrollIndex);
  return 3;]]
		},

		GuiListViewU = {src = [[
  Rectangle bounds = {luaL_checkinteger(L, 1),luaL_checkinteger(L, 2),luaL_checkinteger(L, 3),luaL_checkinteger(L, 4)};
  bool editMode = lua_toboolean(L, 2);
  const char* text = luaL_checkstring(L, 3);
  int active;
  int scrollIndex;
  bool result = GuiListView(bounds, text, &active, &scrollIndex, editMode);
  lua_pushboolean(L, result);
	lua_pushinteger(L, active);
	lua_pushinteger(L, scrollIndex);
  return 3;]]
		},

		GuiListViewEx = {src = [[
  Rectangle bounds = (*(Rectangle*)luaL_checkudata(L, 1, "Rectangle"));
  bool editMode = lua_toboolean(L, 2);
  const char* text[64];
  int n = lua_gettop(L);
  int count = n-2;
  int enabled;
  int active;
  int focus;
  int scrollIndex;
  for (int i = 0; i < count; i++) {
    text[i] = luaL_checkstring(L, i+2);
  }
  bool result = GuiListViewEx(bounds, text, count, &enabled, &active, &focus, &scrollIndex, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, enabled);
  lua_pushinteger(L, active);
  lua_pushinteger(L, focus);
  lua_pushinteger(L, scrollIndex);
  return 5;]]
		},

		GuiListViewExU = {src = [[
  Rectangle bounds = {luaL_checkinteger(L, 1),luaL_checkinteger(L, 2),luaL_checkinteger(L, 3),luaL_checkinteger(L, 4)};
  bool editMode = lua_toboolean(L, 5);
	const char* text[64];
	int n = lua_gettop(L);
	int count = n-2;
  int enabled;
  int active;
  int focus;
  int scrollIndex;
	for (int i = 0; i < count; i++) {
		text[i] = luaL_checkstring(L, i+2);
	}
  bool result = GuiListViewEx(bounds, text, count, &enabled, &active, &focus, &scrollIndex, editMode);
  lua_pushboolean(L, result);
  lua_pushinteger(L, enabled);
  lua_pushinteger(L, active);
  lua_pushinteger(L, focus);
  lua_pushinteger(L, scrollIndex);
	return 5;]]
		},
		
		GuiLoadStyleProps = {src = [[
  int count = lua_gettop(L)-1;
  const int props[NUM_PROPS_DEFAULT + NUM_PROPS_EXTENDED];
  for (int i = 0; i < count; i++) {
    props[i] = luaL_checkinteger(L, i+1);
  }
  GuiLoadStyleProps(props, count);
  return 0;]]
		},

		GuiScrollPanel = {src = [[
  Rectangle bounds = (*(Rectangle*)luaL_checkudata(L, 1, "Rectangle"));
  Rectangle content = (*(Rectangle*)luaL_checkudata(L, 2, "Rectangle"));
  Vector2 scroll;
  Rectangle result = GuiScrollPanel(bounds, content, &scroll);
	lua_pushnumber(L, scroll.x);lua_pushnumber(L, scroll.y);
  return 3;]]
		},

		GuiScrollPanelU = {src = [[
  Rectangle bounds = {luaL_checkinteger(L, 1),luaL_checkinteger(L, 2),luaL_checkinteger(L, 3),luaL_checkinteger(L, 4)};
  Rectangle content = {luaL_checkinteger(L, 5),luaL_checkinteger(L, 6),luaL_checkinteger(L, 7),luaL_checkinteger(L, 8)};
  Vector2 scroll;
  Rectangle result = GuiScrollPanel(bounds, content, &scroll);
  lua_pushinteger(L, result.x);lua_pushinteger(L, result.y);lua_pushinteger(L, result.width);lua_pushinteger(L, result.height);
	lua_pushnumber(L, scroll.x);lua_pushnumber(L, scroll.y);
	return 6;]]
		},

	},

	structs = {
		GuiTextBoxState = {
			fields = {
				{"cursor", "int"},
				{"start", "int"},
				{"index", "int"},
				{"select", "int"}
			}
		},

		[""] = {pass = true},
		Vector2 = {pass = true},
		Vector3 = {pass = true},
		Texture2D = {pass = true},
		Color = {pass = true},
		Rectangle = {pass = true},
	}
}
