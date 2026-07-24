-- ============================================================
-- WezTerm Configuration — macOS
-- ============================================================

local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action


-- ============================================================
-- 1. Default Shell & Working Directory
-- ============================================================

config.default_prog = { '/bin/zsh', '-l' }
config.default_cwd = wezterm.home_dir .. '/workspace'


-- ============================================================
-- 2. Window Behavior
-- ============================================================

config.initial_cols = 1
config.initial_rows = 1

config.window_close_confirmation = 'NeverPrompt'

-- macOS 自动使用 Metal，不手动指定

-- 高配渲染优化
config.animation_fps = 120
config.max_fps = 120
config.freetype_load_target = 'HorizontalLcd'
config.freetype_render_target = 'HorizontalLcd'
config.custom_block_glyphs = true


-- ============================================================
-- 3. Launch Menu
-- ============================================================

config.launch_menu = {
  {
    label = 'Workspace',
    args = { '/bin/zsh', '-l' },
    cwd = wezterm.home_dir .. '/workspace',
  },
}


-- ============================================================
-- 4. Colors & Appearance
-- ============================================================

config.color_scheme = 'Catppuccin Mocha'

config.colors = {
  tab_bar = {
    background = 'rgba(30,30,46,0.92)',
    active_tab = {
      bg_color = 'rgba(49,50,68,0.92)',
      fg_color = '#cdd6f4',
    },
    inactive_tab = {
      bg_color = 'rgba(30,30,46,0.92)',
      fg_color = '#6c7086',
    },
    inactive_tab_hover = {
      bg_color = 'rgba(49,50,68,0.92)',
      fg_color = '#cdd6f4',
      italic = false,
    },
    new_tab = {
      bg_color = 'rgba(30,30,46,0.92)',
      fg_color = '#6c7086',
    },
    new_tab_hover = {
      bg_color = 'rgba(49,50,68,0.92)',
      fg_color = '#cdd6f4',
      italic = false,
    },
  },
}

config.window_frame = {
  active_titlebar_bg = 'rgba(30,30,46,0.92)',
  inactive_titlebar_bg = 'rgba(30,30,46,0.92)',
  active_titlebar_fg = '#cdd6f4',
  inactive_titlebar_fg = '#6c7086',
  button_fg = '#cdd6f4',
  button_bg = 'rgba(30,30,46,0)',
  button_hover_fg = '#cdd6f4',
  button_hover_bg = 'rgba(49,50,68,0.92)',
}

config.window_background_opacity = 0.92
config.text_background_opacity = 0.92
config.macos_window_background_blur = 25

config.window_decorations = "RESIZE"

config.use_fancy_tab_bar = true
config.enable_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.4,
}

config.window_padding = {
  left = 10,
  right = 0,
  top = 20,
  bottom = 0,
}


-- ============================================================
-- 5. Font
-- ============================================================

config.font = wezterm.font_with_fallback({
  "Cascadia Code NF",
  "霞鹜文楷等宽",
})

config.font_size = 15


-- ============================================================
-- 6. Leader Key (Cmd + a)
-- ============================================================

config.leader = {
  key = 'a',
  mods = 'CMD',
  timeout_milliseconds = 1000,
}


-- ============================================================
-- 7. Key Bindings
-- ============================================================

config.disable_default_key_bindings = true

