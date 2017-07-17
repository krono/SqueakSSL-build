# Building SqueakSSL statically for Linux

---

## Usage

```bash
make
```

or
 
```bash
make OPENSMALLTALK=~/src/opensmalltalk-vm SQUEAKSSL=~/src/SqueakSSL SSL_DIR=/opt/libressl
```

## Requirements

 * Source-code of [SqueakSSL] and [OpensSmalltalk-VM] or `git`
 * [OpenSSL] ≥ 0.9.8 (but ≥ 1.0.2 would be better) **or** [LibreSSL] with “development package” or what your Distro calls it.
 * Make sure you have the platform-matching (static) libs.  
    **This typically means installing 32bit libraries** as we build 32bit SqueakSSL by default for historical reasons.


## Rationale

 * Debian- and CentOS/RedHat descendant Distros use incompatible naming/versioning schemes for OpenSSL in certain versions
 * LibreSSL is yet to be bundled for most of those Distros.
 * Static linking of `libssl` and `libcrypto` solves these problems somewhat
 * Automake uses `libtool` which makes partial static linking near impossible
 * Currently, OpenSmalltalk-VM uses automake on Linux
 * Hence, this `Makefile`.


## Configuration
 
```bash
$ head -n 31 Makefile
```

```make
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
```


[SqueakSSL]: https://github.com/squeak-smalltalk/squeakssl
[OpensSmalltalk-VM]: https://github.com/OpenSmalltalk/opensmalltalk-vm
[OpenSSL]: https://www.openssl.org/
[LibreSSL]: https://www.libressl.org/
