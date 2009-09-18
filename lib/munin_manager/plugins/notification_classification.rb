require 'rubygems'
require 'active_support'

module MuninManager
  class Plugins::NotificationClassification
    include ActsAsMuninPlugin
    
    def config
      "graph_title #{ENV['app']} Notification Classification Creation
      graph_vlabel new classifications / hour
      notification_rate.label new classifications / hour
      notification_rate.type derive
      notification_rate.warning 10
      notification_rate.critical 100"
    end
    
    def self.run
      allowed_commands = ['config']
      if cmd = ARGV[0] and allowed_commands.include? cmd
        puts new.config
      else
        cmd = "mysql -u #{ENV['mysql_user']} --password=#{ENV['mysql_password']} -h #{ENV['host']} -e 'use #{ENV['database']}; select count(*) from notification_classifications where created_at >= \"#{1.hour.ago.to_s(:db)}\";' --skip-column-names --silent"
        puts "notification_rate.value %s" % `#{cmd}`
      end
    end
  end
end