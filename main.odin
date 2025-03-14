package winfo

import client "./odin-http/client"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:sync"
import win "core:sys/windows"
import "core:thread"
import rl "vendor:raylib"

log_err :: proc(msg: cstring, args: ..any) {
	rl.TraceLog(rl.TraceLogLevel.ERROR, msg, args)
}

log_info :: proc(msg: cstring, args: ..any) {
	rl.TraceLog(rl.TraceLogLevel.INFO, msg, args)
}

State :: struct {
	click_point:         win.POINT,
	did_click:           bool,
	window_title:        string,
	window_class:        string,
	window_info:         win.WINDOWINFO,
	target_hwnd:         win.HWND,
	winfo_font:          rl.Font,
	window_position:     rl.Vector2,
	window_width:        i32,
	window_height:       i32,
	main_hwnd:           win.HWND,
	mouse_position:      rl.Vector2,
	pan_offset:          rl.Vector2,
	drag_window:         bool,
	frames:              int,
	last_click_pos:      rl.Vector2,
	copied_text:         string,
	copy_feedback_timer: f32,
	// ui strings
	decoded_style:       string,
	decoded_ex_style:    string,
	handle_text:         string,
	rect_info:           string,
	client_info:         string,
	border_info:         string,
}

s := State {
	did_click     = false,
	window_width  = 500,
	window_height = 500,
	pan_offset    = rl.GetMousePosition(),
}

s_mutex := sync.Mutex{}
click_detected := sync.Sema{} // sema balls

init_hook :: proc() {
	if init_mouse_hook() != .OK {
		return
	}

	log_info("mouse hook: OK")
	dummy_message_loop() // needs to be on the same thread, but works like this
	return
}

dummy_message_loop :: proc() {
	log_info("dummy message loop: OK")

	msg: win.MSG
	for win.GetMessageW(&msg, nil, 0, 0) > 0 {
		win.TranslateMessage(&msg)
		win.DispatchMessageW(&msg)
	}
}

main :: proc() {
	log_info("winfo opened, listening for input")

	thread.create_and_start(init_hook, nil, nil, true)

	sync.sema_wait(&click_detected)
	win.PostQuitMessage(0)

	if remove_mouse_hook() != .OK {
		return
	}

	get_window_info(s.click_point)

	// get_file("https://www.google.com/", "test/test.html") // tests the http get request

	rl.SetConfigFlags(
		rl.ConfigFlags {
			.WINDOW_UNDECORATED,
			.WINDOW_TRANSPARENT,
			.WINDOW_TOPMOST,
			.MSAA_4X_HINT,
			.WINDOW_HIGHDPI,
		},
	)
	rl.InitWindow(s.window_width, s.window_height, "winfo")
	defer {
		if len(s.decoded_style) > 0 do delete(s.decoded_style)
		if len(s.decoded_ex_style) > 0 do delete(s.decoded_ex_style)
		if len(s.handle_text) > 0 do delete(s.handle_text)
		if len(s.rect_info) > 0 do delete(s.rect_info)
		if len(s.client_info) > 0 do delete(s.client_info)
		if len(s.border_info) > 0 do delete(s.border_info)
		rl.CloseWindow()
	}
	rl.SetWindowState(
		rl.ConfigFlags {
			.WINDOW_UNDECORATED,
			.WINDOW_TRANSPARENT,
			.WINDOW_TOPMOST,
			.MSAA_4X_HINT,
			.WINDOW_HIGHDPI,
		},
	)
	s.window_position = rl.GetWindowPosition()
	rl.SetTargetFPS(144)
	rl.SetWindowPosition(s.window_info.rcClient.left, s.window_info.rcClient.top)
	get_file(
		"https://github.com/kociumba/winfo/raw/refs/heads/main/assets/dark.rgs",
		"assets/dark.rgs",
	)
	rl.GuiLoadStyle("assets/dark.rgs")

	get_file(
		"https://github.com/kociumba/winfo/raw/refs/heads/main/assets/BaiJamjuree-Regular.ttf",
		"assets/BaiJamjuree-Regular.ttf",
	)
	s.winfo_font = rl.LoadFontEx("assets/BaiJamjuree-Regular.ttf", 32, nil, 250)
	defer rl.UnloadFont(s.winfo_font)

	s.main_hwnd = getWindowFromPoint(
		win.POINT{s.window_info.rcClient.left + 1, s.window_info.rcClient.top + 1},
	)

	// fmt.println(main_hwnd)

	// init_window_info_strings()

	main_loop: for !rl.WindowShouldClose() {
		if s.frames == 1 {
			rl.SetWindowPosition(s.window_info.rcClient.left, s.window_info.rcClient.top)
			init_window_info_strings()
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.Color{0, 0, 0, 200})

		drag()

		draw_ui()

		rl.EndDrawing()

		s.frames += 1
	}
}

drag :: proc() {
	s.mouse_position = rl.GetMousePosition()

	if (rl.IsMouseButtonPressed(.LEFT) && !s.drag_window) {
		if rl.CheckCollisionPointRec(
			s.mouse_position,
			(rl.Rectangle){0, 0, f32(s.window_width), f32(s.window_height)},
		) {
			s.drag_window = true
			s.pan_offset = s.mouse_position
		}
	}

	if s.drag_window {
		s.window_position.x += (s.mouse_position.x - s.pan_offset.x)
		s.window_position.y += (s.mouse_position.y - s.pan_offset.y)

		rl.SetWindowPosition(i32(s.window_position.x), i32(s.window_position.y))

		if rl.IsMouseButtonReleased(.LEFT) {s.drag_window = false}
	}
}

// get's a file from github repo, couse i don't want to package it
get_file :: proc(from, to: string) {
	abs, _ := filepath.abs(to)
	if !os.exists(abs) {
		if os.make_directory(filepath.dir(abs)) != nil {
			log_err("failed to create dir: %s", strings.clone_to_cstring(filepath.dir(abs)))
		}

		res, err := client.get(from)
		if err != nil {
			log_err("failed to get resource from: %s", strings.clone_to_cstring(from))
			return
		}
		defer client.response_destroy(&res)

		body, allocation, berr := client.response_body(&res)
		if berr != nil {
			log_err("failed to get response body")
			return
		}
		defer client.body_destroy(body, allocation)

		f, ferr := os.open(abs, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
		if ferr != nil {
			log_err("failed to create final file")
		}
		defer os.close(f)

		_, werr := os.write(f, transmute([]u8)fmt.aprint(body))
		if werr != nil {
			log_err("error writing the data to file")
			return
		}
	}
}
