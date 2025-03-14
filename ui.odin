package winfo

import "core:fmt"
import "core:strings"
import win "core:sys/windows"
import rl "vendor:raylib"

draw_ui :: proc() {
	scroll_pos := f32(0)
	padding := f32(10)
	label_width := f32(100)
	content_width := f32(s.window_width) - padding
	value_width := content_width - label_width - padding
	line_height := f32(24)
	start_x := f32(5)
	start_y := f32(5) - scroll_pos

    if s.copy_feedback_timer > 0 {
        s.copy_feedback_timer -= rl.GetFrameTime()
    }

    s.last_click_pos = rl.GetMousePosition()

    current_y := start_y + padding + line_height
    
    // Window Handle
    handle_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height,
    }
    draw_copyable_text(handle_rect, "Handle:", s.handle_text)
    current_y += line_height + padding
    
    // Window Title
    title_label := rl.Rectangle{x = start_x + padding, y = current_y, width = label_width, height = line_height}
    title_value := rl.Rectangle{
        x = start_x + label_width + padding * 2,
        y = current_y,
        width = value_width - padding * 2,
        height = line_height,
    }
    rl.GuiLabel(title_label, "Title:")
    draw_copyable_text(title_value, "Title", s.window_title, true)
    current_y += line_height + padding
    
    // Window Class
    class_label := rl.Rectangle{x = start_x + padding, y = current_y, width = label_width, height = line_height}
    class_value := rl.Rectangle{
        x = start_x + label_width + padding * 2,
        y = current_y,
        width = value_width - padding * 2,
        height = line_height,
    }
    rl.GuiLabel(class_label, "Class:")
    draw_copyable_text(class_value, "Class", s.window_class, true)
    current_y += line_height + padding
    
    // Window Position and Size
    rect_info_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height,
    }
    draw_copyable_text(rect_info_rect, "Position/Size", s.rect_info)
    current_y += line_height + padding
    
    // Client Area
    client_info_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height,
    }
    draw_copyable_text(client_info_rect, "Client Area", s.client_info)
    current_y += line_height + padding
    
    // Borders
    border_info_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height,
    }
    draw_copyable_text(border_info_rect, "Borders", s.border_info)
    current_y += line_height + padding
    
    // Window Styles
    style_text := fmt.tprintf("Style (0x%x):", s.window_info.dwStyle)
    style_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height,
    }
    draw_copyable_text(style_label_rect, "Style", style_text)
    current_y += line_height
    
    style_value_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height * 2,
    }
    draw_copyable_text(style_value_rect, "Style Flags", s.decoded_style, true)
    current_y += line_height * 2 + padding
    
    // Extended Styles
    exstyle_text := fmt.tprintf("Extended Style (0x%x):", s.window_info.dwExStyle)
    exstyle_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height,
    }
    draw_copyable_text(exstyle_label_rect, "Extended Style", exstyle_text)
    current_y += line_height
    
    exstyle_value_rect := rl.Rectangle{
        x = start_x + padding,
        y = current_y,
        width = content_width - padding * 2,
        height = line_height * 2,
    }
    draw_copyable_text(exstyle_value_rect, "Extended Style Flags", s.decoded_ex_style, true)

    // Draw copy feedback
    if s.copy_feedback_timer > 0 {
        feedback_text := "Copied to clipboard!"
        feedback_size := rl.MeasureTextEx(s.winfo_font, strings.clone_to_cstring(feedback_text), 20, 1)
        feedback_rect := rl.Rectangle{
            f32(s.window_width) / 2 - feedback_size.x / 2,
            f32(s.window_height) - 40,
            feedback_size.x + 20,
            30,
        }
        alpha := u8(255.0 * s.copy_feedback_timer)
        rl.DrawRectangleRec(feedback_rect, rl.Color{40, 40, 40, alpha})
        rl.DrawTextEx(
            s.winfo_font,
            strings.clone_to_cstring(feedback_text),
            rl.Vector2{feedback_rect.x + 10, feedback_rect.y + 5},
            20,
            1,
            rl.Fade(rl.WHITE, s.copy_feedback_timer),
        )
    }
}

check_and_copy :: proc(rect: rl.Rectangle, text: string) -> bool {
	if rl.CheckCollisionPointRec(s.last_click_pos, rect) && rl.IsMouseButtonPressed(.LEFT) {
		if len(s.copied_text) > 0 do delete(s.copied_text)
		s.copied_text = strings.clone(text)
		if setClipboardText(win.utf8_to_wstring(s.copied_text), s.main_hwnd) != win.TRUE {
            log_err("error setting clipboard contents")
            return false
        }
		s.copy_feedback_timer = 1.0
		return true
	}
	return false
}

