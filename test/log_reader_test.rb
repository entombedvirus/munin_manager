require File.dirname(__FILE__) + "/test_helper"

class LogReaderTest < Test::Unit::TestCase
  def setup
    @reader = RailsLogReader.new("#{HERE}/logs/rails.log")
    
    File.open(@reader.file_name, 'w') do |f|
      10.times {f.puts("Completed in")}
      20.times {f.puts("Some other stuff")}
    end
  end
  
  def teardown
    File.unlink(@reader.state_file)
  end
  
  def test_remembers_last_position_in_log
    @reader.collect!
    assert_equal 10, @reader.num_requests
    
    File.open(@reader.file_name, 'a+') do |f|
      10.times {f.puts("Completed in")}
    end
    
    @new_reader = RailsLogReader.new(@reader.file_name)
    @new_reader.collect!
    
    assert_equal 10, @new_reader.num_requests
    assert_equal 40, File.new(@new_reader.file_name).readlines.length
  end
end