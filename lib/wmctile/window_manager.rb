class Wmctile::WindowManager < Wmctile::ClassWithDmenu
  attr_accessor :w, :h, :workspace, :windows

  def initialize(settings)
    @settings = settings
    init_dimensions
  end

  def init_dimensions
    # legacy (but fast) method via wmctrl
    dimensions = cmd("wmctrl -d | awk '{ print $9 }' | head -n1").split('x')
    # xrandr is slower, but offers more information
    # dimensions = cmd("xrandr | grep -E '\sconnected\s[0-9]+x[0-9]+\+0' | awk '{print $3}' | awk -F'+' '{print $1}'").split('x')
    @w = dimensions[0].to_i - 2 * @settings.window_border
    @h = dimensions[1].to_i - 2 * @settings.window_border - @settings.panel_height
    @workspace = cmd("wmctrl -d | grep '\*' | awk '{ print $1 }'").to_i
  end

  def width(portion = 1)
    @w * portion
  end

  def height(portion = 1)
    @h * portion
  end

  def get_window(window_str = nil, all_workspaces = false)
    if window_str.nil?
      window = ask_for_window all_workspaces
    else
      return window_str if window_str.is_a? Wmctile::Window
      if window_str == ':ACTIVE:'
        window = get_active_window
      else
        window = find_window window_str, all_workspaces
        unless window
          # does window_str have an icon bundle in it? (aka evince.Evince)
          if window_str =~ /[a-z0-9]+\.[a-z0-9]+/i
            icon = window_str.split('.').first
          else
            icon = nil
          end
          notify 'No window found', "#{window_str}", icon
        end
      end
    end
    window
  end

  def get_active_window
    win_id = cmd('wmctrl -a :ACTIVE: -v 2>&1').split('Using window: ').last
    Wmctile::Window.new win_id, @settings
  end

  def find_window(window_string, all_workspaces = false)
    cmd = "wmctrl -lx | grep -F #{window_string}"
    cmd += ' | grep -E \'0x\w+\s+' + @workspace.to_s + '\s+\'' unless all_workspaces
    window_string = self.cmd cmd
    window_string = window_string.split("\n").first
    if window_string.nil?
      return nil
    else
      return Wmctile::Window.new window_string, @settings
    end
  end

  def find_windows(window_string, all_workspaces = false)
    cmd = "wmctrl -lx | grep -F #{window_string}"
    cmd += ' | grep -E \'0x\w+\s+' + @workspace.to_s + '\s+\'' unless all_workspaces
    window_strings = self.cmd cmd
    window_strings = window_strings.split("\n")
    if window_string.nil?
      return nil
    else
      return window_strings.map { |w| Wmctile::Window.new w, @settings }
    end
  end

  def find_in_windows(window_string, all_workspaces = false)
    if window_string.nil?
      ask_for_window all_workspaces
    else
      windows = find_windows window_string, all_workspaces
      if windows
        ids = windows.collect(&:id)
        active_win = get_active_window
        if ids.include? active_win.id
          # cycle through the windows
          i = ids.index active_win.id
          # try the next one
          if ids[i + 1]
            window = windows[i + 1]
          # fallback to the first one
          else
            window = windows.first
          end
        else
          # switch to the first one
          window = windows.first
        end
        return window
      end
      return nil
    end
  end

  def ask_for_window(_all_workspaces = false)
    dmenu windows.map(&:dmenu_item)
  end

  def build_win_list(all_workspaces = false)
    unless all_workspaces
      variable_name = '@windows_on_workspace'
    else
      variable_name = '@windows_all'
    end
    unless instance_variable_get(variable_name)
      unless all_workspaces
        cmd = "wmctrl -lx | grep \" #{@workspace} \""
      else
        cmd = 'wmctrl -lx'
      end
      arr = cmd(cmd).split("\n")

      new_list = arr.map { |w| Wmctile::Window.new(w, @settings) }
      name_length = new_list.map(&:get_name_length).max
      new_list.each { |w| w.set_name_length(name_length) }

      instance_variable_set(variable_name, new_list)
    end
    instance_variable_get(variable_name)
  end

  def windows(all_workspaces = false)
    unless all_workspaces
      variable_name = '@windows_on_workspace'
    else
      variable_name = '@windows_all'
    end
    unless instance_variable_get(variable_name)
      build_win_list all_workspaces
    else
      instance_variable_get(variable_name)
    end
  end

  def calculate_snap(where, portion = 0.5)
    case where
    when 'left'
      {
        x: @settings.panel_width,
        y: @settings.panel_height,
        width: width(portion)
      }
    when 'right'
      {
        x: width(1 - portion),
        y: @settings.panel_height,
        width: width(portion)
      }
    when 'top'
      {
        x: @settings.panel_width,
        y: @settings.panel_height,
        height: height(portion)
      }
    when 'bottom'
      {
        x: @settings.panel_width,
        y: @settings.panel_height + height(1 - portion) + @settings.titlebar_height,
        height: height(portion) - @settings.titlebar_height
      }
    when 'topleft'
      {
        x: @settings.panel_width, y: @settings.panel_height,
        width: width(portion), height: height(0.5)
      }
    when 'topright'
      {
        x: width(portion), y: @settings.panel_height,
        width: width(1 - portion), height: height(0.5)
      }
    when 'bottomleft'
      {
        x: @settings.panel_width, y: @settings.panel_height + height(0.5),
        width: width(portion), height: height(0.5)
      }
    when 'bottomright'
      {
        x: width(portion), y: @settings.panel_height + height(0.5),
        width: width(1 - portion), height: height(0.5)
      }
           end
  end
end
