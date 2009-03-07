require File.dirname(__FILE__) + "/test_helper"

class HAProxyResponseTimeTest < Test::Unit::TestCase
  include MuninManager::Plugins
  
  def setup
    @reader = HAProxy.new("#{HERE}/logs/haproxy.log")
    @reader.state_dir = "#{HERE}/tmp"
  end
  
  def teardown
    File.unlink(@reader.state_file)
  rescue
    # Do nothing
  end
  
  def test_parsing
    @reader.collect!

    expected_values = {
      :rails_action => "0.0005463880",
      :total => "0.5552000000",
      :client_connect => "0.0000000000",
      :waiting_in_queue => "0.0000000000",
      :server_connect => "0.0000000000",
      :server_response => "0.5547000000"
    }
    
    expected_values.each do |field, val|
      assert_equal(val, @reader.data[field], "Value mismatch in #{field}")
    end
  end
  
  def test_has_help_text
    assert !HAProxy.help_text.empty?
  end
end