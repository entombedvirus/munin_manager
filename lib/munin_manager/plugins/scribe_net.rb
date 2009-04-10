#! /usr/bin/env ruby
# Munin plugin for starling.
require 'rubygems'
require 'ruby_scribe_client'

#Monkey patched so the namespaced queues are included in stats
module MuninManager
  class Plugins::ScribeNet
    include ActsAsMuninPlugin
    
    def initialize(host, port)
      @scribe = FB303::Client.new(host, port)
      @category = 'scribe'
    end
    
    def config
      graph_config = <<-END.gsub(/  +/, '')
        graph_title Scribe Traffic
        graph_args --base 1000
        graph_vlabel bits per second
        graph_category #{@category}
      END


      
      graph_order = 'graph_order'
      counters.keys.each do |stat|
        stat_name = format_for_munin(stat)
        graph_order << " "+ stat_name
        stat_config = "#{stat_name}.label #{stat_name}"  
        net_stats.each do |var,value|
          value = "#{stat_name}," + value if var == :label
          stat_config << "#{stat_name}.#{var} #{value}\n"
        end
      end

      return graph_config + graph_order+"\n" + stat_config
    end

    def values
      ret = ""
      @scribe.getCounters.each do |k, v|
        ret << "#{format_for_munin(k)}.value #{v}\n"
      end
      ret
    end
    
    def self.run
      host = ENV['SCRIBE_HOST'] || 'localhost';
      port = ENV['SCRIBE_PORT'] || 1463;
      scribe = new(host, port)
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
    
    def counters
      @scribe.getCounters
    end
    
    def net_stats
      stats = {
          :type => 'COUNTER',
          :cdef => '8,*'
      }
      return stats
    end
    
  end
end
