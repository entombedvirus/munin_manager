HERE = File.dirname(__FILE__)
%w(lib ext bin test).each do |dir| 
  $LOAD_PATH.unshift "#{HERE}/../#{dir}"
end

%w(rubygems test/unit ruby-debug munin_manager).each do |f|
  require f
end

class RailsLogReader < MuninManager::LogReader
  def initialize(*params)
    super
    @state_dir = "#{HERE}/tmp"
    @state_file = File.join(@state_dir, @me)
  end
  
  def scan(log_file)
    @req_counter = 0
    loop do
      line = log_file.readline
      @req_counter += 1 if line =~ /Completed in/
    end
  end

  def process!
    # Do nothing
  end

  def num_requests
    @req_counter
  end
end
