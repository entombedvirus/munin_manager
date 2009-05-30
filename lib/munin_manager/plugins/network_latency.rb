module MuninManager
  class Plugins::NetworkLatency < LogReader
    include ActsAsMuninPlugin
    
    def self.run
      hostnames = (ENV['hostnames'] || 'localhost').split(",")
      count = (ENV["count"] || 1).to_i
      if ARGV[0] == "config"
        puts config(hostnames)
      else
        values = Hash.new {|h,k| h[k] = []}
        threads = []
        count.times do |i|
          threads << Thread.new do
            output = %x{/usr/sbin/fping -c 10 -p 100 -q #{hostnames.join(" ")}}
            Thread.current[:output] = output
          end
        end
        threads.each do |t|
          t.join
          t[:output].to_s.split("\n").each do |line|
            if line =~ /^([^\s]+)\s*:\s*xmt\/rcv\/%loss = [0-9]+\/[0-9]+\/[0-9]+%, min\/avg\/max = [0-9.]+\/([0-9.]+)\/[0-9.]+/
              values[$1] << $2.to_f
            end
          end
        end
        
        values.each do |host, results|
          avg = results.size > 0 ? results.inject(0){|a,b| a + b}.to_f / results.size : -1
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