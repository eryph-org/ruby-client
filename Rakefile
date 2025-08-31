# Don't use bundler's default gem tasks since we have multiple gems
# require "bundler/gem_tasks"

# We'll handle gem building manually with our build script

begin
  require 'rspec/core/rake_task'

  # Default spec task (runs all tests except integration)
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '--tag ~integration'
    t.verbose = false
  end
  
  # Unit tests only
  RSpec::Core::RakeTask.new('spec:unit') do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
    t.verbose = false
  end
  
  # Integration tests only (requires INTEGRATION_TESTS=1)
  RSpec::Core::RakeTask.new('spec:integration') do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
    t.rspec_opts = '--tag integration'
    t.verbose = false
  end
  
  # Run all tests including integration
  RSpec::Core::RakeTask.new('spec:all') do |t|
    ENV['INTEGRATION_TESTS'] = '1'
    t.verbose = false
  end
  
  # Component-specific tests
  RSpec::Core::RakeTask.new('spec:clientruntime') do |t|
    t.pattern = 'spec/unit/eryph/clientruntime/**/*_spec.rb'
    t.verbose = false
  end
  
  RSpec::Core::RakeTask.new('spec:compute') do |t|
    t.pattern = 'spec/unit/eryph/compute/**/*_spec.rb'
    t.verbose = false
  end
  
  # Coverage report
  RSpec::Core::RakeTask.new('spec:coverage') do |t|
    ENV['COVERAGE'] = '1'
    t.rspec_opts = '--tag ~integration'
    t.verbose = false
  end
  
  task default: :spec
rescue LoadError
  # no rspec available
  puts "RSpec not available. Install with: bundle install"
end

desc "Build both gems to build/gems directory"
task :build_all do
  system("ruby scripts/build-gems.rb")
end

desc "Clean build directory"
task :clean do
  require 'fileutils'
  puts "🧹 Cleaning build directory..."
  FileUtils.rm_rf('build')
  puts "  ✅ Build directory cleaned"
end

desc "Show changeset status"
task :changeset_status do
  system("ruby scripts/changeset.rb status")
end

