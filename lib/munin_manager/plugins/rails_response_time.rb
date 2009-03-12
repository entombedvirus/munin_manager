module MuninManager
  class Plugins::RailsResponseTime < LogReader
    include ActsAsMuninPlugin
    attr_accessor :search_pattern

    def initialize(log_file, options = {})
      super(log_file)
      @search_pattern = options[:search_pattern] || /.*/
      @search_pattern = Regexp.new(@search_pattern) if @search_pattern.is_a?(String)
    end

    def data
      @data ||= Hash.new {|h, k| h[k] = Array.new}
    end

    def scan(log_file)
      current_action = nil
      loop do
        line = log_file.readline

        if line.starts_with?("Processing ")
          cols = line.split(/\s+/)
          current_action = cols[1] if self.search_pattern.match(cols[1])

        elsif line.starts_with?("Completed in ") && !current_action.nil?
          cols = line.split(/\s+/)
          data[current_action] << cols[2].to_f
          current_action = nil
        end

      end
    end

    def process!
      data.each_pair do |action_name, response_times|
        data[action_name] = response_times.inject(0) {|sum, i| sum + i} / data[action_name].length rescue 0
      end
    end

    def config
      configs = {
        "graph_title" => "Rails Response Times (by Controller->Action)",
        "graph_vlabel" => "time (secs)",
        "graph_category" => "Performance",
        "graph_args" => "--upper-limit 1.0 --lower-limit 0.100 --rigid"
      }
      self.collect!(:save_state => false)
      self.data.each do |action_name, respose_time|
        configs["#{format_for_munin(action_name)}.label"] = action_name.sub("#", "->")
        configs["#{format_for_munin(action_name)}.draw"] = "LINE2"
      end

      configs["graph_order"] = self.data.to_a.
        sort {|lhs, rhs| rhs[1] <=> lhs[1]}.
        collect {|tuple| format_for_munin(tuple[0])}

      configs.map {|key_value_pair| key_value_pair.join(" ")}.join("\n")
    end

    def values
      data.map {|k, v| "#{format_for_munin(k)}.value #{"%.10f" % v}"}.join("\n")
    end

    def self.run
      log_file = ENV['log_file'] || "/var/log/rails.log"
      allowed_commands = ['config']

      rails = new(log_file, :search_pattern => ENV['search_pattern'])

      if cmd = ARGV[0] and allowed_commands.include? cmd then
        puts rails.send(cmd.to_sym)
      else
        rails.collect!
        puts rails.values
      end
    end

    def self.help_text(options = {})
      %Q{
#{plugin_name.capitalize} Munin Plugin
===========================

Please remember to add something like the lines below to /etc/munin/plugin-conf.d/munin-node
if the rails log file is not at /var/log/rails.log

[#{options[:symlink] || plugin_name}]
env.log_file /var/log/custom/rails.log
env.search_pattern UsersController.*

Also, make sure that the '/var/lib/munin/plugin-state' is writable by munin.

$ sudo chmod 777 /var/lib/munin/plugin-state

}
    end

    private

    def format_for_munin(str)
      str.to_s.gsub(/[^A-Za-z0-9_]/, "_")
    end
  end
end
