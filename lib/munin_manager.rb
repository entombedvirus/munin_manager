munin_manager = File.join(File.dirname(__FILE__), "munin_manager")

%w(../../ext/string log_reader plugins acts_as_munin_plugin).each do |f|
  require File.join(munin_manager, f)
end

Dir[File.join(munin_manager, "plugins", "*")].each do |file|
  require file
end
