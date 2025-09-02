#!/usr/bin/env ruby
# frozen_string_literal: true

# Build script for Eryph Ruby gems
# This script builds both the clientruntime and compute client gems

require 'fileutils'

def build_gem(gemspec_file)
  puts "Building #{gemspec_file}..."

  # Ensure build directory exists
  build_dir = 'build/gems'
  FileUtils.mkdir_p(build_dir)

  # Clean up any existing gem files for this gemspec in build directory
  gem_name = File.basename(gemspec_file, '.gemspec')
  # Use exact match pattern to avoid removing gems with similar names
  Dir.glob("#{build_dir}/#{gem_name}-[0-9]*.gem").each do |old_gem|
    # Double-check the gem name matches exactly
    if File.basename(old_gem).start_with?("#{gem_name}-")
      puts "  Removing old gem: #{old_gem}"
      File.delete(old_gem)
    end
  end

  # Also clean up any gem files in project root (legacy cleanup)
  Dir.glob("#{gem_name}-*.gem").each do |old_gem|
    puts "  Removing legacy gem from root: #{old_gem}"
    File.delete(old_gem)
  end

  # Build the gem and move to build directory
  puts "  Running: gem build #{gemspec_file}"
  result = system("gem build #{gemspec_file}")
  if result
    # Move the built gem to build directory
    built_gem = Dir.glob("#{gem_name}-*.gem").first
    if built_gem
      target_path = File.join(build_dir, File.basename(built_gem))
      FileUtils.mv(built_gem, target_path)
      puts "  ✅ Successfully built #{gemspec_file} -> #{target_path}"
    else
      puts '  ❌ Built gem not found after build'
      exit 1
    end
  else
    puts "  ❌ Failed to build #{gemspec_file}"
    puts '  Check the output above for details'
    exit 1
  end
end

def sync_versions
  puts '🔄 Syncing versions from package.json files...'

  # Sync versions by running the Node.js scripts directly
  clientruntime_result = system('node packages/clientruntime/sync-version.js')
  compute_result = system('node packages/compute-client/sync-version.js')

  unless clientruntime_result && compute_result
    puts '  ❌ Failed to sync versions'
    exit 1
  end

  puts '  ✅ Versions synced successfully'
end

def main
  puts '🔨 Building Eryph Ruby gems...'
  puts '=' * 50

  # Ensure we're in the right directory
  script_dir = File.dirname(__FILE__)
  project_root = File.expand_path('..', script_dir)
  Dir.chdir(project_root)

  # Sync versions before building
  sync_versions

  puts ''

  # Build both gems
  build_gem('eryph-clientruntime.gemspec')
  build_gem('eryph-compute.gemspec')

  puts ''
  puts '🎉 All gems built successfully!'
  puts ''
  puts 'Built gems:'
  Dir.glob('build/gems/*.gem').each do |gem_file|
    puts "  📦 #{gem_file}"
  end
end

main if __FILE__ == $PROGRAM_NAME
