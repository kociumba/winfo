#include <windows.h>
#include <winuser.h>

// amazing code, but the easiest way to do this since this win32 function is missing in odin "core:sys/windows"
extern HWND getWindowFromPoint(POINT point) {
    return WindowFromPoint(point);
}
