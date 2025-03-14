#include <windows.h>
#include <winuser.h>
#include <string.h>
#include <wchar.h>

// amazing code, but the easiest way to do this since this win32 function is missing in odin "core:sys/windows"
extern HWND getWindowFromPoint(POINT point) {
    return WindowFromPoint(point);
}

extern BOOL setClipboardText(wchar_t* text, HWND hwnd) {
    if (!OpenClipboard(hwnd)) {
        return FALSE;
    }
    EmptyClipboard();

    size_t text_len = wcslen(text);
    size_t buffer_size = text_len + 1;
    size_t mem_size = buffer_size * sizeof(wchar_t);

    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, mem_size);
    if (hMem == NULL) {
        CloseClipboard();
        return FALSE;
    }

    wchar_t* pMem = (wchar_t*)GlobalLock(hMem);
    if (pMem == NULL) {
        GlobalFree(hMem);
        CloseClipboard();
        return FALSE;
    }

    __auto_type err = wcscpy_s(pMem, buffer_size, text);
    if (err != 0) {
        GlobalUnlock(hMem);
        GlobalFree(hMem);
        CloseClipboard();
        return FALSE;
    }

    GlobalUnlock(hMem);

    if (SetClipboardData(CF_UNICODETEXT, hMem) == NULL) {
        GlobalFree(hMem);
        CloseClipboard();
        return FALSE;
    }

    CloseClipboard();
    return TRUE;
}