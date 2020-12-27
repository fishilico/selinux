DISABLE_CIL ?= n
ENABLE_LIBFUZZER ?= n

export DISABLE_CIL
export ENABLE_LIBFUZZER

all: 
	$(MAKE) -C src
	$(MAKE) -C utils

ifeq ($(ENABLE_LIBFUZZER),y)
fuzzer:
	$(MAKE) -C src libsepol.a
	$(MAKE) -C fuzz
endif

install: 
	$(MAKE) -C include install
	$(MAKE) -C src install
	$(MAKE) -C utils install
	$(MAKE) -C man install

relabel:
	$(MAKE) -C src relabel

clean:
	$(MAKE) -C src clean
	$(MAKE) -C utils clean
	$(MAKE) -C tests clean
	$(MAKE) -C fuzz ENABLE_LIBFUZZER=y clean

indent:
	$(MAKE) -C src $@
	$(MAKE) -C include $@
	$(MAKE) -C utils $@

test:
	$(MAKE) -C tests test