draw_copyable_text :: proc(
	rect: rl.Rectangle,
	label: string,
	value: string,
	is_textbox: bool = false,
) {
	// Draw regular element
	if is_textbox {
		rl.GuiTextBox(rect, strings.clone_to_cstring(value), 1024, false)
	} else {
		rl.GuiLabel(rect, strings.clone_to_cstring(value))
	}

	// Check for hover and show copy hint
	if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect) {
		// Draw a subtle highlight or indicator
		rl.DrawRectangleLinesEx(rect, 1, rl.Fade(rl.WHITE, 0.3))

		// Draw tooltip
		mouse_pos := rl.GetMousePosition()
		tooltip_text := "Click to copy"
		tooltip_size := rl.MeasureTextEx(s.winfo_font, strings.clone_to_cstring(tooltip_text), 16, 1)
		tooltip_rect := rl.Rectangle {
			mouse_pos.x + 10,
			mouse_pos.y + 10,
			tooltip_size.x + 10,
			tooltip_size.y + 5,
		}
		rl.DrawRectangleRec(tooltip_rect, rl.Color{40, 40, 40, 230})
		rl.DrawTextEx(
			s.winfo_font,
			strings.clone_to_cstring(tooltip_text),
			rl.Vector2{tooltip_rect.x + 5, tooltip_rect.y + 2},
			16,
			1,
			rl.WHITE,
		)
	}
    
    check_and_copy(rect, value)
}

decode_window_style :: proc(style: win.DWORD) -> string {
	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	// Common window styles
	if style & win.WS_BORDER != 0 do strings.write_string(&builder, "WS_BORDER, ")
	if style & win.WS_CAPTION != 0 do strings.write_string(&builder, "WS_CAPTION, ")
	if style & win.WS_CHILD != 0 do strings.write_string(&builder, "WS_CHILD, ")
	if style & win.WS_CLIPCHILDREN != 0 do strings.write_string(&builder, "WS_CLIPCHILDREN, ")
	if style & win.WS_CLIPSIBLINGS != 0 do strings.write_string(&builder, "WS_CLIPSIBLINGS, ")
	if style & win.WS_DISABLED != 0 do strings.write_string(&builder, "WS_DISABLED, ")
	if style & win.WS_DLGFRAME != 0 do strings.write_string(&builder, "WS_DLGFRAME, ")
	if style & win.WS_GROUP != 0 do strings.write_string(&builder, "WS_GROUP, ")
	if style & win.WS_HSCROLL != 0 do strings.write_string(&builder, "WS_HSCROLL, ")
	if style & win.WS_MAXIMIZE != 0 do strings.write_string(&builder, "WS_MAXIMIZE, ")
	if style & win.WS_MAXIMIZEBOX != 0 do strings.write_string(&builder, "WS_MAXIMIZEBOX, ")
	if style & win.WS_MINIMIZE != 0 do strings.write_string(&builder, "WS_MINIMIZE, ")
	if style & win.WS_MINIMIZEBOX != 0 do strings.write_string(&builder, "WS_MINIMIZEBOX, ")
	if style & win.WS_OVERLAPPED != 0 do strings.write_string(&builder, "WS_OVERLAPPED, ")
	if style & win.WS_POPUP != 0 do strings.write_string(&builder, "WS_POPUP, ")
	if style & win.WS_SIZEBOX != 0 do strings.write_string(&builder, "WS_SIZEBOX, ")
	if style & win.WS_SYSMENU != 0 do strings.write_string(&builder, "WS_SYSMENU, ")
	if style & win.WS_TABSTOP != 0 do strings.write_string(&builder, "WS_TABSTOP, ")
	if style & win.WS_VISIBLE != 0 do strings.write_string(&builder, "WS_VISIBLE, ")
	if style & win.WS_VSCROLL != 0 do strings.write_string(&builder, "WS_VSCROLL, ")

	result := strings.to_string(builder)
	if len(result) > 2 {
		result = result[:len(result) - 2] // Remove trailing ", "
	}
	return result
}

