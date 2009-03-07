module MuninManager
  module ActsAsMuninPlugin
    def self.included(klass)
      klass.send(:include, InstanceMethods)
      klass.extend(ClassMethods)
    end
    
    module ClassMethods
      def run
        raise "This is the entry point of the plugin when invoked by munin. Needs implementation by included class"
      end

      def plugin_name
        # Name of the plugin. Must not contain spaces or special chars
        
        # Default is underscorized version of the class name
        self.name.split('::').last.
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end

      def help_text
        # Any general info concerning the plugin. Should be overriden by included class
      end
    end

    module InstanceMethods
      def config
        raise "This is invoked by munin to get graph details. Needs implementation by included class"
      end
    end
  end
end
