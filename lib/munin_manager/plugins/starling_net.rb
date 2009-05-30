#! /usr/bin/env ruby
# Munin plugin for starling.
require 'rubygems'
require 'starling'
#Monkey patched so the namespaced queues are included in stats
require File.join(File.dirname(__FILE__), '..','starling', 'starling_stats')

module MuninManager
  class Plugins::StarlingNet
    include ActsAsMuninPlugin

    def initialize(host, port)
      @host = "#{host}:#{port}"
      @starling = Starling.new(@host)
      @category = 'starling'
    end

    def net_stats
      stats = {
        :bytes_read => {
          :label => 'read',
          :type => 'COUNTER',
          :graph => 'no',
          :cdef => 'bytes_read,8,*'
        },
        :bytes_written => {
          :label => 'bps',
          :type => 'COUNTER',
          :cdef => 'bytes_written,8,*',
          :negative => 'bytes_read'
        }
      }
      return stats
    end

    def config
      graph_config = <<-END.gsub(/  +/, '')
        graph_title Starling traffic
        graph_args --base 1000
        graph_vlabel bits read(-) / written(+) per second
        graph_category #{@category}
        graph_order bytes_read bytes_written
      END

      stat_config = ''
      net_stats.each do |stat,config|
        config.each do |var,value|
          stat_config << "#{stat}.#{var} #{value}\n"
        end
      end
      return graph_config + stat_config
    end

    def values
      ret = "bytes_read.value #{@starling.stats[@host]['bytes_read']}\n"
      ret << "bytes_written.value #{@starling.stats[@host]['bytes_written']}\n"
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