config.keys = {
  -- ------------------------------------------------------------
  -- Config / Launcher
  -- ------------------------------------------------------------

  {
    key = 'L',
    mods = 'CTRL|SHIFT',
    action = act.ShowLauncherArgs({ flags = "LAUNCH_MENU_ITEMS" }),
  },
  {
    key = 'r',
    mods = 'LEADER',
    action = act.ReloadConfiguration,
  },
  {
    key = 'P',
    mods = 'CTRL',
    action = act.ActivateCommandPalette,
  },


  -- ------------------------------------------------------------
  -- Window / Tab / Pane Management
  -- ------------------------------------------------------------

  {
    key = 'n',
    mods = 'LEADER',
    action = act.SpawnWindow,
  },
  {
    key = 'q',
    mods = 'LEADER',
    action = act.QuitApplication,
  },
  {
    key = 'w',
    mods = 'LEADER',
    action = act.CloseCurrentTab { confirm = false },
  },
  {
    key = 'w',
    mods = 'CTRL',
    action = act.CloseCurrentPane { confirm = false },
  },
  {
    key = 'n',
    mods = 'ALT',
    action = act.SpawnTab 'CurrentPaneDomain',
  },

  -- Tab 切换
  {
    key = 'Tab',
    mods = 'CTRL',
    action = act.ActivateTabRelative(1),
  },
  {
    key = 'Tab',
    mods = 'CTRL|SHIFT',
    action = act.ActivateTabRelative(-1),
  },
  {
    key = '=',
    mods = 'LEADER',
    action = act.ActivateTabRelative(1),
  },
  {
    key = '-',
    mods = 'LEADER',
    action = act.ActivateTabRelative(-1),
  },

  -- Window 切换
  {
    key = 'L',
    mods = 'LEADER|SHIFT',
    action = act.ActivateWindowRelative(1),
  },
  {
    key = 'H',
    mods = 'LEADER|SHIFT',
    action = act.ActivateWindowRelative(-1),
  },

  -- Pane 分屏
  {
    key = '\\',
    mods = 'LEADER',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = ';',
    mods = 'LEADER',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'i',
    mods = 'LEADER',
    action = act.SplitPane {
      direction = "Down",
      size = { Percent = 30 },
    },
  },

  -- Pane 移动
  {
    key = 'l',
    mods = 'LEADER',
    action = act.ActivatePaneDirection "Right",
  },
  {
    key = 'h',
    mods = 'LEADER',
    action = act.ActivatePaneDirection "Left",
  },
  {
    key = 'j',
    mods = 'LEADER',
    action = act.ActivatePaneDirection "Down",
  },
  {
    key = 'k',
    mods = 'LEADER',
    action = act.ActivatePaneDirection "Up",
  },

  -- Pane Zoom
  {
    key = 'Z',
    mods = 'CTRL',
    action = act.TogglePaneZoomState,
  },
  {
    key = 'i',
    mods = 'CMD|SHIFT',
    action = act.TogglePaneZoomState,
  },


  -- ------------------------------------------------------------
  -- Font Size
  -- ------------------------------------------------------------

  {
    key = '0',
    mods = 'SHIFT|CTRL',
    action = act.ResetFontSize,
  },
  {
    key = '+',
    mods = 'SHIFT|CTRL',
    action = act.IncreaseFontSize,
  },
  {
    key = '-',
    mods = 'SHIFT|CTRL',
    action = act.DecreaseFontSize,
  },


  -- ------------------------------------------------------------
  -- Clipboard (macOS 风格)
  -- ------------------------------------------------------------

  -- Cmd+C: 有选中时复制，没选中时交给 shell (SIGINT)
  {
    key = 'c',
    mods = 'CMD',
    action = act.CopyTo 'Clipboard',
  },
  -- Cmd+V: 粘贴
  {
    key = 'v',
    mods = 'CMD',
    action = act.PasteFrom 'Clipboard',
  },
  -- 保留旧的 Ctrl+Shift+C/V 兼容
  {
    key = 'C',
    mods = 'CTRL|SHIFT',
    action = act.CopyTo 'Clipboard',
  },
  {
    key = 'V',
    mods = 'CTRL|SHIFT',
    action = act.PasteFrom 'Clipboard',
  },


  -- ------------------------------------------------------------
  -- Search / Copy Mode / Quick Select
  -- ------------------------------------------------------------

  {
    key = 'F',
    mods = 'CTRL',
    action = act.Search 'CurrentSelectionOrEmptyString',
  },
  {
    key = 'X',
    mods = 'CTRL',
    action = act.ActivateCopyMode,
  },
  {
    key = 'Q',
    mods = 'CTRL',
    action = act.QuickSelect,
  },


  -- ------------------------------------------------------------
  -- Scrolling
  -- ------------------------------------------------------------

  {
    key = 'PageUp',
    mods = 'SHIFT',
    action = act.ScrollByPage(-1),
  },
  {
    key = 'PageDown',
    mods = 'SHIFT',
    action = act.ScrollByPage(1),
  },


  -- ------------------------------------------------------------
  -- Tab Movement
  -- ------------------------------------------------------------

  {
    key = ',',
    mods = 'LEADER',
    action = act.MoveTabRelative(-1),
  },
  {
    key = '.',
    mods = 'LEADER',
    action = act.MoveTabRelative(1),
  },

  -- Tab 重命名
  {
    key = 't',
    mods = 'LEADER|CMD',
    action = act.PromptInputLine {
      description = '输入 tab 新名称（留空 = 恢复自动，ESC = 取消）',
      action = wezterm.action_callback(function(window, pane, line)
        if line ~= nil then
          window:active_tab():set_title(line)
        end
      end),
    },
  },


  -- ------------------------------------------------------------
  -- Arrow Key Pane Navigation / Resize
  -- ------------------------------------------------------------

  {
    key = 'LeftArrow',
    mods = 'SHIFT|CTRL',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'SHIFT|CTRL',
    action = act.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'SHIFT|CTRL',
    action = act.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'SHIFT|CTRL',
    action = act.ActivatePaneDirection 'Down',
  },

  {
    key = 'LeftArrow',
    mods = 'SHIFT|ALT|CTRL',
    action = act.AdjustPaneSize { 'Left', 1 },
  },
  {
    key = 'RightArrow',
    mods = 'SHIFT|ALT|CTRL',
    action = act.AdjustPaneSize { 'Right', 1 },
  },
  {
    key = 'UpArrow',
    mods = 'SHIFT|ALT|CTRL',
    action = act.AdjustPaneSize { 'Up', 1 },
  },
  {
    key = 'DownArrow',
    mods = 'SHIFT|ALT|CTRL',
    action = act.AdjustPaneSize { 'Down', 1 },
  },
}


-- Ctrl + 数字切换 tab
for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CTRL',
    action = act.ActivateTab(i - 1),
  })
