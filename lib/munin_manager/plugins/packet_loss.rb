module MuninManager
  class Plugins::PacketLoss < LogReader
    include ActsAsMuninPlugin
    
    def self.run
      hostnames = (ENV['hostnames'] || 'localhost').split(",")
      count = (ENV["count"] || 1).to_i
      if ARGV[0] == "config"
        puts config(hostnames)
      else
        hostnames.each do |hostname|
          values = []
          threads = []
          count.times do |i|
            threads << Thread.new do
              value = %x{(ping -c 10 #{hostname} 2> /dev/null || echo "1 packets transmitted, 1 received, 100% packet loss, time 0ms") | tail -2 | head -1 | cut -d' ' -f 6 | sed s/%//}.to_i
              Thread.current[:value] = value
            end
          end
          threads.each do |t|
            t.join
            values << t[:value]
          end
          avg = values.inject{|a,b| a + b}.to_f / values.size
          puts "#{sanitize(hostname)}.value #{avg}"
        end
      end
    end
    
    def self.sanitize(hostname)
      hostname.to_s.gsub(/[^\w]/, '_')
    end
    
    def self.config(hostnames)
      configs = {
        "graph_title" => "Packet Loss",
        "graph_vlabel" => "percentage",
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