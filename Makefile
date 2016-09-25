PREFIX ?= /usr
OPT_SUBDIRS ?= dbus gui mcstrans python restorecond sandbox semodule-utils
SUBDIRS=libsepol libselinux libsemanage checkpolicy secilc policycoreutils $(OPT_SUBDIRS)
PYSUBDIRS=libselinux libsemanage
DISTCLEANSUBDIRS=libselinux libsemanage

# Choose compiler (default is cc)
#export CC = gcc
#export CC = clang

ifneq ($(CC),cc)
# for python modules, compiled with clang
export LDSHARED = $(CC) -pthread -shared -Wl,-O1 -Wl,-Bsymbolic-functions
endif

ifeq ($(DEBUG),1)
	export CFLAGS = -g3 -O0 -gdwarf-2 -fno-strict-aliasing -Wall -Wshadow -Werror
	export LDFLAGS = -g
else
	export CFLAGS ?= -O2 -Werror -Wall -Wextra \
		-Wmissing-format-attribute \
		-Wmissing-noreturn \
		-Wpointer-arith \
		-Wshadow \
		-Wstrict-prototypes \
		-Wundef \
		-Wunused \
		-Wwrite-strings \
		-fno-common
endif

# Compiler flags, using cc-disable-warning from Linux's scripts/Kbuild.include
try-run = $(shell set -e; if ($(1)) >/dev/null 2>&1; then echo "$(2)"; else echo "$(3)"; fi)
cc-disable-warning = $(call try-run,$(CC) -Werror -W$(strip $(1)) -E - < /dev/null,-Wno-$(strip $(1)))

CFLAGS += -Wformat=2
CFLAGS += -Wno-padded
CFLAGS += -Wno-cast-align
CFLAGS += -Wno-cast-qual
CFLAGS += -Wno-conversion
CFLAGS += -Wno-missing-prototypes
CFLAGS += -Wno-packed
CFLAGS += -Wno-switch-enum
CFLAGS += -Wno-variadic-macros
CFLAGS += -Wno-vla # There are VLAs in tests
CFLAGS += -ftrapv # Trap on integer overflow
export LDFLAGS += -Wl,-O1,-as-needed,-no-undefined,-z,relro,-z,now,--fatal-warnings

export SWIG_CFLAGS ?=
SWIG_CFLAGS += $(call cc-disable-warning, shadow) # SWIG 3.0.10 generates code with a shadowed variable
SWIG_CFLAGS += $(call cc-disable-warning, missing-field-initializers) # SWIG 4.0.1 with Python 3.8 misses initializer for field 'tp_vectorcall' of 'PyTypeObject'

export SWIG_RUBY_CFLAGS ?=
SWIG_RUBY_CFLAGS += -Wno-unused-parameter # Ruby SWIG wrappers have many unused parameters
SWIG_RUBY_CFLAGS += -Wno-strict-prototypes # Ruby 2.5 headers use empty args for functions with any arguments, which is incompatible with Wstrict-prototypes

