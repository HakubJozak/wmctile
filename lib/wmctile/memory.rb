require 'yaml'

class Wmctile::Memory < Wmctile::Class
  ##################################
  ## init ##########################
  ##################################
  def initialize
    @path = File.expand_path '~/.config/wmctile/wmctile-memory.yml'
    raw_memory = create_new_memory unless File.exist? @path
    raw_memory ||= File.read @path
    @memory = YAML.load(raw_memory)
  end

  def create_new_memory
    dir_path = @path[/(.*)\/wmctile-memory.yml/, 1]
    Dir.mkdir dir_path unless Dir.exist? dir_path
    out_file = File.new @path, 'w'
    # 20 workspaces should suffice
    20.times do |i|
      out_file.puts "#{i}:"
    end
    out_file.close
  end

  def write_memory
    out_file = File.new @path, 'w'
    out_file.puts @memory.to_yaml
    out_file.close
  end
  ##################################
  ## getters/setters ###############
  ##################################
  def get(workspace = 0, key = nil, key_sub = nil)
    a = @memory[workspace]
    if key.nil?
      return nil
    else
      a = a[key]
      if key_sub.nil?
        return a
      else
        return a[key_sub]
      end
    end
  rescue Exception => e
    return nil
  end

  def set(workspace = 0, key, hash)
    hash.merge! 'time' => Time.now.to_i
    @memory[workspace] = {} if @memory[workspace].nil?
    if @memory[workspace][key]
      @memory[workspace][key] = hash
    else
      @memory[workspace].merge! key => hash
    end
    write_memory
  end
end
