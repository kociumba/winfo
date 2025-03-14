package winfo

import rl "vendor:raylib"
import win "core:sys/windows"
import "core:fmt"
import "core:strings"
import "base:runtime"
import "core:reflect"

foreign import winfo_utils "winfo_utils.lib"
foreign winfo_utils {
    getWindowFromPoint :: proc(point: win.POINT) -> win.HWND ---
}

get_window_info :: proc(point: win.POINT) {
    hwnd := getWindowFromPoint(s.click_point)

    if hwnd != nil {
        title_buffer: [256]win.WCHAR
        class_buffer: [256]win.WCHAR
        info_buffer: win.PWINDOWINFO = &win.WINDOWINFO{cbSize = size_of(win.WINDOWINFO)}
        err: runtime.Allocator_Error

        title_len := win.GetWindowTextW(hwnd, &title_buffer[0], i32(len(title_buffer)))
        class_len := win.GetClassNameW(hwnd, &class_buffer[0], i32(len(class_buffer)))
        if win.GetWindowInfo(hwnd, info_buffer) != win.TRUE {
            log_err("failed to get window info")
        }

        s.window_title, err = win.utf16_to_utf8(title_buffer[:])
        if err != .None {
            log_err(strings.clone_to_cstring(reflect.enum_string(err)))
        }
        s.window_class, err = win.utf16_to_utf8(class_buffer[:])
        if err != .None {
            log_err(strings.clone_to_cstring(reflect.enum_string(err)))
        }
        s.window_info = info_buffer^

        fmt.println(info_buffer)

        log_info(strings.clone_to_cstring(fmt.aprint(s)))
    } else {
        log_err("no window found at click point")
    }
}

get_window_info_string :: proc(s: State) -> string {
    return fmt.aprint(s.window_info)
}

window_info_string_formatted :: proc(wi: win.WINDOWINFO, font: rl.Font) -> string {
    info_str_builder: [7]cstring
    res_str := ""

    info_str_builder[0] = rl.TextFormat("Style: %x\n", wi.dwStyle)
    info_str_builder[1] = rl.TextFormat("ExStyle: %x\n", wi.dwExStyle)
    info_str_builder[2] = rl.TextFormat("Window Rect: %v\n", wi.rcWindow)
    info_str_builder[3] = rl.TextFormat("Client Rect: %v\n", wi.rcClient)
    info_str_builder[4] = rl.TextFormat("Window Status: %x\n", wi.dwWindowStatus)
    info_str_builder[5] = rl.TextFormat("X: %d, Y: %d\n", wi.rcWindow.left, wi.rcWindow.top)
    info_str_builder[6] = rl.TextFormat("Width: %d, Height: %d\n", wi.rcWindow.right - wi.rcWindow.left, wi.rcWindow.bottom - wi.rcWindow.top)

    for str in info_str_builder {
        strings.concatenate({res_str, string(str)})
    }

    return res_str
}