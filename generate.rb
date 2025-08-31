#!/usr/bin/env ruby
# OpenAPI Code Generator for Eryph Ruby Client

require 'fileutils'
require 'json'

class EryphClientGenerator
  SPEC_URL = 'https://raw.githubusercontent.com/eryph-org/eryph-api-spec/main/specification/compute/v1/swagger.json'
  OUTPUT_DIR = 'lib/eryph/compute/generated'
  PACKAGE_NAME = 'compute_client'
  MODULE_NAME = 'ComputeClient'

  def initialize
    @base_dir = File.expand_path('..', __FILE__)
    @output_path = File.join(@base_dir, OUTPUT_DIR)
  end

  def generate
    puts "🔧 Generating Eryph Ruby Compute Client"
    puts "Spec URL: #{SPEC_URL}"
    puts "Output Directory: #{OUTPUT_DIR}"
    
    setup_directories
    download_spec
    fix_global_security
    check_generator
    generate_client
    fix_generated_authentication
    create_entry_point
    cleanup
    
    puts "✅ Code generation completed successfully!"
    puts ""
    puts "🎯 Next steps:"
    puts "1. Review generated code in: #{OUTPUT_DIR}"
    puts "2. Run tests: bundle exec rspec"
    puts "3. Build gems: gem build *.gemspec"
  end

  private

  def setup_directories
    puts "📁 Creating directory structure..."
    FileUtils.rm_rf(@output_path) if File.exist?(@output_path)
    FileUtils.mkdir_p(@output_path)
    puts "  Created: #{@output_path}"
  end

  def download_spec
    puts "📥 Downloading OpenAPI specification..."
    system("curl -s -o swagger.json #{SPEC_URL}")
    unless File.exist?('swagger.json')
      raise "Failed to download OpenAPI specification from #{SPEC_URL}"
    end
    puts "  Downloaded to: swagger.json"
  end

  def fix_global_security
    puts "🔧 Adding global OAuth2 security to all endpoints..."
    
    # Read and parse the swagger.json file
    spec_content = File.read('swagger.json')
    spec = JSON.parse(spec_content)
    
    # Define the global security configuration
    global_security = [
      {
        "oauth2" => ["compute:read"]
      }
    ]
    
    # Count endpoints that need fixing
    endpoints_fixed = 0
    
    # Add security to all endpoints except version
    spec['paths'].each do |path, path_obj|
      path_obj.each do |method, method_obj|
        next unless method_obj.is_a?(Hash)
        
        # Skip version endpoint - it should not require authentication
        if path == '/v1/version'
          # Explicitly set no security for version endpoint
          method_obj['security'] = []
          puts "  ⚪ Version endpoint set to no authentication: #{method.upcase} #{path}"
          next
        end
        
        # Add OAuth2 security if not already present
        unless method_obj['security']
          method_obj['security'] = global_security
          endpoints_fixed += 1
          puts "  ✅ Added OAuth2 security: #{method.upcase} #{path}"
        end
      end
    end
    
    # Write the fixed spec back to the file
    File.write('swagger.json', JSON.pretty_generate(spec))
    puts "  💾 Updated swagger.json with #{endpoints_fixed} endpoints secured"
  end
  
  def fix_generated_authentication
    puts "🔧 Fixing authentication in generated API files..."
    
    api_files = Dir.glob(File.join(@output_path, 'lib', PACKAGE_NAME, 'api', '*.rb'))
    files_fixed = 0
    methods_fixed = 0
    
    api_files.each do |file_path|
      content = File.read(file_path)
      original_content = content.dup
      
      # Skip version_api.rb as it should not require authentication
      if File.basename(file_path) == 'version_api.rb'
        # Ensure version API explicitly has no auth
        content.gsub!(/auth_names = opts\[:debug_auth_names\] \|\| \['oauth2'\]/, 
                     "auth_names = opts[:debug_auth_names] || []")
        puts "  ⚪ Ensured no authentication for version API"
      else
        # Fix all other API files to use oauth2 authentication
        methods_in_file = content.scan(/auth_names = opts\[:debug_auth_names\] \|\| \[\]/).size
        if methods_in_file > 0
          content.gsub!(/auth_names = opts\[:debug_auth_names\] \|\| \[\]/, 
                       "auth_names = opts[:debug_auth_names] || ['oauth2']")
          methods_fixed += methods_in_file
          puts "  ✅ Fixed #{methods_in_file} methods in #{File.basename(file_path)}"
        end
      end
      
      # Write back if changed
      if content != original_content
        File.write(file_path, content)
        files_fixed += 1
      end
    end
    
    puts "  💾 Fixed authentication in #{files_fixed} API files (#{methods_fixed} methods total)"
  end

  def check_generator
    puts "🔍 Checking OpenAPI Generator CLI..."
    # Just try to run the generator - if it fails, we'll catch it later
    puts "  Generator check skipped - will verify during generation"
  end

  def generate_client
    puts "⚙️ Generating Ruby client..."
    
    cmd = [
      'npx', '@openapitools/openapi-generator-cli', 'generate',
      '-i', 'swagger.json',
      '-g', 'ruby',
      '--library', 'faraday',
      '-o', "\"#{@output_path}\"",
      '--package-name', PACKAGE_NAME,
      '--additional-properties', "moduleName=#{MODULE_NAME}"
    ].join(' ')
    
    puts "  Running: #{cmd}"
    result = system(cmd)
    
    unless result
      raise "OpenAPI Generator failed"
    end
    
    puts "  Generation completed successfully"
  end

  def create_entry_point
    puts "📝 Creating entry point file..."
    
    # Get all model and API files for the entry point
    models = collect_models
    apis = collect_apis
    
    entry_content = generate_entry_content(models, apis)
    
    entry_file = File.join(@base_dir, 'lib/eryph/compute/generated.rb')
    File.write(entry_file, entry_content)
    puts "  Created entry point: #{entry_file}"
  end

  def collect_models
    model_dir = File.join(@output_path, 'lib', PACKAGE_NAME, 'models')
    return [] unless Dir.exist?(model_dir)
    
    Dir.entries(model_dir)
       .select { |f| f.end_with?('.rb') }
       .map { |f| File.basename(f, '.rb') }
       .sort
  end

  def collect_apis
    api_dir = File.join(@output_path, 'lib', PACKAGE_NAME, 'api')
    return [] unless Dir.exist?(api_dir)
    
    Dir.entries(api_dir)
       .select { |f| f.end_with?('.rb') }
       .map { |f| File.basename(f, '.rb') }
       .sort
  end

  def generate_entry_content(models, apis)
    <<~RUBY
      # Generated by OpenAPI Generator: https://openapi-generator.tech
      # Do not edit this file manually - it will be overwritten during regeneration

      # Add the generated lib directory to the load path
      # Try multiple path resolution strategies for different contexts (development vs gem)
      generated_lib_paths = [
        File.expand_path('generated/lib', __dir__),  # Development path
        File.expand_path('generated/lib', File.dirname(__FILE__)),  # From current file directory
        File.expand_path('../compute/generated/lib', __dir__),  # Alternative relative path  
        File.expand_path('../../../../compute/generated/lib', __FILE__)  # From gem context
      ]

      # Debug: print attempted paths in development mode
      if ENV['ERYPH_DEBUG'] || $DEBUG
        puts "DEBUG: Attempting to find generated client in:"
        generated_lib_paths.each_with_index do |path, i|
          exists = File.exist?(path)
          puts "  \#{i+1}. \#{path} (exists: \#{exists})"
        end
      end

      generated_lib_path = generated_lib_paths.find { |path| File.exist?(path) }

      if generated_lib_path
        $LOAD_PATH.unshift(generated_lib_path) unless $LOAD_PATH.include?(generated_lib_path)
        
        begin
          require '#{PACKAGE_NAME}'
        rescue LoadError => e
          # More detailed error in debug mode
          error_msg = "Failed to load #{PACKAGE_NAME} from \#{generated_lib_path}: \#{e.message}"
          if ENV['ERYPH_DEBUG'] || $DEBUG
            error_msg += "\\nLoad path: \#{$LOAD_PATH.join(':')}"
            error_msg += "\\nFiles in \#{generated_lib_path}: \#{Dir.entries(generated_lib_path).join(', ')}" if File.exist?(generated_lib_path)
          end
          raise LoadError, "\#{error_msg}. Please run generate.rb to regenerate the client."
        end
      else
        raise LoadError, "Generated compute client directory not found in any of: \#{generated_lib_paths.join(', ')}. Please run generate.rb to regenerate the client."
      end

      module Eryph
        # Create ComputeClient namespace that mirrors the generated ComputeClient module
        module ComputeClient
          # Re-export all core classes
          ApiClient = ::#{MODULE_NAME}::ApiClient
          Configuration = ::#{MODULE_NAME}::Configuration
          ApiError = ::#{MODULE_NAME}::ApiError
          
          # Re-export all API endpoint classes
      #{generate_api_exports(apis)}
          
          # Re-export all model classes  
      #{generate_model_exports(models)}
        end
        
        # Keep the old Generated namespace for backward compatibility
        module Generated
          # Alias the main classes for backward compatibility
          NewCatletRequest = ::#{MODULE_NAME}::NewCatletRequest
          StopCatletRequestBody = ::#{MODULE_NAME}::StopCatletRequestBody
          CatletStopMode = ::#{MODULE_NAME}::CatletStopMode
          ApiClient = ::#{MODULE_NAME}::ApiClient
          Configuration = ::#{MODULE_NAME}::Configuration
        end
        
        module Compute
          module Generated
            # Re-export the generated client classes for easier access
            Client = ::#{MODULE_NAME}
          end
        end
      end
    RUBY
  end

  def generate_api_exports(apis)
    apis.map do |api|
      class_name = api.split('_').map(&:capitalize).join('')
      "    #{class_name} = ::#{MODULE_NAME}::#{class_name}"
    end.join("\n")
  end

  def generate_model_exports(models)
    models.map do |model|
      class_name = model.split('_').map(&:capitalize).join('')
      "    #{class_name} = ::#{MODULE_NAME}::#{class_name}"
    end.join("\n")
  end

  def cleanup
    puts "🧹 Cleaning up temporary files..."
    File.delete('swagger.json') if File.exist?('swagger.json')
    puts "  Removed temporary spec file"
  end
end

# Run the generator
if __FILE__ == $0
  begin
    generator = EryphClientGenerator.new
    generator.generate
  rescue => e
    puts "❌ Generation failed: #{e.message}"
    puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
    exit 1
  end
end