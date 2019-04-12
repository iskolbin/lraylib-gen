LUA ?= 5.1

LUA_HEADERS = -I./include/lua$(LUA)

RAYLIB_PATH = ./raylib
RAYLIB_STATIC = raylib/src/libraylib.a

CFLAGS=-O2

init:
	git submodule update --init --recursive

gen:
	lua gen.lua $(RAYLIB_PATH)/src/raylib.h > raylua.c

libraylib.a:
	cd $(RAYLIB_PATH)/src && $(MAKE) PLATFORM=PLATFORM_DESKTOP CFLAGS+=-fPIC

build-osx: gen libraylib.a
	cc -Wall -Wextra $(CFLAGS) raylua.c $(LUA_HEADERS) -I$(RAYLIB_PATH)/src $(RAYLIB_STATIC) -llua -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -fPIC -shared -o raylua.so

build-linux: gen libraylib.a
	cc -Wall -Wextra $(CFLAGS) raylua.c $(LUA_HEADERS) -I$(RAYLIB_PATH)/src $(RAYLIB_STATIC) -lX11 -lpthread -ldl -fPIC -shared -o raylua.so
