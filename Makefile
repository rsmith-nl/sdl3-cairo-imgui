# vim:fileencoding=utf-8:ft=make
# Use as many jobs as the computer has cores.
.MAKEFLAGS: -j C

# Define the C compiler to be used, if not clang.
#CC = gcc14

# For debugging builds (clang only).
CFLAGS = -pipe -std=c11 -g3 -Wall -Wextra -Wstrict-prototypes -Wpedantic \
                -Wshadow -Wmissing-field-initializers -Wpointer-arith \
                -fsanitize=address,undefined

# For release builds, clang and gcc. (Comment out for debug build.)
CFLAGS = -Os -pipe -std=c11 -ffast-math -march=native
LFLAGS = -flto

# For a static executable, add the following LFLAGS.
#LFLAGS += --static

# for pkg-config libraries
PKGCFLAGS !=pkg-config --cflags sdl3 cairo
CFLAGS += $(PKGCFLAGS)
PKGLIBS != pkg-config --libs sdl3 cairo
LFLAGS += $(PKGLIBS)

# Other libraries to link against
LIBS += -lm

##### Maintainer stuff goes here:

##### No editing necessary beyond this point
ALL = ./build/cairo-imgui-demo ./build/demo-template ./build/circle-demo
ALL += ./build/cube-demo

all: $(ALL) ## Compile the program. (default)

# This makefile uses unit builds.
# NB: I'm not using ${.ALLSRC}; GNU make doesn't understand that. :(
./build/cairo-imgui-demo: ./src/cairo-imgui-demo.c ./src/cairo-imgui.c
	$(CC) $(CFLAGS) $(LFLAGS) -o ./build/cairo-imgui-demo ./src/cairo-imgui-demo.c ./src/cairo-imgui.c $(LIBS)

./build/demo-template: ./src/demo-template.c ./src/cairo-imgui.c
	$(CC) $(CFLAGS) $(LFLAGS) -o ./build/demo-template ./src/demo-template.c ./src/cairo-imgui.c $(LIBS)

./build/circle-demo: ./src/circle-demo.c ./src/cairo-imgui.c
	$(CC) $(CFLAGS) $(LFLAGS) -o ./build/circle-demo ./src/circle-demo.c ./src/cairo-imgui.c $(LIBS)

./build/cube-demo: ./src/cube-demo.c ./src/cairo-imgui.c
	$(CC) $(CFLAGS) $(LFLAGS) -o ./build/cube-demo ./src/cube-demo.c ./src/cairo-imgui.c $(LIBS)

cairo-imgui.c: cairo-imgui.h

.PHONY: clean
clean:  ## Remove all generated files.
	rm -f $(ALL) *~ core gmon.out backup-*

.PHONY: style
style:  ## Reformat source code using astyle.
	astyle -n --style=1tbs -s2 -p -o -O --indent-switches --delete-empty-lines --add-braces ./src/*.c ./src/*.h

.PHONY: tidy
tidy:  ## Run static code checker clang-tidy.
	clang-tidy19 --use-color --quiet ./src/*.c ./src/*.h --

tags: $(SRCS) *.h  ## Update tags file
	uctags --language-force=C --kinds-C=+p-f *.c /usr/local/include/SDL3/*.h

.PHONY: help
help:  ## List available commands
	@echo "make variables:"
	@echo
	@sed -n -e '/##/s/=.*\#\#/\t/p' Makefile
	@echo
	@echo "make targets:"
	@echo
	@sed -n -e '/##/s/:.*\#\#/\t/p' Makefile
