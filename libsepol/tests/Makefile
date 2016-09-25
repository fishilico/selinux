M4 ?= m4
MKDIR ?= mkdir
EXE ?= libsepol-tests

#CFLAGS += -g3 -gdwarf-2 -O0 -Wall -W -Wundef -Wmissing-noreturn -Wmissing-format-attribute -Wno-unused-parameter -Werror
CFLAGS += -Wno-unused-parameter

# Statically link libsepol on the assumption that we are going to
# be testing internal functions.
LIBSEPOL := ../src/libsepol.a

# In order to load source policies we need to link in the checkpolicy/checkmodule parser and util code.
# This is less than ideal, but it makes the tests easier to maintain by allowing source policies
# to be loaded directly.
CHECKPOLICY := ../../checkpolicy/
override CPPFLAGS += -I../include/ -I$(CHECKPOLICY)

# test program object files
objs := $(patsubst %.c,%.o,$(sort $(wildcard *.c)))
parserobjs := $(CHECKPOLICY)queue.o $(CHECKPOLICY)y.tab.o \
	$(CHECKPOLICY)parse_util.o $(CHECKPOLICY)lex.yy.o \
	$(CHECKPOLICY)policy_define.o $(CHECKPOLICY)module_compiler.o

# test policy pieces
m4support := $(wildcard policies/support/*.spt)
testsuites := $(wildcard policies/test-*)
policysrc := $(foreach path,$(testsuites),$(wildcard $(path)/*.conf))
stdpol := $(addsuffix .std,$(policysrc))
mlspol := $(addsuffix .mls,$(policysrc))
policies := $(stdpol) $(mlspol)

# Compiler flags, using cc-disable-warning from Linux's scripts/Kbuild.include
try-run = $(shell set -e; if ($(1)) >/dev/null 2>&1; then echo "$(2)"; else echo "$(3)"; fi)
cc-disable-warning = $(call try-run,$(CC) -Werror -W$(strip $(1)) -E - < /dev/null,-Wno-$(strip $(1)))
override CFLAGS += $(call cc-disable-warning, extra-semi-stmt)  # Because of CU_ASSERT_FATAL

all: $(EXE) $(policies)
policies: $(policies)

$(EXE): $(objs) $(parserobjs) $(LIBSEPOL)
	$(CC) $(LDFLAGS) $(objs) $(parserobjs) -lcunit $(LIBSEPOL) -o $@

%.conf.std: $(m4support) %.conf
	$(M4) $(M4PARAMS) $^ > $@

%.conf.mls: $(m4support) %.conf
	$(M4) $(M4PARAMS) -D enable_mls $^ > $@

clean: 
	rm -f $(objs) $(EXE)
	rm -f $(policies)
	rm -f policies/test-downgrade/policy.hi policies/test-downgrade/policy.lo
	

test: $(EXE) $(policies)
	$(MKDIR) -p policies/test-downgrade
	../../checkpolicy/checkpolicy -M policies/test-cond/refpolicy-base.conf -o policies/test-downgrade/policy.hi	
	./$(EXE)

.PHONY: all policies clean test