decode_window_ex_style :: proc(style: win.DWORD) -> string {
	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	// Extended window styles
	if style & win.WS_EX_ACCEPTFILES != 0 do strings.write_string(&builder, "WS_EX_ACCEPTFILES, ")
	if style & win.WS_EX_APPWINDOW != 0 do strings.write_string(&builder, "WS_EX_APPWINDOW, ")
	if style & win.WS_EX_CLIENTEDGE != 0 do strings.write_string(&builder, "WS_EX_CLIENTEDGE, ")
	if style & win.WS_EX_COMPOSITED != 0 do strings.write_string(&builder, "WS_EX_COMPOSITED, ")
	if style & win.WS_EX_CONTEXTHELP != 0 do strings.write_string(&builder, "WS_EX_CONTEXTHELP, ")
	if style & win.WS_EX_CONTROLPARENT != 0 do strings.write_string(&builder, "WS_EX_CONTROLPARENT, ")
	if style & win.WS_EX_DLGMODALFRAME != 0 do strings.write_string(&builder, "WS_EX_DLGMODALFRAME, ")
	if style & win.WS_EX_LAYERED != 0 do strings.write_string(&builder, "WS_EX_LAYERED, ")
	if style & win.WS_EX_LAYOUTRTL != 0 do strings.write_string(&builder, "WS_EX_LAYOUTRTL, ")
	if style & win.WS_EX_LEFT != 0 do strings.write_string(&builder, "WS_EX_LEFT, ")
	if style & win.WS_EX_LEFTSCROLLBAR != 0 do strings.write_string(&builder, "WS_EX_LEFTSCROLLBAR, ")
	if style & win.WS_EX_MDICHILD != 0 do strings.write_string(&builder, "WS_EX_MDICHILD, ")
	if style & win.WS_EX_NOACTIVATE != 0 do strings.write_string(&builder, "WS_EX_NOACTIVATE, ")
	if style & win.WS_EX_NOINHERITLAYOUT != 0 do strings.write_string(&builder, "WS_EX_NOINHERITLAYOUT, ")
	if style & win.WS_EX_NOPARENTNOTIFY != 0 do strings.write_string(&builder, "WS_EX_NOPARENTNOTIFY, ")
	if style & win.WS_EX_OVERLAPPEDWINDOW != 0 do strings.write_string(&builder, "WS_EX_OVERLAPPEDWINDOW, ")
	if style & win.WS_EX_PALETTEWINDOW != 0 do strings.write_string(&builder, "WS_EX_PALETTEWINDOW, ")
	if style & win.WS_EX_TOPMOST != 0 do strings.write_string(&builder, "WS_EX_TOPMOST, ")
	if style & win.WS_EX_TRANSPARENT != 0 do strings.write_string(&builder, "WS_EX_TRANSPARENT, ")
	if style & win.WS_EX_TOOLWINDOW != 0 do strings.write_string(&builder, "WS_EX_TOOLWINDOW, ")

	result := strings.to_string(builder)
	if len(result) > 2 {
		result = result[:len(result) - 2] // Remove trailing ", "
	}
	return result
}

init_window_info_strings :: proc() {
	// Free any existing strings
	if len(s.decoded_style) > 0 do delete(s.decoded_style)
	if len(s.decoded_ex_style) > 0 do delete(s.decoded_ex_style)
	if len(s.handle_text) > 0 do delete(s.handle_text)
	if len(s.rect_info) > 0 do delete(s.rect_info)
	if len(s.client_info) > 0 do delete(s.border_info)
	if len(s.border_info) > 0 do delete(s.border_info)

	// Create new strings
	s.decoded_style = decode_window_style(s.window_info.dwStyle)
	s.decoded_ex_style = decode_window_ex_style(s.window_info.dwExStyle)
	s.handle_text = fmt.tprintf("Handle: 0x%x", win.HWND(s.target_hwnd))
	s.rect_info = fmt.tprintf(
		"Position: (%d, %d) Size: %d x %d",
		s.window_info.rcWindow.left,
		s.window_info.rcWindow.top,
		s.window_info.rcWindow.right - s.window_info.rcWindow.left,
		s.window_info.rcWindow.bottom - s.window_info.rcWindow.top,
	)
	s.client_info = fmt.tprintf(
		"Client Area: (%d, %d) Size: %d x %d",
		s.window_info.rcClient.left,
		s.window_info.rcClient.top,
		s.window_info.rcClient.right - s.window_info.rcClient.left,
		s.window_info.rcClient.bottom - s.window_info.rcClient.top,
	)
	s.border_info = fmt.tprintf(
		"Borders - Left: %d, Right: %d, Top: %d, Bottom: %d",
		s.window_info.cxWindowBorders,
		s.window_info.cxWindowBorders,
		s.window_info.cyWindowBorders,
		s.window_info.cyWindowBorders,
	)
}