ifneq ($(shell "$(CC)" -v 2>&1 | grep clang),)
	# clang-specific flags
	CFLAGS += -Weverything
	CFLAGS += $(call cc-disable-warning, assign-enum)
	CFLAGS += $(call cc-disable-warning, atomic-implicit-seq-cst) # Use __sync_synchronize(); instead of atomics
	CFLAGS += $(call cc-disable-warning, covered-switch-default)
	CFLAGS += $(call cc-disable-warning, disabled-macro-expansion)
	CFLAGS += $(call cc-disable-warning, documentation)
	CFLAGS += $(call cc-disable-warning, documentation-unknown-command)
	CFLAGS += $(call cc-disable-warning, format-non-iso) # Use sscanf("%ms") to allocate strings
	CFLAGS += $(call cc-disable-warning, gnu)
	CFLAGS += $(call cc-disable-warning, gnu-conditional-omitted-operand)
	CFLAGS += $(call cc-disable-warning, implicit-fallthrough) # clang does not understand /* FALLTHRU */ annotations
	CFLAGS += $(call cc-disable-warning, language-extension-token)
	CFLAGS += $(call cc-disable-warning, missing-variable-declarations)
	CFLAGS += $(call cc-disable-warning, pedantic)
	CFLAGS += $(call cc-disable-warning, reserved-id-macro)
	CFLAGS += $(call cc-disable-warning, shift-sign-overflow) # /usr/include/glib-2.0/gobject/gparam.h contains "1 << 31"
	CFLAGS += $(call cc-disable-warning, shorten-64-to-32)
	CFLAGS += $(call cc-disable-warning, unreachable-code)
	CFLAGS += $(call cc-disable-warning, unreachable-code-break)
	CFLAGS += $(call cc-disable-warning, unreachable-code-return)
	CFLAGS += $(call cc-disable-warning, unused-macros)

	#CFLAGS += -fsanitize=undefined-trap

	SWIG_CFLAGS += $(call cc-disable-warning, used-but-marked-unused)
	SWIG_CFLAGS += $(call cc-disable-warning, conditional-uninitialized) # There is a false positive in SWIG-generated code
	SWIG_CFLAGS += $(call cc-disable-warning, extra-semi-stmt)
	ifneq ($(subst pypy3, , $(PYTHON)), $(PYTHON))
		# /home/travis/virtualenv/pypy3/include/unicodeobject.h contains "s1++, s2++;"
		SWIG_CFLAGS += $(call cc-disable-warning, comma)
	endif

	SWIG_RUBY_CFLAGS += $(call cc-disable-warning, ignored-attributes) # ruby.h from Ruby 2.3 has a misplaced deprecated attribute
	SWIG_RUBY_CFLAGS += $(call cc-disable-warning, missing-noreturn) # SWIG 3.0.12 introduces Ruby_Format_OverloadedError, which can be declared with a noreturn attribute
	SWIG_RUBY_CFLAGS += $(call cc-disable-warning, unknown-attributes) # backward.h from Ruby 2.5 uses __error__ attribute, which is unknown to clang
else ifneq ($(shell "$(CC)" -v 2>&1 | grep gcc),)
	# gcc-specific flags
	CFLAGS += $(call cc-disable-warning, clobbered) # vfork+execve on stack arguments construct
	CFLAGS += $(call cc-disable-warning, maybe-uninitialized) # Too many false positives (with -O0)
	CFLAGS += $(call cc-disable-warning, uninitialized) # Too many false positives
	CFLAGS += $(call cc-disable-warning, unused-result) # Too many false positives

	# Flags introduced in gcc 8
	SWIG_CFLAGS += $(call cc-disable-warning, cast-function-type) # Python SWIG uses cast between incompatible function types
	SWIG_CFLAGS += $(call cc-disable-warning, stringop-truncation) # SWIG 3.0.12 uses strncpy(buff, "swig_ptr: ", 10) (output truncated before terminating nul copying 10 bytes from a string of the same length)
endif

# With Travis (Ubuntu 14.04), SWIG 2.0.11 generates Python and Ruby wrappers with compiler warnings
ifeq ($(TRAVIS),true)
	SWIG_CFLAGS += $(call cc-disable-warning, missing-field-initializers)
	SWIG_RUBY_CFLAGS += $(call cc-disable-warning, missing-noreturn)
	SWIG_RUBY_CFLAGS += $(call cc-disable-warning, strict-prototypes)
	SWIG_RUBY_CFLAGS += $(call cc-disable-warning, unused-but-set-variable)
	ifneq ($(subst pypy, , $(PYTHON)), $(PYTHON))
		# Do not use -Wl,-no-undefined with PyPy on Travis as libpypy-c.so is not provided
		, := ,
		LDFLAGS := $(subst $(,)-no-undefined,,$(LDFLAGS))
	endif
endif

ifneq ($(DESTDIR),)
	LIBDIR ?= $(DESTDIR)$(PREFIX)/lib
	LIBSEPOLA ?= $(LIBDIR)/libsepol.a

	CFLAGS += -I$(DESTDIR)$(PREFIX)/include
	LDFLAGS += -L$(DESTDIR)$(PREFIX)/lib -L$(LIBDIR)
	export CFLAGS
	export LDFLAGS
	export LIBSEPOLA
endif

all install relabel clean test indent:
	@for subdir in $(SUBDIRS); do \
		(cd $$subdir && $(MAKE) $@) || exit 1; \
	done

install-pywrap install-rubywrap swigify:
	@for subdir in $(PYSUBDIRS); do \
		(cd $$subdir && $(MAKE) $@) || exit 1; \
	done

distclean:
	@for subdir in $(DISTCLEANSUBDIRS); do \
		(cd $$subdir && $(MAKE) $@) || exit 1; \
	done
