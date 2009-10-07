module MuninManager
  class Plugins::HaproxyAppResponseTime < LogReader
    include ActsAsMuninPlugin

    EXTRACTORS = {
      :client_connect => lambda {|line| line.split(/\s+/)[9].split("/")[0].to_f},
      :waiting_in_queue => lambda {|line| line.split(/\s+/)[9].split("/")[1].to_f},
      :server_connect => lambda {|line| line.split(/\s+/)[9].split("/")[2].to_f},
      :server_response => lambda {|line| line.split(/\s+/)[9].split("/")[3].to_f},
      :rails_action => lambda {|line| (line.match(/\{([0-9.]+)\}/).captures[0].to_f * 1000) rescue 0},
      :total => lambda {|line| line.split(/\s+/)[9].split("/")[4].to_f},
    }
    
    def initialize(logfile, options)
      @measure = options[:measure].to_sym
      raise ArgumentError, 
        "I do not know how to measure `%s`" % options[:measure] unless EXTRACTORS.key?(@measure)
        
      super(logfile)
    end
    
    def data
      @data ||= Hash.new {|h, k| h[k] = Hash.new{|d,v| d[v] = Array.new}}
    end

    def scan(log_file)
      loop do
        line = log_file.readline
        chunks = line.split(/\s+/)
        server, port = chunks[8].split(":") rescue []
        server_name = server.split("/")[1] rescue nil
        next if server_name.nil?
        
        data[server_name][@measure] << EXTRACTORS[@measure].call(line)
      end
    end

    def process!
      data.each do |server, values|
        values.each do |k, v|
          values[k] = values[k].inject(0) {|sum, i| sum + i} / values[k].length rescue 0
          values[k] = formatted(values[k] / 1000)
        end
      end
    end
    
    def config
      log_file = ENV['log_file'] || "/var/log/haproxy.log"
      f = File.open(log_file)
      count = 0
      server_hash = {}
      while(!f.eof? && count < 100)
        count += 1
        line = f.readline
        chunks = line.split(/\s+/)
        server, port = chunks[8].split(":") rescue []
        server_name = server.split("/")[1] rescue nil
        server_hash[server_name] = '' unless server_name.nil?
      end
      
      default = Array(@measure)
            
      config_text = <<-LABEL                     
graph_title HAProxy App Server #{@measure}
graph_vlabel time (secs)
graph_category Haproxy
      LABEL
      server_hash.keys.sort.each do |server|
        config_text << default.map{|k| "#{server}_#{k}.label #{server}_#{k}"}.join("\n")
        config_text << "\n"
      end
      config_text
    end

    def values
      data.inject([]){|datas, (server, values)| (datas + values.map{|k,v| "#{server}_#{k}.value #{v}"})}.join("\n")
    end

    def self.run
      log_file = ENV['log_file'] || "/var/log/haproxy.log"
      allowed_commands = ['config']

      measure = ENV['measure']
      # Try to figure out what we're trying to measure from the symlink name
      measure ||= File.basename($0).split(".", 2).last
      measure = nil unless EXTRACTORS.key?(measure.to_sym)
      
      haproxy = new(log_file, :measure => measure || 'total')

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts haproxy.send(cmd.to_sym)
      else
        haproxy.collect!
        puts haproxy.values
      end
    end

    def self.help_text(options = {})
      %Q{
#{plugin_name.capitalize} Munin Plugin
===========================

Please remember to add something like the lines below to /etc/munin/plugin-conf.d/munin-node
if the haproxy log file is not at /var/log/haproxy.log

[#{options[:symlink]}]
env.log_file /var/log/custom/haproxy.log

Also, make sure that the '/var/lib/munin/plugin-state' is writable by munin.

$ sudo chmod 777 /var/lib/munin/plugin-state

}
    end
    
    private

    def formatted(num)
      "%.10f" % num
    end
  end
end
