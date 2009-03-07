module MuninManager
  class Plugins::HaproxyResponseTime < LogReader
    include ActsAsMuninPlugin

    def data
      @data ||= Hash.new {|h, k| h[k] = Array.new}
    end

    def scan(log_file)
      loop do
        line = log_file.readline
        chunks = line.split(/\s+/)

        timers = chunks[9].split("/") rescue []
        data[:client_connect] << timers[0].to_f
        data[:waiting_in_queue] << timers[1].to_f
        data[:server_connect] << timers[2].to_f
        data[:server_response] << timers[3].to_f
        data[:rails_action] << line.match(/\{([0-9.]+)\}/).captures[0].to_f rescue 0
        data[:total] << timers[4].to_f
      end
    end

    def process!
      data.each do |k, v|
        data[k] = data[k].inject(0) {|sum, i| sum + i} / data[k].length rescue 0
        data[k] = formatted(data[k] / 1000)
      end
    end
    
    def config
      <<-LABEL                     
graph_title HAProxy Response Breakdown
graph_vlabel time (secs)
graph_category Haproxy                
client_connect.label Client Connect
waiting_in_queue.label  Waiting In Queue
server_connect.label  Server Connect
server_response.label  Server Response
rails_action.label  Rails Controller Action
total.label Total Response Time
      LABEL
    end

    def values
      data.map {|k, v| "#{k}.value #{v}"}.join("\n")
    end

    def self.run
      log_file = ENV['log_file'] || "/var/log/haproxy.log"
      allowed_commands = ['config']

      haproxy = new(log_file)

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts haproxy.send(cmd.to_sym)
      else
        haproxy.collect!
        puts haproxy.values
      end
    end

    def self.help_text
      %Q{
#{plugin_name.capitalize} Munin Plugin
===========================

Please remember to add something like the lines below to /etc/munin/plugin-conf.d/munin-node
if the haproxy log file is not at /var/log/haproxy.log

[#{plugin_name}]
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