desc "Build documentation"
namespace :docs do
  desc "Generate YARD documentation for Ruby extensions"
  task :yard do
    require 'fileutils'
    puts "📚 Generating YARD documentation..."
    
    # Ensure output directory exists
    FileUtils.mkdir_p('docs')
    
    # Generate YARD docs (uses .yardopts configuration)
    begin
      require 'yard'
      YARD::CLI::Yardoc.run
    rescue => e
      puts "❌ YARD documentation generation failed: #{e.message}"
      exit 1
    end
    
    puts "  ✅ YARD documentation generated to docs/ruby-api/"
  end
  
  desc "Copy OpenAPI documentation to docs/api/"
  task :copy_api do
    require 'fileutils'
    puts "📋 Copying OpenAPI documentation..."
    
    source_dir = 'lib/eryph/compute/generated/docs'
    target_dir = 'docs/api'
    
    unless Dir.exist?(source_dir)
      puts "⚠️  Warning: Generated docs not found at #{source_dir}"
      puts "   Run 'ruby generate.rb' first to generate the API client"
      return
    end
    
    # Clean and create target directory
    FileUtils.rm_rf(target_dir)
    FileUtils.mkdir_p(target_dir)
    
    # Copy all markdown files
    Dir.glob(File.join(source_dir, '*.md')).each do |file|
      FileUtils.cp(file, target_dir)
    end
    
    # Create API README.md
    File.write(File.join(target_dir, 'README.md'), <<~MARKDOWN)
      # Eryph Compute API Reference
      
      This directory contains the complete REST API reference documentation
      generated from the OpenAPI specification.
      
      ## API Endpoints
      
      - [CatletsApi](CatletsApi.md) - Manage virtual machines (catlets)
      - [OperationsApi](OperationsApi.md) - Track long-running operations
      - [ProjectsApi](ProjectsApi.md) - Manage projects
      - [VirtualDisksApi](VirtualDisksApi.md) - Manage virtual disks
      - [VirtualNetworksApi](VirtualNetworksApi.md) - Manage virtual networks
      - [GenesApi](GenesApi.md) - Manage genes (VM templates)
      - [VersionApi](VersionApi.md) - API version information
      
      ## Authentication
      
      All API endpoints require OAuth2 authentication with JWT assertions.
      See the [Authentication Guide](../guides/authentication.md) for setup instructions.
      
      ## High-Level Ruby API
      
      For easier usage, see the [Ruby Extensions](../ruby-api/) which provide
      convenient wrapper methods around these low-level API calls.
    MARKDOWN
    
    puts "  ✅ OpenAPI documentation copied to #{target_dir}/"
  end
  
  desc "Create documentation guides and examples"
  task :guides do
    require 'fileutils'
    puts "📖 Creating documentation guides..."
    
    # Create guides directory
    guides_dir = 'docs/guides'
    FileUtils.mkdir_p(guides_dir)
    
    # Create examples directory
    examples_dir = 'docs/examples'
    FileUtils.mkdir_p(examples_dir)
    
    # Create examples README
    File.write(File.join(examples_dir, 'README.md'), <<~MARKDOWN)
      # Examples
      
      Code examples demonstrating common usage patterns for the Eryph Ruby Client.
      
      ## Available Examples
      
      - [Basic Usage](basic-usage.md) - Getting started with the client
      - [Operation Tracking](operation-tracking.md) - Advanced operation monitoring
      - [Configuration Validation](config-validation.md) - Validating catlet configurations
      
      ## Running Examples
      
      Examples are available as Ruby files in the `examples/` directory:
      
      ```bash
      # Basic usage
      ruby examples/basic_usage.rb
      
      # Operation tracking
      ruby examples/operation_tracker_demo.rb
      
      # Configuration testing
      ruby examples/test_catlet_config_demo.rb
      ```
    MARKDOWN
    
    puts "  ✅ Guides and examples structure created"
  end
  
  desc "Create main documentation README"
  task :readme do
    require 'fileutils'
    puts "📄 Creating main documentation README..."
    
    FileUtils.mkdir_p('docs')
    
    File.write('docs/README.md', <<~MARKDOWN)
      # Eryph Ruby Client Libraries
      
      Official Ruby client libraries for Eryph APIs, providing clean, idiomatic Ruby interfaces with built-in OAuth2 authentication.
      
      ## 📦 Available Gems
      
      This is a monorepo containing multiple Eryph Ruby client libraries:
      
      - **`eryph-compute`** - Compute API client for managing catlets, projects, and resources
      - **`eryph-clientruntime`** - Shared authentication and configuration runtime
      - **`eryph-identity`** *(coming soon)* - Identity API client for user and role management
      
      ## Quick Start
      
      ```ruby
      require 'eryph'
      
      # Connect to Eryph with auto-discovered configuration
      client = Eryph.compute_client('zero')
      
      # List all catlets
      catlets = client.catlets.catlets_list
      puts "Found \#{catlets.length} catlets"
      
      # Validate a catlet configuration
      config = { name: 'test', parent: 'dbosoft/ubuntu-22.04/starter' }
      result = client.validate_catlet_config(config)
      puts "Configuration valid: \#{result.is_valid}"
      ```
      
      ## 📚 Documentation
      
      ### User Guides
      - [Getting Started](guides/getting-started.md) - Installation and basic setup
      - [Authentication](guides/authentication.md) - OAuth2 setup and configuration
      - [Configuration](guides/configuration.md) - Managing multiple environments
      - [Operation Tracking](guides/operation-tracking.md) - Monitoring long-running operations
      
      ### API Reference
      - [Ruby Extensions](ruby-api/) - High-level Ruby API with convenience methods
      - [REST API Reference](api/) - Complete OpenAPI-generated documentation
      
      ### Examples
      - [Code Examples](examples/) - Common usage patterns and recipes
      
      ## 🏗️ Architecture
      
      The Eryph Ruby Client uses a two-layer architecture:
      
      ```
      ┌─────────────────────────────────────┐
      │ High-Level Ruby API                 │  ← You use this
      │ (Eryph::Compute::Client)           │
      ├─────────────────────────────────────┤
      │ Generated OpenAPI Client            │  ← Generated from API spec
      │ (Low-level HTTP/JSON)              │
      └─────────────────────────────────────┘
      ```
      
      - **High-Level API**: Convenient Ruby methods with authentication, error handling, and typed results
      - **Generated Client**: Direct OpenAPI-generated bindings for complete API access
      
      ## 🔧 Key Features
      
      - ✅ **Automatic Authentication** - OAuth2 with JWT assertions
      - ✅ **Configuration Discovery** - Multi-store hierarchical configuration
      - ✅ **Cross-Platform** - Windows, Linux, macOS support
      - ✅ **Typed Results** - Structured result objects with Struct pattern
      - ✅ **Operation Tracking** - Real-time progress monitoring
      - ✅ **Error Handling** - Enhanced error messages with ProblemDetails
      - ✅ **Eryph-Zero Integration** - Auto-discovery of local development environments
      
      ## 📦 Installation
      
      Add to your Gemfile:
      
      ```ruby
      gem 'eryph-compute'
      ```
      
      Or install directly:
      
      ```bash
      gem install eryph-compute
      ```
      
      ## 🚀 Next Steps
      
      1. Check out the [Getting Started Guide](guides/getting-started.md)
      2. Browse the [Code Examples](examples/)
      3. Explore the [Ruby API Reference](ruby-api/)
    MARKDOWN
    
    puts "  ✅ Main documentation README created"
  end
  
  desc "Build complete documentation site"
  task :build => [:yard, :copy_api, :guides, :readme] do
    puts "🎉 Documentation build complete!"
    puts
    puts "📁 Generated documentation structure:"
    puts "   docs/README.md         - Main documentation"
    puts "   docs/ruby-api/         - Ruby API reference (YARD)"
    puts "   docs/api/              - REST API reference (OpenAPI)"
    puts "   docs/guides/           - User guides"
    puts "   docs/examples/         - Code examples"
    puts
    puts "🌐 To serve locally:"
    puts "   rake docs:serve"
  end
  
  desc "Serve documentation locally"
  task :serve do
    require 'webrick'
    
    port = ENV['PORT'] || 8080
    doc_root = File.expand_path('docs')
    
    unless Dir.exist?(doc_root)
      puts "❌ Documentation not found. Run 'rake docs:build' first."
      exit 1
    end
    
    puts "🌐 Serving documentation at http://localhost:#{port}"
    puts "   Document root: #{doc_root}"
    puts "   Press Ctrl+C to stop"
    
    server = WEBrick::HTTPServer.new(
      Port: port,
      DocumentRoot: doc_root,
      Logger: WEBrick::Log.new("/dev/null"),
      AccessLog: []
    )
    
    trap('INT') { server.shutdown }
    server.start
  end
  
  desc "Clean documentation"
  task :clean do
    require 'fileutils'
    puts "🧹 Cleaning documentation..."
    FileUtils.rm_rf('docs')
    puts "  ✅ Documentation cleaned"
  end
end
