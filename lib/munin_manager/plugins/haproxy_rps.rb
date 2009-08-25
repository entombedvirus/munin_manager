#! /usr/bin/env ruby
# Munin plugin for starling.
require 'open-uri'
require 'base64'

module MuninManager
  class Plugins::HaproxyRps
    include ActsAsMuninPlugin

    def initialize(url, user, pass)
      @url = url
      @user = user
      @pass = pass
      @data = Hash.new{|h,k|h[k] = 0}
      @category = 'Haproxy'
      parse_csv
    end

    def parse_csv
      base64 = Base64.encode64("#{@user}:#{@pass}")
      file = open(@url, {"Authorization" => "Basic #{base64}"})
      file.readline #skip first line
      file.each_line do |line|
        data_ary = line.split(",")
        host,port = data_ary[1].split(":")
        @data[host] += data_ary[7].to_i
      end
    end

    def ops_stats
      defaults = {
      'min' => 0,
      'type' => 'DERIVE',
      'draw' => 'LINE2',
      }

      stats = {
        
      }
      
      @data.each_key do |k|
        stats[k] = defaults.merge({:label => k})
      end
      return stats
    end

    def config
      graph_config = <<-END.gsub(/  +/, '')
      graph_title Haproxy RPS / App Server
      graph_args --base 1000
      graph_vlabel ops/${graph_period}
      graph_category #{@category}
      graph_order #{@data.keys.sort.join(" ")}
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
      @data.each do |key, stat|
        ret << "#{key}.value #{stat}\n"
      end
      return ret
    end

    def self.run
      url = ENV['URL'] || 'http://lb01.ffs.seriousops.com/haproxy?stats;csv'
      user = ENV['USERNAME'] || 'admin'
      pass = ENV['PASSWORD'] || 'pass'
      haproxy = new(url, user, pass)

      allowed_commands = ['config']

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts haproxy.send(cmd.to_sym)
      else
        puts haproxy.values
      end
    end

  private

    def format_for_munin(str)
      str.to_s.gsub(/[^A-Za-z0-9_]/, "_")
    end

  end
end