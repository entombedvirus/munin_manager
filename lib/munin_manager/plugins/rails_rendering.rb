module MuninManager
  class Plugins::RailsRendering < LogReader
    include ActsAsMuninPlugin

    def data
      @data ||= Hash.new {|h, k| h[k] = Array.new}
    end

    def scan(log_file)
      loop do
        line = log_file.readline
        next unless line.match(/^Completed in/)

        chunks = line.split(/\s/)
        data[:total] << chunks[2].to_f
        data[:rendering] << chunks[7].to_f
        data[:memcache] << chunks[11].to_f
        data[:db] << chunks[14].to_f
      end
    end

    def process!
      data.each_pair do |component, response_times|
        data[component] = response_times.inject(0) {|sum, i| sum + i} / data[component].length rescue 0
      end
    end

    def config
      <<-LABEL
graph_title Rails Response Breakdown
graph_vlabel response time          
graph_category Rails                
total.label total                   
rendering.label rendering           
db.label db                         
memcache.label memcache             
LABEL
    end

    def values
      data.map {|k, v| "#{format_for_munin(k)}.value #{"%.10f" % v}"}.join("\n")
    end

    def self.run
      log_file = ENV['log_file'] || "/var/log/rails.log"
      allowed_commands = ['config']

      rails = new(log_file)

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts rails.send(cmd.to_sym)
      else
        rails.collect!
        puts rails.values
      end
    end

    def self.help_text(options = {})
      %Q{
#{plugin_name.capitalize} Munin Plugin
===========================

Please remember to add something like the lines below to /etc/munin/plugin-conf.d/munin-node
if the rails log file is not at /var/log/rails.log

[#{options[:symlink] || plugin_name}]
env.log_file /var/log/custom/rails.log

Also, make sure that the '/var/lib/munin/plugin-state' is writable by munin.

$ sudo chmod 777 /var/lib/munin/plugin-state

}
    end

    private

    def format_for_munin(str)
      str.to_s.gsub(/[^A-Za-z0-9_]/, "_")
    end
  end
end
