# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{munin_manager}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rohith Ravi"]
  s.date = %q{2009-04-13}
  s.description = %q{Tool to maintain and install munin plugins written in Ruby}
  s.email = %q{entombedvirus@gmail.com}
  s.executables = ["munin_manager", "runner"]
  s.extra_rdoc_files = ["bin/munin_manager", "bin/runner", "ext/string.rb", "lib/munin_manager/acts_as_munin_plugin.rb", "lib/munin_manager/log_reader.rb", "lib/munin_manager/plugins/haproxy_response_time.rb", "lib/munin_manager/plugins/network_latency.rb", "lib/munin_manager/plugins/packet_loss.rb", "lib/munin_manager/plugins/rails_response_time.rb", "lib/munin_manager/plugins/scribe_net.rb", "lib/munin_manager/plugins.rb", "lib/munin_manager.rb", "README.markdown"]
  s.files = ["bin/munin_manager", "bin/runner", "ext/string.rb", "lib/munin_manager/acts_as_munin_plugin.rb", "lib/munin_manager/log_reader.rb", "lib/munin_manager/plugins/haproxy_response_time.rb", "lib/munin_manager/plugins/network_latency.rb", "lib/munin_manager/plugins/packet_loss.rb", "lib/munin_manager/plugins/rails_response_time.rb", "lib/munin_manager/plugins/scribe_net.rb", "lib/munin_manager/plugins.rb", "lib/munin_manager.rb", "Manifest", "munin_manager.gemspec", "Rakefile", "README.markdown", "test/haproxy_response_time_test.rb", "test/log_reader_test.rb", "test/rails_response_time_test.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Munin_manager", "--main", "README.markdown"]
  s.require_paths = ["lib", "ext"]
  s.rubyforge_project = %q{munin_manager}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Tool to maintain and install munin plugins written in Ruby}
  s.test_files = ["test/haproxy_response_time_test.rb", "test/log_reader_test.rb", "test/rails_response_time_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
