module MuninManager
  module Plugins
    extend Enumerable
    
    def self.each(&block)
      registered_plugins.each(&block)
    end    
    
    def self.registered_plugins
      @registered_plugins ||= constants.map {|c| const_get(c) }
    end
    
    def self.[](*names)
      if names.length == 1
        return detect {|plugin| plugin.plugin_name == names.first}
      end
      
      names.map {|name| self[name]}
    end
  end
end

require "#{File.dirname(__FILE__)}/munin_manager/log_reader"

Dir["#{File.dirname(__FILE__)}/munin_manager/plugins/*"].each do |file|
  require file
end