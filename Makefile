#!/usr/bin/make -f 


# Path to opensmalltalk-vm checkout
OPENSMALLTALK?=$(SRC)/opensmalltalk-vm
# Path to SqueakSSL checkout
SQUEAKSSL?=$(SRC)/SqueakSSL

# One of: nsspur64 nsspur nsspurstack64 nsspurstack spur64
# spurlowcode64 spurlowcode spurlowcodestack64 spurlowcodestack
# spursista64 spursista spur spurstack64 spurstack stack
# or empty for interpreter
SRC_FLAVOR?=spur

# One of: newspeak.cog.spur newspeak.sista.spur newspeak.stack.spur
# nsnac.cog.spur pharo.cog.spur pharo.cog.spur.lowcode
# pharo.stack.spur.lowcode squeak.cog.spur
# squeak.cog.spur.immutability squeak.cog.v3 squeak.sista.spur
# squeak.stack.spur squeak.stack.v3
BUILD_FLAVOR?=squeak.cog.spur

# One of: 32x86 64x64 32ARMv6 32ARMv7
BUILD_ARCH?=32x86

# One of: build build.assert build.assert.itimerheartbeat build.debug
# build.debug.itimerheartbeat build.itimerheartbeat
BUILD_KIND?=build

# Where to find OpenSSL or LibreSSL
#
#SSL_DIR=/opt/libressl

#-------------------------------------------------------------------#

SRC:=$(PWD)/src
OSVM_PLATFORMS?=$(OPENSMALLTALK)/platforms
OSVM_PLATFORMS_UNIX?=$(OSVM_PLATFORMS)/unix
OSVM_PLATFORMS_UNIX_VM?=$(OSVM_PLATFORMS_UNIX)/vm
OSVM_PLATFORMS_UNIX_CONFIG?=$(OSVM_PLATFORMS_UNIX)/config
OSVM_PLATFORMS_CROSS_VM?=$(OSVM_PLATFORMS)/Cross/vm
OSVM_PLUGIN_SRC?=$(OPENSMALLTALK)/src/plugins
OSVM_VM_SRC?=$(OPENSMALLTALK)/$(SRC_FLAVOR)src/vm
OSVM_BUILD?=$(OPENSMALLTALK)/build.linux$(BUILD_ARCH)/$(BUILD_FLAVOR)
#

#----------#
CONFIG_CF=-msse2 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64
CONFIG_CC=
ifneq (,$(findstring itimerheartbeat,$(BUILD_KIND)))
  CONFIG_CF+=-DITIMER_HEARTBEAT=1
endif

ifneq (,$(findstring multithreaded,$(BUILD_KIND)))
  CONFIG_CF+=-DCOGMTVM=1
else
ifneq (,$(findstring squeak.cog,$(BUILD_KIND)))
  CONFIG_CF+=-DCOGMTVM=0
endif
ifneq (,$(findstring pharo.cog,$(BUILD_KIND)))
  CONFIG_CF+=-DCOGMTVM=0
endif
ifneq (,$(findstring squeak.sista,$(BUILD_KIND)))
  CONFIG_CF+=-DCOGMTVM=0
endif
endif


ifneq (,$(findstring immutability,$(BUILD_FLAVOR)))
  CONFIG_CF+=-DIMMUTABILITY=1
endif
ifneq (,$(findstring nsnac,$(BUILD_FLAVOR)))
  CONFIG_CF+=-DEnforceAccessControl=0
endif

ifneq (,$(findstring x86,$(BUILD_ARCH)))
  CONFIG_CC+=-m32
endif
ifneq (,$(findstring x64,$(BUILD_ARCH)))
  CONFIG_CC+=-m64
endif
ifneq (,$(findstring ARMv6,$(BUILD_ARCH)))
  CONFIG_CC+=-march=armv6 -mfpu=vfp -mfloat-abi=hard
endif

#----------------------------------------------------------------#
TARGETS=SqueakSSL SqueakSSL.so so.SqueakSSL
OBJS=SqueakSSL.o sqUnixOpenSSL.o

TARGET_ARCH=-m32

