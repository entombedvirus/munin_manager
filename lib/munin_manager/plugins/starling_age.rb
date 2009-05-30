#! /usr/bin/env ruby
# Munin plugin for starling.
require 'rubygems'
require 'starling'
#Monkey patched so the namespaced queues are included in stats
require File.join(File.dirname(__FILE__), '..','starling', 'starling_stats')

module MuninManager
  class Plugins::StarlingAge
    include ActsAsMuninPlugin

    def initialize(host, port)
      @host = "#{host}:#{port}"
      @starling = Starling.new(@host)
      @category = 'starling'
    end

    def age_stats
      defaults = {
        :type => 'GAUGE',
        :draw => 'AREA'
      }
      stats = @starling.available_queues.inject({}) do |stats, queue_name|
        queue,item = queue_name.split(/:/, 2)
        stats["queue_#{queue_name}_age"] = defaults.merge({
          :label => "#{queue}[#{item}] age"
        })
        stats
      end
    end


    def config
      graph_names = age_stats.keys.map{|n| n.to_s.tr(':', '_')}
      graph_config = <<-END.gsub(/  +/, '')
        graph_title Starling Queues Age
        graph_vlabel seconds in queue
        graph_category #{@category}
        graph_order #{graph_names.sort.join(' ')}
      END

      age_stats.inject(graph_config) do |stat_config, stat|
        stat[1].each do |var,value|
          graph_config << "#{format_for_munin(stat[0])}.#{var} #{value}\n"
        end
        graph_config
      end
    end

    def values
      age_stats.inject("") do |ret, stat|
        ret << "#{format_for_munin(stat[0])}.value #{@starling.stats[@host][stat[0]]/100.0}\n"
      end
    end

    def self.run
      host = ENV['HOST'] || '127.0.0.1';
      port = ENV['PORT'] || 22122;
      starling = new(host, port)


      allowed_commands = ['config']

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts starling.send(cmd.to_sym)
      else
        puts starling.values
      end
    end

  private

    def format_for_munin(str)
      str.to_s.gsub(/[^A-Za-z0-9_]/, "_")
    end
  end
end