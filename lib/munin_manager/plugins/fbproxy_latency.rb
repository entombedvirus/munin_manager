module MuninManager
  class Plugins::FbProxyLatency < LogReader
    include ActsAsMuninPlugin

    def data
      @data ||= Hash.new {|h, k| h[k] = Array.new}
    end

    def scan(log_file)
      loop do
        line = log_file.readline
        next unless line.match(/^Benchmark /)
        chunks = line.split(/-/).map{ |x| x.strip }
        data_type = chunks[1] =~ /Queue/ ? 'queue' : 'fb_api'
        next if chunks[2].nil?
        data[data_type] << chunks[2].match('\((.*)\)')[1].to_f
      end
    end

    def process!
      data.each_pair do |component, response_times|
        data[component] = response_times.inject(0.0) {|sum, i| sum + i} / data[component].length rescue 0
      end
    end

    def config
      <<-LABEL
graph_title Facebook Proxy Latency
graph_vlabel latency          
graph_category Facebook Proxy                
queue.label queue_latency                   
fb_api.label fb_api_latency
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
