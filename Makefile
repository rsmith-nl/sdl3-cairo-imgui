# Package name and version: BASENAME-VMAJOR.VMINOR.VPATCH.tar.gz
BASENAME = cairo-imgui-demo  ## Name for the project

# Define the C compiler to be used, if not clang.
#CC = cc

# The next lines are for debug builds.
#CFLAGS = -pipe -std=c11 -g3 -Wall -Wextra -Wstrict-prototypes -Wpedantic \
                -Wshadow -Wmissing-field-initializers -Wpointer-arith \
                -fsanitize=address,undefined

# The next lines are for release builds.
CFLAGS = -Os -pipe -std=c11 -ffast-math -march=native

# For a static executable, add the following LFLAGS.
#LFLAGS += --static

# for pkg-config libraries
PKGCFLAGS := $(shell pkg-config --cflags sdl3 cairo)
CFLAGS += $(PKGCFLAGS)
PKGLIBS := $(shell pkg-config --libs sdl3 cairo)
LFLAGS += $(PKGLIBS)

# Other libraries to link against
LIBS += -lm

##### Maintainer stuff goes here:
DISTFILES = Makefile  ## Files that need to be included in the distribution.
# Source files.
SRCS = cairo-imgui-demo.c cairo-imgui.c

##### No editing necessary beyond this point
ALL = $(BASENAME)

all: $(ALL) ## Compile the program. (default)

$(BASENAME): $(SRCS)
	$(CC) $(CFLAGS) -o $(BASENAME) $(SRCS) $(LFLAGS) $(LIBS)

cairo-imgui.c: cairo-imgui.h

.PHONY: clean
clean:  ## Remove all generated files.
	rm -f $(ALL) *~ core gmon.out backup-*

.PHONY: style
style:  ## Reformat source code using astyle.
	astyle -n *.c

.PHONY: tidy
tidy:  ## Run static code checker clang-tidy.
	clang-tidy19 --use-color --quiet *.c --

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

dist: clean  # Build a tar distribution file
	rm -rf $(PKGDIR)
	mkdir -p $(PKGDIR)
	cp $(DISTFILES) $(XTRA_DIST) *.c *.h $(PKGDIR)
	tar -czf $(TARFILE) $(PKGDIR)
	rm -rf $(PKGDIR)
