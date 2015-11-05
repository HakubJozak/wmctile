class Wmctile::Router < Wmctile::Class
  ##################################
  ## init ##########################
  ##################################
  def initialize
    @settings = Wmctile::Settings.new
    @all_workspaces = false
  end
  ##################################
  ## main dispatch method ##########
  ##################################
  def dispatch(args = [])
    if args.length
      main_arg = args[0]
      if ['--all-workspaces', '-a'].include? main_arg
        @all_workspaces = true
        drop = 2
        main_arg = args[1]
      else
        @all_workspaces = false
        drop = 1
      end
      if main_arg and !%w(dispatch initialize wm wt memory).include? main_arg and self.respond_to? main_arg
        send main_arg, *args.drop(drop)
      else
        help
      end
    else
      help
    end
  end
  ##################################
  ## object getter methods #########
  ##################################
  def wm
    @wm || @wm = Wmctile::WindowManager.new(@settings)
  end

  def wt
    # @wm might be nil
    @wt || @wt = Wmctile::WindowTiler.new(@settings, memory, @wm)
  end

  def memory
    @memory || @memory = Wmctile::Memory.new
  end
  ##################################
  ## actual command-line methods ###
  ##################################
  def help(_args = nil)
    puts <<-eos
wmctile version 0.1.2

usage:
   wmctile [--option1, --option2, ...] <command> ['argument1', 'argument2', ...]

examples:
   wmctile snap 'left' 'terminator'
   wmctile summon --all-workspaces ':ACTIVE:'

options:
   --all-workspaces, -a
      Use all workspaces when searching for windows.

explanation:
  Optional arguments in the "commands" bellow are written in [square brackets]. This syntax only matches the fact that the argument is not required. When it's used, it shouldn't be surrounded by brackets.

commands:
   list
      Lists windows for easier matching.

   summon 'window_string'
      Summons a window matching 'window_str'.

   summon_or_run 'window_string' 'command_to_run'
      Summons a window matching 'window_string'. If no window is found, the 'command_to_run' is run.

   switch_to 'window_string'
      Switches to a window matching 'window_string'.

   switch_to_or_run 'window_string' 'command_to_run'
      Switches to a window matching 'window_string'. If no window is found, the 'command_to_run' is run.

   maximize 'window_string'
      Maximizes a window matching 'window_string'.

   unmaximize 'window_string'
      Unmaximizes a window matching 'window_string'.

   shade 'window_string'
      Shades a window matching 'window_string'.

   unshade 'window_string'
      Unshades a window matching 'window_string'.

   unshade_last_shaded
      Unshades the last shaded window on active workspace.

   snap 'where' 'window_string' ['portion']
      Snaps a window matching 'window_string' to occupy the 'where' 'portion' of the screen.
         'where' can be one of 'left', 'right', 'top', 'bottom'
         'portion' is a float number with the default of 0.5

   resize 'where' ['portion']
      Resizes the last performed action (snap/tile etc.) on active workspace.
         'where' can be one of 'left', 'right', 'top', 'bottom'
             The action depends on the previously performed action. When you resize 'left' a previous snap 'left', you're shrinking the window. When you resize 'left' a previous snap 'right', you're increasing the size of the window.
         'portion' is a float number by which to edit the previous portion of the screen with the default of 0.01.

   resize_snap 'where' ['portion']
      Resizes the last performed snap on active workspace. Arguments are the same as in resize command.

additional information:
   To use the active window, pass ':ACTIVE:' as the 'window_string' argument.
    eos
  end

  def list
    on_workspace = wm.windows
    all_windows = wm.windows true

    puts 'Windows on current workspace:'
    names = on_workspace.map(&:name)
    names.uniq.each { |w| puts "   #{w}" }
    puts '', 'Windows on all workspaces:'
    names = all_windows.map(&:name)
    names.uniq.each { |w| puts "   #{w}" }
  end

  def summon(window_str)
    window = wm.find_in_windows window_str, @all_workspaces
    if window
      window.summon
      return true
    else
      return false
    end
  end

  def summon_or_run(window_str, cmd_to_run)
    cmd "#{cmd_to_run} > /dev/null &" unless summon window_str
  end

  def switch_to(window_str)
    window = wm.find_in_windows window_str, @all_workspaces
    if window
      window.switch_to
      return true
    else
      return false
    end
  end

  def switch_to_or_run(window_str, cmd_to_run)
    cmd "#{cmd_to_run} > /dev/null &" unless switch_to window_str
  end

  def maximize(window_str)
    window = wm.get_window window_str
    window.maximize if window
  end

  def unmaximize(window_str)
    window = wm.get_window window_str
    window.unmaximize if window
  end

  def shade(window_str)
    window = wm.get_window window_str
    if window
      window.shade
      memory.set wm.workspace, 'shade',	'window_id' => window.id
    end
  end

  def unshade(window_str)
    window = wm.get_window window_str
    if window
      window.unshade
      memory.set wm.workspace, 'unshade',	'window_id' => window.id
    end
  end

  def unshade_last_shaded
    win_id = memory.get wm.workspace, 'shade', 'window_id'
    window = Wmctile::Window.new win_id, @settings
    if window
      window.unshade
      memory.set wm.workspace, 'unshade',	'window_id' => window.id
    end
  end

  def snap(where = 'left', window_str = nil, portion = 0.5)
    wt.snap where, window_str, portion
  end

  def resize(where = 'left', portion = 0.01)
    wt.resize where, portion
  end

  def resize_snap(where = 'left', portion = 0.01)
    wt.resize_snap where, portion
  end

  def resize_snap(where = 'left', portion = 0.01)
    wt.resize_snap where, portion
  end

  def tile(*args)
    wt.tile *args
  end
end
