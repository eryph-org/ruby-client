#!/usr/bin/env ruby
# frozen_string_literal: true

# Build script for Eryph Ruby gems
# This script builds both the clientruntime and compute client gems

require 'fileutils'

def build_gem(gemspec_file)
  puts "Building #{gemspec_file}..."
  
  # Clean up any existing gem files for this gemspec
  gem_name = File.basename(gemspec_file, '.gemspec')
  Dir.glob("#{gem_name}-*.gem").each do |old_gem|
    puts "  Removing old gem: #{old_gem}"
    File.delete(old_gem)
  end
  
  # Build the gem
  result = system("gem build #{gemspec_file}")
  if result
    puts "  ✅ Successfully built #{gemspec_file}"
  else
    puts "  ❌ Failed to build #{gemspec_file}"
    exit 1
  end
end

def sync_versions
  puts "🔄 Syncing versions from package.json files..."
  
  # Sync versions using the npm scripts
  result = system("pnpm sync:versions")
  unless result
    puts "  ❌ Failed to sync versions"
    exit 1
  end
  
  puts "  ✅ Versions synced successfully"
end

def main
  puts "🔨 Building Eryph Ruby gems..."
  puts "=" * 50
  
  # Ensure we're in the right directory
  script_dir = File.dirname(__FILE__)
  project_root = File.expand_path('..', script_dir)
  Dir.chdir(project_root)
  
  # Sync versions before building
  sync_versions
  
  puts ""
  
  # Build both gems
  build_gem('eryph-clientruntime.gemspec')
  build_gem('eryph-compute-client.gemspec')
  
  puts ""
  puts "🎉 All gems built successfully!"
  puts ""
  puts "Built gems:"
  Dir.glob("*.gem").sort.each do |gem_file|
    puts "  📦 #{gem_file}"
  end
end

if __FILE__ == $0
  main
end