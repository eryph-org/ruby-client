#!/usr/bin/env ruby
# frozen_string_literal: true

# Publish script for Eryph Ruby gems
# This script publishes gems to RubyGems.org based on changeset information

require 'fileutils'
require 'json'

def load_gem_info(gemspec_file)
  spec_content = File.read(gemspec_file)
  
  # Extract name and version using regex (simple approach)
  name_match = spec_content.match(/s\.name\s*=\s*["']([^"']+)["']/)
  version_match = spec_content.match(/s\.version\s*=\s*([^#\n]+)/)
  
  unless name_match && version_match
    puts "❌ Could not parse gem name/version from #{gemspec_file}"
    exit 1
  end
  
  name = name_match[1]
  
  # Evaluate the version expression (e.g., Eryph::VERSION)
  version_expr = version_match[1].strip
  
  # Load the version by requiring the necessary files
  $LOAD_PATH.unshift(File.join(Dir.pwd, 'lib'))
  
  if version_expr.include?('ClientRuntime::VERSION')
    require 'eryph/clientruntime/version'
    version = Eryph::ClientRuntime::VERSION
  elsif version_expr.include?('Eryph::VERSION')
    require 'eryph/version'
    version = Eryph::VERSION
  else
    # Try to evaluate the expression
    begin
      version = eval(version_expr)
    rescue
      puts "❌ Could not determine version for #{gemspec_file}"
      exit 1
    end
  end
  
  {
    name: name,
    version: version,
    gemspec: gemspec_file,
    gem_file: "#{name}-#{version}.gem"
  }
end

def gem_published?(name, version)
  # Check if gem version is already published
  result = `gem list #{name} --remote --exact 2>/dev/null`
  result.include?("#{name} (") && result.include?(version)
end

def publish_gem(gem_info, dry_run: false)
  name = gem_info[:name]
  version = gem_info[:version]
  gem_file = gem_info[:gem_file]
  
  puts "📦 Publishing #{name} v#{version}..."
  
  # Check if gem file exists
  unless File.exist?(gem_file)
    puts "  ❌ Gem file #{gem_file} not found. Run 'pnpm build:gems' first."
    return false
  end
  
  # Check if already published
  if gem_published?(name, version)
    puts "  ⚠️  Version #{version} already published. Skipping."
    return true
  end
  
  # Publish the gem
  if dry_run
    puts "  🏃 DRY RUN: Would publish #{gem_file}"
    return true
  else
    puts "  🚀 Publishing #{gem_file} to RubyGems..."
    result = system("gem push #{gem_file}")
    if result
      puts "  ✅ Successfully published #{name} v#{version}"
      return true
    else
      puts "  ❌ Failed to publish #{name} v#{version}"
      return false
    end
  end
end

def main
  dry_run = ARGV.include?('--dry-run')
  
  puts "📡 Publishing Eryph Ruby gems to RubyGems.org"
  puts "=" * 50
  
  if dry_run
    puts "🏃 DRY RUN MODE - No gems will actually be published"
    puts ""
  end
  
  # Ensure we're in the right directory
  script_dir = File.dirname(__FILE__)
  project_root = File.expand_path('..', script_dir)
  Dir.chdir(project_root)
  
  # Ensure gems are built first
  puts "🔨 Ensuring gems are built with latest versions..."
  build_result = system("ruby scripts/build-gems.rb")
  unless build_result
    puts "❌ Failed to build gems"
    exit 1
  end
  puts ""
  
  # Load gem information
  gemspecs = ['eryph-clientruntime.gemspec', 'eryph-compute.gemspec']
  gems = gemspecs.map { |spec| load_gem_info(spec) }
  
  puts "Gems to publish:"
  gems.each do |gem_info|
    puts "  📦 #{gem_info[:name]} v#{gem_info[:version]}"
  end
  puts ""
  
  # Publish gems in dependency order (runtime first, then compute client)
  success = true
  gems.each do |gem_info|
    success &= publish_gem(gem_info, dry_run: dry_run)
  end
  
  if success
    puts ""
    puts "🎉 All gems published successfully!"
    puts ""
    puts "Next steps:"
    puts "  1. Create a git tag for the release: git tag v#{gems.first[:version]}"
    puts "  2. Push the tag: git push origin v#{gems.first[:version]}"
    puts "  3. Create a GitHub release from the tag"
  else
    puts ""
    puts "❌ Some gems failed to publish. Check the output above."
    exit 1
  end
end

if __FILE__ == $0
  main
end