LUA ?= 5.1

LUA_HEADERS = -I./include/lua$(LUA)

RAYLIB_PATH = ./raylib
RAYLIB_STATIC = raylib/src/libraylib.a

init:
	git submodule update --init --recursive

gen:
	lua raylib-gen.lua $(RAYLIB)/src/raylib.h > raylib.c

libraylib.a:
	cd raylib/src && $(MAKE) PLATFORM=PLATFORM_DESKTOP CFLAGS+=-fPIC

build-osx: gen libraylib.a
	cc -Wall -Wextra -O2 raylib.c $(LUA_HEADERS) -I./include $(RAYLIB_STATIC) -llua -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -fPIC -shared -o raylib.so

build-linux: gen libraylib.a
	cc -Wall -Wextra -O2 raylib.c $(LUA_HEADERS) -I./include $(RAYLIB_STATIC) -lX11 -lpthread -ldl -fPIC -shared -o raylib.so