CFLAGS+= $(CONFIG_CF) \
 -g \
 -O2 \
 -fPIC \
 -DPIC \
 -DNDEBUG \
 -DDEBUGVM=0 \
 -DLSB_FIRST=1 \
 -DHAVE_CONFIG_H \
#

LDFLAGS+=\
 -Wl,-z,now \
 -Wl,-soname -Wl,SqueakSSL  \
#
LDLIBS+=\
 -Wl,--no-as-needed \
   -lrt \
 -Wl,--whole-archive \
 -Wl,-Bstatic \
   -lcrypto \
   -lssl \
 -Wl,-Bdynamic \
 -Wl,--no-whole-archive \
#

ifdef SSL_DIR
  SSL_LIB=$(SSL_DIR)/lib
  SSL_INC=$(SSL_DIR)/include

  CFLAGS+=-I$(SSL_INC)

  LDFLAGS+=-L$(SSL_LIB)
endif 



all: $(TARGETS)

SqueakSSL: LDFLAGS+=-shared
SqueakSSL: $(OBJS)

SqueakSSL.so: SqueakSSL
	cp $^ $@
so.SqueakSSL: SqueakSSL
	cp $^ $@

SqueakSSL.c: sqConfig.h sqVirtualMachine.h sqPlatformSpecific.h SqueakSSL.h sqMemoryAccess.h $(OPENSMALLTALK)
	[ -f $@ ] || ln -s $(OSVM_PLUGIN_SRC)/SqueakSSL/$@

sqUnixOpenSSL.c: sq.h SqueakSSL.h $(SQUEAKSSL)
	[ -f $@ ] || ln -s $(SQUEAKSSL)/src/unix/$@

sq.h: sqConfig.h sqMemoryAccess.h sqVirtualMachine.h sqPlatformSpecific.h

sqConfig.h: config.h

sqVirtualMachine.h: interp.h sqMemoryAccess.h

sqPlatformSpecific.h: sqMemoryAccess.h

sqMemoryAccess.h: interp.h config.h

sq.h sqAtomicOps.h  sqMemoryAccess.h sqVirtualMachine.h: $(OPENSMALLTALK)
	[ -f $@ ] || ln -s $(OSVM_PLATFORMS_CROSS_VM)/$@

sqConfig.h sqPlatformSpecific.h: $(OPENSMALLTALK)
	[ -f $@ ] || ln -s $(OSVM_PLATFORMS_UNIX_VM)/$@


SqueakSSL.h: $(SQUEAKSSL)
	[ -f $@ ] || ln -s $(SQUEAKSSL)/src/Cross/$@

interp.h: $(OPENSMALLTALK)
	[ -f $@ ] || ln -s $(OSVM_VM_SRC)/$@


config.h: glibc.h plugins.int plugins.ext
	mkdir -p config || true ;  \
	cd config ; \
	cp ../plugins.int ../plugins.ext . ; \
	$(OSVM_PLATFORMS_UNIX_CONFIG)/configure \
	   --without-npsqueak \
	--with-vmversion=5.0 \
	--with-src=$(SRC_FLAVOR)src \
	CC="gcc $(CONFIG_CC)" \
	CXX="g++ $(CONFIG_CC)" \
	CFLAGS="$(CONFIG_CF)" \
	LIBS="-lpthread -luuid" \
	LDFLAGS=-Wl,-z,now ;\
	cp config.h .. ; \
	cd - ; \
#

glibc.h: $(OPENSMALLTALK)
	[ -f $@ ] || ln -s $(OSVM_PLATFORMS_UNIX_VM)/$@

plugins.int plugins.ext: $(OPENSMALLTALK)
	[ -f $@ ] || ln -s $(OSVM_BUILD)/$@

$(OPENSMALLTALK):
	git clone --depth 1 'https://github.com/OpenSmalltalk/opensmalltalk-vm.git' $@

$(SQUEAKSSL):
	git clone --depth 1 'https://github.com/squeak-smalltalk/squeakssl.git' $@

.PHONY: clean
clean:
	rm -f $(TARGETS) $(OBJS)

# EOF
