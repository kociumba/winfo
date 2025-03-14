# winfo

winfo is a simple Windows utility written in Odin to display window information, such as class names or extended style information.

winfo is in deep alpha right now, and is prone to bugs.

Prerequisites to build winfo:

- Windows (winfo only supports Windows)
- Installed `zig v0.13` or later (can be any C compiler, but `zig cc` is portable and configured in the Lua build script)
- Installed `odin dev-2025-2` or later
- Installed any `lua` interpreter to use the build script

Steps to build:

- Clone the repo with the `odin-http` submodule
- cd into the main repo directory
  - If using the lua build script and having the prerequisites, simply run `lua build.lua` or `lua build.lua -windows` to build in the windows subsystem
  - If not using the lua build script, compile the c code in `./c` into a static library named `winfo_utils.lib` in the main repo dir, (optionally) compile the resource file with `rc`, then use `odin build . -linker:lld` to compile the main binary (to include the resource file you can use: `-extra-linker-flags:"winfo.res"`). You can see the commands and their order in `build.lua`.