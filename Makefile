LUA ?= 5.1

LUA_HEADERS = -I./include/lua$(LUA)

RAYLIB_PATH = ./raylib
RAYLIB_STATIC = raylib/src/libraylib.a

CFLAGS=-O2

init:
	git submodule update --init --recursive

gen:
	lua gen.lua $(RAYLIB_PATH)/src/raylib.h $(RAYLIB_PATH)/src/raymath.h $(RAYLIB_PATH)/src/easings.h > raylib.c

libraylib.a:
	cd $(RAYLIB_PATH)/src && $(MAKE) PLATFORM=PLATFORM_DESKTOP CFLAGS+=-fPIC

build-osx: gen libraylib.a
	cc -Wall -Wextra $(CFLAGS) raylib.c $(LUA_HEADERS) -I$(RAYLIB_PATH)/src $(RAYLIB_STATIC) -llua -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -fPIC -shared -o raylib.so

build-linux: gen libraylib.a
	cc -Wall -Wextra $(CFLAGS) raylib.c $(LUA_HEADERS) -I$(RAYLIB_PATH)/src $(RAYLIB_STATIC) -lX11 -lpthread -ldl -fPIC -shared -o raylib.so

parse:
	lua -e 'require("parse")("raylib/src/raylib.h","RLAPI",require("aliases"))' > raylib_defs.lua
	lua -e 'require("parse")("raylib/src/raymath.h","RMDEF",require("aliases"))' > raymath_defs.lua
	lua -e 'require("parse")("raylib/src/physac.h","PHYSACDEF",require("aliases"))' > physac_defs.lua
	lua -e 'require("parse")("raylib/src/easings.h","EASEDEF",require("aliases"))' > easings_defs.lua

bind:
	lua -e 'require("bind")({libname = "easings", prefix = "l_", includes = {"raylib/src/easings.h"}, defines = {"PI M_PI"}}, require("easings_defs"))' > easings_bind.c

so-osx:
	cc -Wall -Wextra $(CFLAGS) easings_bind.c $(LUA_HEADERS) -llua$(LUA) -fPIC -shared -o easings.so
