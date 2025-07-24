require "bundler/gem_tasks"

# Define gem tasks for both gems
Bundler::GemHelper.install_tasks(name: 'eryph-clientruntime')
Bundler::GemHelper.install_tasks(name: 'eryph-compute-client')

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  
  # Add specific spec tasks if needed
  RSpec::Core::RakeTask.new('spec:clientruntime') do |t|
    t.pattern = 'spec/eryph/clientruntime/**/*_spec.rb'
  end
  
  RSpec::Core::RakeTask.new('spec:compute') do |t|
    t.pattern = 'spec/eryph/compute/**/*_spec.rb'
  end
  
  task default: :spec
rescue LoadError
  # no rspec available
  puts "RSpec not available. Install with: bundle install"
end

desc "Build both gems"
task :build_all do
  system("ruby scripts/build-gems.rb")
end

desc "Show changeset status"
task :changeset_status do
  system("ruby scripts/changeset.rb status")
end
