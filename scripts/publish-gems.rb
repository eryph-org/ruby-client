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
    rescue StandardError
      puts "❌ Could not determine version for #{gemspec_file}"
      exit 1
    end
  end

  {
    name: name,
    version: version,
    gemspec: gemspec_file,
    gem_file: "#{name}-#{version}.gem",
  }
end

def gem_published?(name, version)
  # Check if gem version is already published
  puts "  🔍 Checking if #{name} v#{version} is already published..."
  result = `gem list #{name} --remote --exact 2>/dev/null`
  is_published = result.include?("#{name} (") && result.include?(version)
  
  if is_published
    puts "  ✅ Version #{version} found on RubyGems.org"
  else
    puts "  🆕 Version #{version} not found, ready to publish"
  end
  
  is_published
end

def publish_gem(gem_info, dry_run: false)
  name = gem_info[:name]
  version = gem_info[:version]
  gem_file = gem_info[:gem_file]

  puts "📦 Publishing #{name} v#{version}..."

  # Check if gem file exists (look in build directory first)
  build_gem_file = File.join('build', 'gems', gem_file)
  if File.exist?(build_gem_file)
    gem_file = build_gem_file
    puts "  📦 Using gem file: #{gem_file}"
  elsif File.exist?(gem_file)
    puts "  📦 Using gem file: #{gem_file}"
  else
    puts "  ❌ Gem file not found at #{gem_file} or #{build_gem_file}"
    puts "      Run 'pnpm build:gems' first."
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
    true
  else
    puts "  🚀 Publishing #{gem_file} to RubyGems..."
    result = system("gem push #{gem_file}")
    if result
      puts "  ✅ Successfully published #{name} v#{version}"
      true
    else
      puts "  ❌ Failed to publish #{name} v#{version}"
      false
    end
  end
end

def main
  dry_run = ARGV.include?('--dry-run')
  ci_mode = ENV['CI'] == 'true' || ENV['TF_BUILD'] == 'True' || !ENV['RUBYGEMS_API_TOKEN'].nil?

  puts '📡 Publishing Eryph Ruby gems to RubyGems.org'
  puts '=' * 50

  if dry_run
    puts '🏃 DRY RUN MODE - No gems will actually be published'
    puts ''
  end

  if ci_mode
    puts '🤖 CI MODE - Running in continuous integration environment'
    puts ''
  end

  # Ensure we're in the right directory
  script_dir = File.dirname(__FILE__)
  project_root = File.expand_path('..', script_dir)
  Dir.chdir(project_root)

  # Ensure gems are built first (skip in CI if they should already be built)
  if ci_mode && File.exist?('build/gems') && Dir.glob('build/gems/*.gem').any?
    puts '🔨 Using pre-built gems from CI artifacts...'
  else
    puts '🔨 Ensuring gems are built with latest versions...'
    build_result = system('ruby scripts/build-gems.rb')
    unless build_result
      puts '❌ Failed to build gems'
      exit 1
    end
  end
  puts ''

  # Load gem information
  gemspecs = ['eryph-clientruntime.gemspec', 'eryph-compute.gemspec']
  gems = gemspecs.map { |spec| load_gem_info(spec) }

  puts 'Gems to publish:'
  gems.each do |gem_info|
    puts "  📦 #{gem_info[:name]} v#{gem_info[:version]}"
  end
  puts ''

  # Publish gems in dependency order (runtime first, then compute client)
  success = true
  gems.each do |gem_info|
    success &= publish_gem(gem_info, dry_run: dry_run)
  end

  puts ''
  if success
    if dry_run
      puts '🎉 Dry run completed successfully!'
      puts ''
      puts 'All gems are ready to publish. To publish for real:'
      puts '  ruby scripts/publish-gems.rb'
    else
      puts '🎉 All gems published successfully!'
      puts ''
      if ci_mode
        puts 'CI will handle git tagging and repository updates.'
      else
        puts 'Next steps:'
        puts "  1. Create git tags for each gem version"
        puts "  2. Push tags to repository"
        puts "  3. Update changelog or create release notes"
      end
    end
  else
    puts '❌ Some gems failed to publish. Check the output above.'
    exit 1
  end
end

main if __FILE__ == $PROGRAM_NAME
