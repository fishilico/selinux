#
# Makefile for the PO files (translation) catalog
#

PREFIX ?= /usr
TOP	 = ../..

# What is this package?
NLSPACKAGE	= policycoreutils
POTFILE		= $(NLSPACKAGE).pot
INSTALL		= /usr/bin/install -c -p
INSTALL_DATA	= $(INSTALL) -m 644
INSTALL_DIR	= /usr/bin/install -d

# destination directory
INSTALL_NLS_DIR = $(PREFIX)/share/locale

# PO catalog handling
MSGMERGE	= msgmerge
MSGMERGE_FLAGS	= -q
XGETTEXT	= xgettext --default-domain=$(NLSPACKAGE)
MSGFMT		= msgfmt

# All possible linguas
PO_LINGUAS := $(sort $(patsubst %.po,%,$(wildcard *.po)))

# Only the files matching what the user has set in LINGUAS
USER_LINGUAS := $(filter $(patsubst %,%%,$(LINGUAS)),$(PO_LINGUAS))

# if no valid LINGUAS, build all languages
USE_LINGUAS := $(if $(USER_LINGUAS),$(USER_LINGUAS),$(PO_LINGUAS))

POFILES		= $(patsubst %,%.po,$(USE_LINGUAS))
MOFILES		= $(patsubst %.po,%.mo,$(POFILES))
POTFILES = \
	../run_init/open_init_pty.c \
	../run_init/run_init.c \
	../../semodule-utils/semodule_link/semodule_link.c \
	../../python/audit2allow/audit2allow \
	../../python/semanage/seobject.py \
	../setsebool/setsebool.c \
	../newrole/newrole.c \
	../load_policy/load_policy.c \
	../sestatus/sestatus.c \
	../semodule/semodule.c \
	../setfiles/setfiles.c \
	../../semodule-utils/semodule_package/semodule_package.c \
	../../semodule-utils/semodule_expand/semodule_expand.c \
	../../python/chcat/chcat \
	../scripts/fixfiles \
	../../restorecond/stringslist.c \
	../../restorecond/restorecond.h \
	../../restorecond/utmpwatcher.h \
	../../restorecond/stringslist.h \
	../../restorecond/restorecond.c \
	../../restorecond/utmpwatcher.c \
	../../gui/booleansPage.py \
	../../gui/fcontextPage.py \
	../../gui/loginsPage.py \
	../../gui/modulesPage.py \
	../../gui/portsPage.py \
	../../gui/semanagePage.py \
	../../gui/statusPage.py \
	../../gui/system-config-selinux.py \
	../../gui/system-config-selinux.ui \
	../../gui/usersPage.py \
	../secon/secon.c \
	booleans.py \
	../../python/sepolicy/sepolicy.py \
	../../python/sepolicy/sepolicy/communicate.py \
	../../python/sepolicy/sepolicy/__init__.py \
	../../python/sepolicy/sepolicy/network.py \
	../../python/sepolicy/sepolicy/generate.py \
	../../python/sepolicy/sepolicy/sepolicy.glade \
	../../python/sepolicy/sepolicy/gui.py \
	../../python/sepolicy/sepolicy/manpage.py \
	../../python/sepolicy/sepolicy/transition.py \
	../../python/sepolicy/sepolicy/templates/executable.py \
	../../python/sepolicy/sepolicy/templates/__init__.py \
	../../python/sepolicy/sepolicy/templates/network.py \
	../../python/sepolicy/sepolicy/templates/rw.py \
	../../python/sepolicy/sepolicy/templates/script.py \
	../../python/sepolicy/sepolicy/templates/semodule.py \
	../../python/sepolicy/sepolicy/templates/tmp.py \
	../../python/sepolicy/sepolicy/templates/user.py \
	../../python/sepolicy/sepolicy/templates/var_lib.py \
	../../python/sepolicy/sepolicy/templates/var_log.py \
	../../python/sepolicy/sepolicy/templates/var_run.py \
	../../python/sepolicy/sepolicy/templates/var_spool.py

#default:: clean

all::  $(MOFILES)

booleans.py:
	sepolicy booleans -a > booleans.py

$(POTFILE): $(POTFILES) booleans.py
	$(XGETTEXT) --keyword=_ --keyword=N_ $(POTFILES)
	@if cmp -s $(NLSPACKAGE).po $(POTFILE); then \
	    rm -f $(NLSPACKAGE).po; \
	else \
	    mv -f $(NLSPACKAGE).po $(POTFILE); \
	fi; \

update-po: Makefile $(POTFILE) refresh-po
	@rm -f booleans.py

refresh-po: Makefile
	for cat in $(POFILES); do \
		lang=`basename $$cat .po`; \
		if $(MSGMERGE) $(MSGMERGE_FLAGS) $$lang.po $(POTFILE) > $$lang.pot ; then \
			mv -f $$lang.pot $$lang.po ; \
			echo "$(MSGMERGE) of $$lang succeeded" ; \
		else \
			echo "$(MSGMERGE) of $$lang failed" ; \
			rm -f $$lang.pot ; \
		fi \
	done

clean:
	@rm -fv *mo *~ .depend
	@rm -rf tmp

install: $(MOFILES)
	@for n in $(MOFILES); do \
	    l=`basename $$n .mo`; \
	    $(INSTALL_DIR) $(DESTDIR)$(INSTALL_NLS_DIR)/$$l/LC_MESSAGES; \
	    $(INSTALL_DATA) --verbose $$n $(DESTDIR)$(INSTALL_NLS_DIR)/$$l/LC_MESSAGES/$(NLSPACKAGE).mo; \
	done

%.mo: %.po
	$(MSGFMT) -o $@ $<
report:
	@for cat in $(wildcard *.po); do \
                echo -n "$$cat: "; \
                msgfmt -v --statistics -o /dev/null $$cat; \
        done

.PHONY: missing depend

relabel:
