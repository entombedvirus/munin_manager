#! /usr/bin/env ruby
# Munin plugin for starling.
require 'rubygems'
require 'starling'
#Monkey patched so the namespaced queues are included in stats
require File.join(File.dirname(__FILE__), '..','starling', 'starling_stats')

module MuninManager
  class Plugins::StarlingOps
    include ActsAsMuninPlugin

    def initialize(host, port)
      @host = "#{host}:#{port}"
      @starling = Starling.new(@host)
      @category = 'starling'
    end

    def ops_stats
      defaults = {
      'min' => 0,
      'max' => 5000,
      'type' => 'DERIVE',
      'draw' => 'LINE2',
      }
      stats = {
      'cmd_get' => {:label => 'GETs'},
      'cmd_set' => {:label => 'SETs'},
      'get_hits' => {:label => 'Hits'},
      'get_misses' => {:label => 'Misses'}
      }
      
      stats.each_key do |k|
        stats[k] = defaults.merge(stats[k])
      end
      return stats
    end

    def config
      graph_config = <<-END.gsub(/  +/, '')
      graph_title Starling Operations
      graph_args --base 1000
      graph_vlabel ops/${graph_period}
      graph_category #{@category}
      graph_order cmd_set cmd_get get_hits get_misses
      END

      stat_config = []
      ops_stats.each do |stat,config|
        config.each do |var,value|
          stat_config << "#{stat}.#{var} #{value}\n"
        end
      end
      return graph_config + stat_config.sort.join
    end

    def values
      ret = ''
      ops_stats.each_key do |stat|
        ret << "#{stat}.value #{@starling.stats[@host][stat]}\n"
      end
      return ret
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