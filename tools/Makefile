#
# Directories
#
_MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
TOOLSDIR := $(patsubst %/,%,$(dir $(_MKFILE_PATH)))
BUILDDIR ?= $(TOOLSDIR)/../build
PATCHDIR ?= $(TOOLSDIR)/patches

#
# Tools
#
GIT ?= git
CP ?= cp

#
# Targets
#

.PHONY: all
all: wrk

.PHONY: wrk

WRK_VERSION ?= a211dd5a7050b1f9e8a9870b95513060e72ac4a0

wrk: $(BUILDDIR)/wrk
	$(MAKE) -C $(BUILDDIR)/$@
	$(CP) $(BUILDDIR)/$@/wrk $(CURDIR)

$(BUILDDIR)/wrk:
	$(GIT) clone https://github.com/wg/wrk.git $(BUILDDIR)/$@
	(cd $(BUILDDIR)/$@; $(GIT) checkout $(WRK_VERSION))

