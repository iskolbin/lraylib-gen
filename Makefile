LUA ?= 5.1

LUA_HEADERS = -I./include/lua$(LUA)

RAYLIB_PATH = ./raylib
RAYLIB_STATIC = raylib/src/libraylib.a

CFLAGS=-O2

init:
	git submodule update --init --recursive

libraylib:
	cd $(RAYLIB_PATH)/src && $(MAKE) PLATFORM=PLATFORM_DESKTOP CFLAGS+=-fPIC

parse:
	lua -e 'print("return", require("str.str")(require("parse")("raylib/src/raylib.h","RLAPI",require("aliases"))))' > raylib_defs.lua
	lua -e 'print("return", require("str.str")(require("parse")("raylib/src/raymath.h","RMDEF",require("aliases"))))' > raymath_defs.lua
	lua -e 'print("return", require("str.str")(require("parse")("raylib/src/easings.h","EASEDEF",require("aliases"))))' > easings_defs.lua
	#lua -e 'print("return", require("str.str")(require("parse")("raylib/src/physac.h","PHYSACDEF",require("aliases"))))' > physac_defs.lua

bind:
	lua -e 'require("bind")({libname = "raylib", prefix = "l", includes = {"raylib/src/raylib.h", "raylib/src/rlgl.h", "isl_sleep/isl_sleep.h"}, defines = {"ISL_SLEEP_IMPLEMENTATION"}}, require("raylib_defs"), require("raylib_custom"))' > raylib_bind.c
	lua -e 'require("bind")({libname = "easings", prefix = "l", includes = {"raylib/src/easings.h"}, defines = {"PI M_PI"}}, require("easings_defs"))' > easings_bind.c
	lua -e 'require("bind")({libname = "raymath", prefix = "l", includes = {"raylib/src/raymath.h"}, defines = {"RAYMATH_HEADER_ONLY"}}, require("raymath_defs"), require("raymath_custom"))' > raymath_bind.c
	#lua -e 'require("bind")({libname = "physac", prefix = "l_", includes = {"raylib/src/raylib.h","raylib/src/physac.h",}, defines = {"PHYSAC_IMPLEMENTATION"}}, require("physac_defs"), require("physac_custom"))' > physac_bind.c

so-linux:
	cc -Wall -Wextra $(CFLAGS) raylib_bind.c $(LUA_HEADERS) -I$(RAYLIB_PATH)/src $(RAYLIB_STATIC) -llua$(LUA) -lX11 -lpthread -ldl -fPIC -shared -o raylib.so
	cc -Wall -Wextra $(CFLAGS) easings_bind.c $(LUA_HEADERS) -llua$(LUA) -fPIC -shared -o easings.so
	cc -Wall -Wextra $(CFLAGS) raymath_bind.c $(LUA_HEADERS) -llua$(LUA) -fPIC -shared -o raymath.so
	#cc -Wall -Wextra $(CFLAGS) physac_bind.c $(LUA_HEADERS) -llua$(LUA) -lpthread -fPIC -shared -o physac.so

so-osx:
	cc -Wall -Wextra $(CFLAGS) raylib_bind.c $(LUA_HEADERS) -I$(RAYLIB_PATH)/src $(RAYLIB_STATIC) -llua$(LUA) -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -fPIC -shared -o raylib.so
	cc -Wall -Wextra $(CFLAGS) easings_bind.c $(LUA_HEADERS) -llua$(LUA) -fPIC -shared -o easings.so
	cc -Wall -Wextra $(CFLAGS) raymath_bind.c $(LUA_HEADERS) -llua$(LUA) -fPIC -shared -o raymath.so
	#cc -Wall -Wextra $(CFLAGS) physac_bind.c $(LUA_HEADERS) -llua$(LUA) -fPIC -shared -o physac.so
