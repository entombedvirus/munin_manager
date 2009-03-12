require 'fileutils'

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

      def help_text(options = {})
        # Any general info concerning the plugin. Should be overriden by included class
      end

      def install(options)
        install_as = options.install_name.split(":").last
        symlink = File.join(options.plugin_dir, install_as)
        runner = File.join(File.dirname(__FILE__), "..", "..", "bin", "runner")
        runner = File.expand_path(runner)

        if File.exists?(symlink)
          if options.force
            File.unlink(symlink)
          else
            STDERR.puts "'%s' already exists. Please specify --force option to overwrite" % symlink
            return
          end
        end

        STDOUT.puts "Installing '%s' at '%s'" % [plugin_name, symlink]
        FileUtils.ln_sf(runner, symlink)

        STDOUT.puts help_text(:symlink => install_as)

      rescue Errno::EACCES
        STDERR.puts "ERROR: Permission denied while attempting to install to '%s'" % symlink
      end

      # Default uninstaller. Override in included classes if the default is not sufficient
      def uninstall(options)
        install_as = options.install_name.split(":").last
        symlink = File.join(options.plugin_dir, install_as)

        unless File.exists?(symlink)
          STDERR.puts "'%s' does not seem to exist. Aborting..." % symlink
          return
        end

        unless File.symlink?(symlink) || options.force
          STDERR.puts "'%s' does not appear to be a symlink. Please specify --force option to remove" % symlink
          return
        end

        STDOUT.puts "Removing '%s'..." % symlink
        File.unlink(symlink)
      rescue Errno::EACCES
        STDERR.puts "ERROR: Permission denied while attempting to uninstall '%s'" % symlink
      end
    end

    module InstanceMethods
      def config
        raise "This is invoked by munin to get graph details. Needs implementation by included class"
      end
    end
  end
end
