package winfo

import "core:strings"
import rl "vendor:raylib"
import "core:fmt"
import win "core:sys/windows"

draw_ui :: proc() {
    // Calculate dimensions based on window size
    padding := f32(10)
    label_width := f32(100)
    value_width := f32(s.window_width) - label_width - padding * 3
    line_height := f32(24) // Reduced height to fit more content
    start_x := f32(5)
    start_y := f32(5)
    
    // Create a panel to contain all elements
    panel_rect := rl.Rectangle{
        x = start_x,
        y = start_y,
        width = f32(s.window_width) - padding,
        height = f32(s.window_height) - padding,
    }
    rl.GuiPanel(panel_rect, "Window Info")
    
    // Window Title
    title_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = start_y + padding + line_height,
        width = label_width,
        height = line_height,
    }
    rl.GuiLabel(title_label_rect, "Title:")
    
    title_value_rect := rl.Rectangle{
        x = title_label_rect.x + label_width + padding,
        y = title_label_rect.y,
        width = value_width,
        height = line_height,
    }
    rl.GuiTextBox(title_value_rect, strings.clone_to_cstring(s.window_title), 256, false)
    
    // Window Class
    class_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = title_label_rect.y + line_height + padding,
        width = label_width,
        height = line_height,
    }
    rl.GuiLabel(class_label_rect, "Class:")
    
    class_value_rect := rl.Rectangle{
        x = class_label_rect.x + label_width + padding,
        y = class_label_rect.y,
        width = value_width,
        height = line_height,
    }
    rl.GuiTextBox(class_value_rect, strings.clone_to_cstring(s.window_class), 256, false)
    
    // Window Style
    style_text := fmt.tprintf("0x%x", s.window_info.dwStyle)
    style_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = class_label_rect.y + line_height + padding,
        width = label_width,
        height = line_height,
    }
    rl.GuiLabel(style_label_rect, "Style:")
    
    style_value_rect := rl.Rectangle{
        x = style_label_rect.x + label_width + padding,
        y = style_label_rect.y,
        width = value_width,
        height = line_height,
    }
    rl.GuiTextBox(style_value_rect, strings.clone_to_cstring(style_text), 256, false)
    
    // Window ExStyle
    exstyle_text := fmt.tprintf("0x%x", s.window_info.dwExStyle)
    exstyle_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = style_label_rect.y + line_height + padding,
        width = label_width,
        height = line_height,
    }
    rl.GuiLabel(exstyle_label_rect, "ExStyle:")
    
    exstyle_value_rect := rl.Rectangle{
        x = exstyle_label_rect.x + label_width + padding,
        y = exstyle_label_rect.y,
        width = value_width,
        height = line_height,
    }
    rl.GuiTextBox(exstyle_value_rect, strings.clone_to_cstring(exstyle_text), 256, false)
    
    // Window State
    state_text := fmt.tprintf("State: %s", 
        s.window_info.dwWindowStatus == 0x0001 ? "Active" : "Inactive")
    
    state_label_rect := rl.Rectangle{
        x = start_x + padding,
        y = exstyle_label_rect.y + line_height + padding,
        width = panel_rect.width - padding * 2,
        height = line_height,
    }
    rl.GuiLabel(state_label_rect, strings.clone_to_cstring(state_text))
}