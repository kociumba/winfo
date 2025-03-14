-- build commands
local build_c = 'zig cc -c "c/utils.c" -target x86_64-windows-msvc -static -o "winfo_utils.lib"'
local compile_rc = 'rc "winfo.rc" > nul'
local buiuld_odin = 'odin build . -o:speed -linker:lld -min-link-libs -extra-linker-flags:"winfo.res"'

-- Function to execute a command and return success status
local function execute_command(command)
    local status = os.execute(command)
    return status
end

-- Function to print status with color
local function print_status(success, message)
    local color_code = success and "\027[38;5;112m" or "\027[38;5;196m"
    local status_text = success and "[OK]" or "[ERROR]"
    local reset_code = "\027[0m"

    io.write("\r" .. message .. " " .. color_code .. status_text .. reset_code .. "\n")
    io.flush()
end

-- Compile C utils
io.write("Compiling C utils...\r")
io.flush()
local c_utils_success = execute_command(build_c)
print_status(c_utils_success, "Compiling C utils...")

-- Compile resources (silencing rc.exe)
io.write("Compiling resources...\r")
io.flush()
local rc_success = os.execute(compile_rc)
print_status(rc_success, "Compiling resources...")

-- Build Odin executable with lld
io.write("Building Odin executable with lld...\r")
io.flush()
local odin_build_success = execute_command(buiuld_odin)
print_status(odin_build_success, "Building Odin executable with lld...")

-- (Optional) Compress executable with upx
-- io.write("Compressing executable with upx...\r")
-- io.flush()
-- local upx_success = os.execute('upx "winfo.exe"') == 0
-- print_status(upx_success, "Compressing executable")

-- Final summary (optional)
if c_utils_success and rc_success and odin_build_success then   -- and upx_success
else
    print("\nBuild errors detected. See error messages above.")
end
