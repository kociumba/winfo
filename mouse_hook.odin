package winfo

import win "core:sys/windows"
import "core:sync"

hook_handle: win.HHOOK
hook_proc: win.HOOKPROC

hook_err :: enum {
    OK,
    INIT_FAIL,
    REMOVE_FAIL
}

win32_mouse_hook :: proc(code: win.c_int, wParam: win.WPARAM, lParam: win.LPARAM) -> win.LRESULT {
    if code >= 0 {
        mouse_struct := (^win.MSLLHOOKSTRUCT)(uintptr(lParam))
        if wParam == win.WM_LBUTTONDOWN || wParam == win.WM_NCLBUTTONDOWN {
            sync.mutex_lock(&s_mutex)
            s.click_point = mouse_struct.pt
            s.did_click = true
            sync.mutex_unlock(&s_mutex)
            sync.sema_post(&click_detected)
        }
    }
    return win.CallNextHookEx(hook_handle, code, wParam, lParam)
}

init_mouse_hook :: proc() -> hook_err {
    hook_proc = win.HOOKPROC(win32_mouse_hook)

	hook_handle = win.SetWindowsHookExW(
		win.WH_MOUSE_LL,
		hook_proc,
		win.HANDLE(win.GetModuleHandleW(nil)),
		0,
	)
    if hook_handle == nil {
        err := win.GetLastError()
        log_err("mouse hook failed to initialize, erro: %d", err)
        return hook_err.INIT_FAIL
    }

    return hook_err.OK
}

remove_mouse_hook :: proc() -> hook_err {
    if win.UnhookWindowsHookEx(hook_handle) == win.FALSE {
        log_err("mouse hook failed to unhook")
        return hook_err.REMOVE_FAIL
    }

    return hook_err.OK
}
