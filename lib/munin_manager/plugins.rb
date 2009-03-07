module MuninManager
  module Plugins
    extend self
    extend Enumerable
    
    def each(&block)
      registered_plugins.each(&block)
    end    
    
    def registered_plugins
      @registered_plugins ||= constants.map {|c| const_get(c) }
    end
    
    def [](*names)
      if names.length == 1
        return detect {|plugin| plugin.plugin_name == names.first}
      end
      
      names.map {|name| self[name]}
    end
  end
end
