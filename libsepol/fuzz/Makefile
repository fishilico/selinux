FUZZ_EXE := $(patsubst %.c,%,$(sort $(wildcard fuzz-*.c)))

# TODO: integrate as documented on https://google.github.io/oss-fuzz/getting-started/new-project-guide/ with LIB_FUZZING_ENGINE (with -fsanitize=fuzzer or the no-link option?) Maybe the sanitizers get passed via CFLAGS, in fact...
LIBFUZZER_FLAGS ?= -g -fsanitize=address,undefined

override CFLAGS += -I../include -I../cil/include
LIBSEPOL := ../src/libsepol.a

ifneq ($(ENABLE_LIBFUZZER),y)
$(error Missing ENABLE_LIBFUZZER. Please use "make CC=clang ENABLE_LIBFUZZER=y" to build the fuzzer)
endif

all: $(FUZZ_EXE)

clean:
	$(RM) $(FUZZ_EXE)

%: %.c $(LIBSEPOL)
	$(CC) $(CFLAGS) $(LDFLAGS) -fsanitize=fuzzer $(LIBFUZZER_FLAGS) -o $@ $^

.PHONY: all clean
