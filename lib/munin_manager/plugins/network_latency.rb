module MuninManager
  class Plugins::NetworkLatency < LogReader
    include ActsAsMuninPlugin
    
    def self.run
      hostnames = (ENV['hostnames'] || 'localhost').split(",")
      count = (ENV["count"] || 1).to_i
      if ARGV[0] == "config"
        puts config(hostnames)
      else
        hostnames.each do |hostname|
          values = []
          count.times do |i|
            value = %x{(ping -c 10 #{hostname} 2> /dev/null  || echo '0/0/0/0/-1/0') | tail -1 | cut -d/ -f  5}.to_i
            values << value if value >= 0
          end
          avg = values.size > 0 ? values.inject(0){|a,b| a + b}.to_f / values.size : -1
          puts "#{sanitize(hostname)}.value #{avg}"
        end
      end
    end
    
    def self.sanitize(hostname)
      hostname.to_s.gsub(/[^\w]/, '_')
    end
    
    def self.config(hostnames)
      configs = {
        "graph_title" => "Network Latency",
        "graph_vlabel" => "time (ms)",
        "graph_category" => "Network",
        "graph_order" => ""
      }
      hostnames.each do |hostname|
        configs["#{sanitize(hostname)}.label"] = hostname
        configs["graph_order"] += "#{sanitize(hostname)} "
      end
      configs.map {|key_value_pair| key_value_pair.join(" ")}.join("\n")
    end
  end
end