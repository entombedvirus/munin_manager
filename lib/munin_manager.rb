HERE = File.join(File.dirname(__FILE__), "munin_manager")

%w(log_reader plugins).each do |f|
  require File.join(HERE, f)
end

Dir[File.join(HERE, "plugins", "*")].each do |file|
  require file
end
