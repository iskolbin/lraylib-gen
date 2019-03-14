gen:
	lua raylib-gen.lua include/raylib.h > raylib.c

build-osx:
	cc raylib.c -I./include lib/liblua53.a lib/libraylib.a -llua -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -fPIC -shared -o raylib.so

