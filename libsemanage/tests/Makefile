# Add your test source files here:
SOURCES = $(sort $(wildcard *.c))
CILS = $(sort $(wildcard *.cil))

###########################################################################

EXECUTABLE = libsemanage-tests
CFLAGS += -g -O0 -Wall -W -Wundef -Wmissing-noreturn -Wmissing-format-attribute -Wno-unused-parameter
override CFLAGS += -I../src -I../include
override LDLIBS += -lcunit -lbz2 -laudit -lselinux -lsepol

# Compiler flags, using cc-disable-warning from Linux's scripts/Kbuild.include
try-run = $(shell set -e; if ($(1)) >/dev/null 2>&1; then echo "$(2)"; else echo "$(3)"; fi)
cc-disable-warning = $(call try-run,$(CC) -Werror -W$(strip $(1)) -E - < /dev/null,-Wno-$(strip $(1)))
override CFLAGS += $(call cc-disable-warning, extra-semi-stmt)  # Because of CU_ASSERT_FATAL

OBJECTS = $(SOURCES:.c=.o)
POLICIES = $(CILS:.cil=.policy)

all: $(EXECUTABLE) $(POLICIES)

$(EXECUTABLE): $(OBJECTS) ../src/libsemanage.a
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

%.policy: %.cil
	../../secilc/secilc $*.cil -o $*.policy -f /dev/null

clean distclean: 
	rm -rf $(OBJECTS) $(POLICIES) $(EXECUTABLE)

test: all 
	./$(EXECUTABLE)

