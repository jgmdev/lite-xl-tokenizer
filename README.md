# Lite XL C-Tokenizer Plugin

This repository provides a standalone copy of the work done by **Adam** on the
native implementation of the Lua tokenizer found on his simplified branch
https://github.com/adamharrison/lite-xl-simplified/tree/c-tokenizer for
testing purposes.

## Building

You will need to have meson and a working build environment for your operating
system. Then, to build just execute the following commands:

```sh
meson setup build
meson compile -C build
```

By default we configured meson to download Lua and pcre2 and statically link
to it. To disable this behavior and instead link against system libraries,
use `--wrap-mode default`

```sh
meson setup --wrap-mode default build
```

Also you can link to luajit instead by adding `-Djit=true`

```sh
meson setup -Djit=true build
```

## Installation

To install just copy the generated library file to your libraries directory:

```sh
cp build/tokenizer.so ~/.config/lite-xl/libraries/
```

Then install the Lua plugin to take advantage of the native tokenizer plugin:

```sh
cp plugins/ctokenizer.lua ~/.config/lite-xl/plugins/
```

## Usage:

You can enable and disable the native tokenizer from the settings or by
modifying the value of `config.plugins.ctokenizer.enabled` to `true` or `false`.

Also, you can enable `config.plugins.ctokenizer.log_time` to measure the time
it takes to tokenize a range of lines.
