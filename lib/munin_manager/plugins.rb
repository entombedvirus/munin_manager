module MuninManager
  module Plugins
    extend self
    extend Enumerable
    
    def each(&block)
      registered_plugins.each(&block)
    end    
    
    def registered_plugins
      @registered_plugins ||= constants.
        map {|c| const_get(c) }.
        select {|const| const.is_a?(Class) && const < MuninManager::ActsAsMuninPlugin}
    end
    
    def [](*names)
      if names.length == 1
        return detect {|plugin_klass| plugin_klass.plugin_name == names.first}
      end
      
      names.map {|name| self[name]}
    end

    def search(name)
      str = name.to_s.split('.', 2).first
      detect {|plugin_klass| plugin_klass.plugin_name.starts_with?(str)}
    end
  end
end