end

-- Cmd + 数字切换 tab
for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CMD',
    action = act.ActivateTab(i - 1),
  })
end

-- Leader + 数字将当前 tab 移到指定位置
for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = act.MoveTab(i - 1),
  })
end


-- ============================================================
-- 8. Key Tables
-- ============================================================

config.key_tables = {
  -- Copy Mode
  copy_mode = {
    {
      key = 'Escape',
      mods = 'NONE',
      action = act.CopyMode 'Close',
    },
    {
      key = 'v',
      mods = 'NONE',
      action = act.CopyMode { SetSelectionMode = 'Cell' },
    },
    {
      key = 'V',
      mods = 'NONE',
      action = act.CopyMode { SetSelectionMode = 'Line' },
    },
    {
      key = 'v',
      mods = 'CTRL',
      action = act.CopyMode { SetSelectionMode = 'Block' },
    },
    {
      key = 'b',
      mods = 'NONE',
      action = act.CopyMode 'MoveBackwardWord',
    },
    {
      key = 'w',
      mods = 'NONE',
      action = act.CopyMode 'MoveForwardWord',
    },
    {
      key = 'e',
      mods = 'NONE',
      action = act.CopyMode 'MoveForwardWordEnd',
    },
    {
      key = 'h',
      mods = 'NONE',
      action = act.CopyMode 'MoveLeft',
    },
    {
      key = 'j',
      mods = 'NONE',
      action = act.CopyMode 'MoveDown',
    },
    {
      key = 'k',
      mods = 'NONE',
      action = act.CopyMode 'MoveUp',
    },
    {
      key = 'l',
      mods = 'NONE',
      action = act.CopyMode 'MoveRight',
    },
    {
      key = 'L',
      mods = 'NONE',
      action = act.CopyMode 'MoveToEndOfLineContent',
    },
    {
      key = 'H',
      mods = 'NONE',
      action = act.CopyMode 'MoveToStartOfLine',
    },
    {
      key = 'y',
      mods = 'NONE',
      action = act.Multiple {
        { CopyTo = 'ClipboardAndPrimarySelection' },
        { CopyMode = 'Close' },
      },
    },
  },

  -- Search Mode
  search_mode = {
    {
      key = 'Enter',
      mods = 'NONE',
      action = act.CopyMode 'PriorMatch',
    },
    {
      key = 'Escape',
      mods = 'NONE',
      action = act.CopyMode 'Close',
    },
    {
      key = 'n',
      mods = 'CTRL',
      action = act.CopyMode 'NextMatch',
    },
    {
      key = 'p',
      mods = 'CTRL',
      action = act.CopyMode 'PriorMatch',
    },
    {
      key = 'r',
      mods = 'CTRL',
      action = act.CopyMode 'CycleMatchType',
    },
    {
      key = 'u',
      mods = 'CTRL',
      action = act.CopyMode 'ClearPattern',
    },
    {
      key = 'PageUp',
      mods = 'NONE',
      action = act.CopyMode 'PriorMatchPage',
    },
    {
      key = 'PageDown',
      mods = 'NONE',
      action = act.CopyMode 'NextMatchPage',
    },
    {
      key = 'UpArrow',
      mods = 'NONE',
      action = act.CopyMode 'PriorMatch',
    },
    {
      key = 'DownArrow',
      mods = 'NONE',
      action = act.CopyMode 'NextMatch',
    },
  },
}


-- ============================================================
-- 9. Mouse Bindings
-- ============================================================

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  {
    event = { Up = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = act.PasteFrom 'Clipboard',
  },
}


-- ============================================================
-- 10. Tab Title Format
-- ============================================================

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1

  local custom = tab.tab_title
  if custom and #custom > 0 then
    local title = custom
    if #title > 20 then
      title = title:sub(1, 17) .. '...'
    end
    return {
      { Text = ' ' .. index .. ': ' .. title .. ' ' },
    }
  end

  local title = tab.active_pane.title
  local cwd = tab.active_pane.current_working_dir
  if cwd then
    local path = cwd.file_path or cwd.path
    if path then
      path = path:gsub('[\\/]+$', '')
      title = path:match('([^\\/]+)$') or title
    end
  end

  if #title > 20 then
    title = title:sub(1, 17) .. '...'
  end

  return {
    { Text = ' ' .. index .. ': ' .. title .. ' ' },
  }
end)


-- ============================================================
-- 11. Startup Window Position
-- ============================================================

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()
  local screen = wezterm.gui.screens().active
  local w = math.floor(screen.width * 0.7)
  local h = math.floor(screen.height * 0.7)
  gui_window:set_inner_size(w, h)
  gui_window:set_position(
    screen.x + (screen.width - w) / 2,
    screen.y + (screen.height - h) / 2
  )
end)


-- ============================================================
-- 12. Right Status
-- ============================================================

wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime('%Y/%m/%d %H:%M:%S')
  window:set_right_status(' ' .. date .. ' ')
end)


-- ============================================================
-- 13. Return Config
-- ============================================================

return config
