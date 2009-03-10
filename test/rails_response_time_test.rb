require File.dirname(__FILE__) + "/test_helper"

class RailsResponseTimeTest < Test::Unit::TestCase
  include MuninManager::Plugins
  
  def setup
    @reader = RailsResponseTime.new("#{TEST_DIR}/logs/rails.log")
    @reader.state_dir = "#{TEST_DIR}/tmp"
  end
  
  def teardown
    File.unlink(@reader.state_file)
  rescue
    # Do nothing
  end
  
  def test_parsing
    @reader.collect!
    assert @reader.data.keys.length > 0

    @reader.data.each_pair do |k, v|
      assert v > 0, "Value mismatch for #{k}"
    end
  end

  def test_config_parses_log
    assert @reader.config.split("\n").select {|line| not line.starts_with?("graph_")}.length > 0
  end

  def test_config_does_not_save_state
    @reader.config
    assert !File.exists?(@reader.state_file)
  end
  
  def test_has_help_text
    assert !RailsResponseTime.help_text.empty?
  end
end
