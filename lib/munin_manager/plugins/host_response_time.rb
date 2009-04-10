#! /usr/bin/env ruby
# Munin plugin for starling.
require 'rubygems'
require 'ruby_scribe_client'

#Monkey patched so the namespaced queues are included in stats
module MuninManager
  class Plugins::HostResponseTime
    include ActsAsMuninPlugin
    
    def initialize(host, ping_times, count)
      @host = host
      @ping_times = ping_times
      @count = count
      @category = 'host'
    end
    
    def config

    end

    def values
      
      #   64 bytes from api.11.07.snc1.facebook.com (69.63.180.23): icmp_seq=1 ttl=245 time=89.1 ms
      #   64 bytes from api.11.07.snc1.facebook.com (69.63.180.23): icmp_seq=2 ttl=245 time=89.1 ms
      #   64 bytes from api.11.07.snc1.facebook.com (69.63.180.23): icmp_seq=3 ttl=245 time=88.6 ms
      # --- api.facebook.com ping statistics ---
      #       2 packets transmitted, 2 received, 0% packet loss, time 1000ms
      #       rtt min/avg/max/mdev = 88.667/88.789/88.911/0.122 ms
      #
      #
      pings = []
      @ping_times.times do |x|
        out = `ping -c #{@count} #{@host}`
        pings += out.grep(/icmp/).map{|x| x.match(/time=(\d*\.\d*)/)[1]}
      end
      pings.sort
      min = pings.first
      max = pings.last
      avg = pings.inject(0){|sum, x| sum + x}/pings.size
      dif_sum = pings.inject(0){|sum, x| sum + (avg-x)**2 }
      std_dev = Math.sqrt(dif_sum/pings.size)
      packets_lost = @num_times * @count - pings.size
      out = "packet_loss.value #{packets_lost* 100 /(@num_times * @count)}\n"
      out << "response_time_min.value #{min}\n"
      out << "response_time_max.value #{max}\n"
      out << "reponse_time_avg.value #{std_dev}\n"
    end
    
    def self.run
      host = ENV['PING_HOST'] || 'api.facebook.com';
      ping_times = ENV['PING_TIMES'] || 10;
      ping_count = ENV['PING_COUNT'] || 5;
      scribe = new(host, ping_times, ping_count)
      allowed_commands = ['config']

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts scribe.send(cmd.to_sym)
      else
        puts scribe.values
      end
    end
    
  private

    def format_for_munin(str)
      str.to_s.gsub(/[^A-Za-z0-9_]/, "_")
    end
    
  end
end
