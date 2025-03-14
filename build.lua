-- build commands
local build_c = 'zig cc -c "c/utils.c" -target x86_64-windows-msvc -static -o "winfo_utils.lib"'
local compile_rc = 'rc "winfo.rc" > nul'
local build_odin = 'odin build . -o:speed -linker:lld -min-link-libs -extra-linker-flags:"winfo.res"'
local pack_upx = 'upx "winfo.exe" > nul'

local function has_arg(argument)
    for i = 1, #arg do
        if arg[i] == argument then
            return true, i
        end
    end
    return false
end

if has_arg("-windows") then
    build_odin = build_odin .. " -subsystem:windows"
end

local threads_flag, index = has_arg("-j")

if threads_flag then
    if not tonumber(arg[index + 1]) then
        print("Provide a number of threads after -j, for example: -j 8")
        os.exit(1)
    end

    local threads = tonumber(arg[index + 1])

    build_odin = build_odin .. " -thread-count:" .. tostring(threads)
end

local function execute_command(command)
    local status = os.execute(command)
    return status
end

-- Nice color formatting couse why not
local function print_status(success, message)
    local color_code = success and "\027[38;5;112m" or "\027[38;5;196m"
    local status_text = success and "[OK]" or "[ERROR]"
    local reset_code = "\027[0m"

    io.write("\r" .. message .. " " .. color_code .. status_text .. reset_code .. "\n")
    io.flush()
end

-- Compile C deps
io.write("Compiling C deps...\r")
io.flush()
local c_utils_success = execute_command(build_c)
print_status(c_utils_success, "Compiling C deps...")

-- Compile resources
io.write("Compiling resources...\r")
io.flush()
local rc_success = os.execute(compile_rc)
print_status(rc_success, "Compiling resources...")

-- Build Odin executable with lld
io.write("Building Odin executable...\r")
io.flush()
local odin_build_success = execute_command(build_odin)
print_status(odin_build_success, "Building Odin executable...")

-- (Optional) Compress executable with upx
local upx_success
if has_arg("-upx") then
    io.write("Compressing executable with upx...\r")
    io.flush()
    upx_success = os.execute(pack_upx)
    print_status(upx_success, "Compressing executable with upx...")
else
    upx_success = true
end

if not (c_utils_success and rc_success and odin_build_success and upx_success) then
    print("\nBuild errors detected. See error messages above.")
    os.exit(1)
end

if has_arg("-run") then
    os.execute("winfo.exe")
end
