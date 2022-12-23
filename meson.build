project('tokenizer',
    ['c', 'cpp'],
    version : '1.0',
    license : 'MIT',
    default_options : [
        'c_std=c11',
        'cpp_std=c++11',
        'buildtype=release',
        'wrap_mode=forcefallback'
    ]
)

#===============================================================================
# Compiler Settings
#===============================================================================
cc = meson.get_compiler('c')
compiler_args = ['-Wno-declaration-after-statement']

#===============================================================================
# Linker Settings
#===============================================================================
link_args = []
if cc.get_id() == 'gcc' and get_option('buildtype') == 'release'
    link_args += ['-static-libgcc']
endif

if host_machine.system() == 'darwin'
    link_args += ['-framework', 'CoreServices', '-framework', 'Foundation']
endif

#===============================================================================
# Dependencies
#===============================================================================
default_fallback_options = [
    'warning_level=0', 'werror=false', 'default_library=static'
]

# pcre2
pcre2_dep = dependency('libpcre2-8', fallback: ['pcre2', 'libpcre2_8'],
    default_options: default_fallback_options + ['grep=false', 'test=false']
)

# Optional Lua
use_lua = not get_option('use_lua').disabled()

# use luajit if enabled
lua_jit_found = false
if get_option('jit')
    lua_dep = dependency('luajit', required : false,
        default_options: default_fallback_options
    )
    use_lua = true
    compiler_args += '-DLUA_JIT'
    compiler_args += '-DUSE_LUA'
# use puc lua if enabled
elif use_lua
    lua_dep = dependency('lua-5.4',
        version: '>= 5.4',
        fallback: ['lua', 'lua_dep'],
        default_options: default_fallback_options + [
            'line_editing=false', 'interpreter=false'
        ]
    )
    compiler_args += '-DUSE_LUA'
endif

# Dependencies list
plugin_dependencies = [pcre2_dep]

if use_lua
    plugin_dependencies += lua_dep
endif

#===============================================================================
# Library Suffix
#===============================================================================
library_suffix = []

# On macOS the default suffix is .dylib but on lite-xl we need .so
if host_machine.system() == 'darwin'
    library_suffix = 'so'
endif

#===============================================================================
# Plugin Library
#===============================================================================
shared_library(
    'tokenizer',
    ['src/tokenizer.c'],
    name_prefix: '',
    name_suffix: library_suffix,
    dependencies: plugin_dependencies,
    c_args: compiler_args,
    link_args: link_args
)
