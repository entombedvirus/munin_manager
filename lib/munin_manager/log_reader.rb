module MuninManager
  # A LogReader that continues from where it left off.
  # Ex:
  # class RailsLogReader < LogReader
  #     def scan(log_file)
  #       @req_counter = 0
  #       loop do
  #         line = log_file.readline
  #         @req_counter += 1 if line =~ /Completed in/
  #       end
  #     end
  #     
  #     def process!
  #       # Do nothing
  #     end
  #     
  #     def print_data
  #       "num_requests.value #{@req_counter}"
  #     end
  #   end
  #   
  #   Usage:
  #   
  #   reader = RailsLogReader.new("log/development.log")
  #   reader.collect!
  #   reader.print_data
  #   
  class LogReader
    attr_accessor :file_name, :me, :state_dir, :state_file

    def initialize(file_name)
      @file_name = file_name
      @me = File.basename($0)
      @state_dir = ENV['MUNIN_PLUGSTATE'] || '/var/lib/munin/plugin-state'
    end

    def state_file
      @state_file ||= File.join(@state_dir, @me)
    end

    def collect!
      File.open(@file_name, "r") do |f|
        load_saved_state(f)
        
        begin
          scan(f)
        rescue EOFError
        end
        
        process!
        save_state(f)
      end
    end

    def load_saved_state(log_file)
      return unless File.exists?(state_file) && !(state = File.read(state_file)).nil?
      pos, last_file_size = Marshal.load(state)

      # Check for log rotation
      return if File.size(@file_name) < last_file_size

      log_file.pos = pos
    end

    def scan(log_file)
      # Only subclasses know how to process each type of logfile
      raise "Needs to be implemented by subclasses"
    end

    def process!
      raise "Needs to be implemented by subclasses"
    end
    
    def save_state(log_file)
      File.open(state_file, "w") do |f|
        f.write(Marshal.dump([log_file.pos, File.size(log_file)]))
        f.flush
      end
    end
  end
end