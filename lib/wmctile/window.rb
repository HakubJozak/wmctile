class Wmctile::Window < Wmctile::Class
  attr_accessor :id, :name, :title

  def initialize(win_string, settings)
    @default_movement = { x: 0, y: 0, width: '-1', height: '-1' }
    @settings = settings
    @id = win_string[/0x[\d\w]{8}/]
    get_name_and_title win_string
  end

  def get_name_and_title(win_string)
    if win_string == @id
      @name = ''
      @title = ''
    else
      after_id_and_workspace = win_string[14..-1].split(/\s+#{ @settings.hostname }\s+/, 2)
      @name = after_id_and_workspace[0]
      @title = after_id_and_workspace[1]
    end
  end

  def dmenu_item
    unless @dmenu_item
      str = "#{@id} #{@name} #{@title}"
      @dmenu_item = Dmenu::Item.new str, self
    end
    @dmenu_item
  end

  def get_name
    get_name_and_title cmd('wmctrl -lx | grep ' + @id) if @name == ''
    @name
  end

  def get_name_length
    @name.length
  end

  def set_name_length(name_length)
    @name += ' ' * (name_length - @name.length)
  end

  def wmctrl(wm_cmd = '', summon = false)
    cmd "wmctrl -i#{summon ? 'R' : 'r'} #{@id} #{wm_cmd}"
    puts "wmctrl -i#{summon ? 'R' : 'r'} #{@id} #{wm_cmd}"
    self # return self so that commands can be chained
  end

  def move(how_to_move = {})
    how_to_move = @default_movement.merge! how_to_move
    cmd = "-e 0,#{how_to_move[:x].to_i},#{how_to_move[:y].to_i},#{how_to_move[:width].to_i},#{how_to_move[:height].to_i}"
    unshade
    unmaximize
    wmctrl cmd
  end

  def shade
    wmctrl '-b add,shaded'
  end

  def unshade
    wmctrl '-b remove,shaded'
  end

  def summon
    wmctrl '', true
  end

  def switch_to
    cmd "wmctrl -ia #{@id}"
    self
  end

  def maximize
    wmctrl '-b add,maximized_vert,maximized_horz'
  end

  def unmaximize
    wmctrl '-b remove,maximized_vert,maximized_horz'
  end

  def maximize_horiz
    wmctrl '-b add,maximized_horz'
  end

  def maximize_vert
    wmctrl '-b add,maximized_vert'
  end
end
