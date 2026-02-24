# config-generator/generate.rb
require 'erb'
require 'fileutils'

class ConfigGenerator
  REQUIRED_VARS = %w[
    SAGITTARIUS_RAILS_HOST
    SAGITTARIUS_RAILS_PORT
    SAGITTARIUS_GRPC_HOST
    SAGITTARIUS_GRPC_PORT
    SCULPTOR_HOST
    SCULPTOR_PORT
    HOSTNAME
  ]
  TEMPLATES_DIR = '/config-generator/templates'
  OUTPUT_DIR = '/generated-configs'

  def initialize
    @env = ENV.to_h
    validate_env!
  end

  def generate_all
    puts "Generating configuration files..."

    template_files = Dir.glob(File.join(TEMPLATES_DIR, '**', '*.erb'))

    if template_files.empty?
      puts "WARNING: No template files found in #{TEMPLATES_DIR}"
      return
    end

    template_files.each do |template_path|
      generate_from_template(template_path)
    end

    puts "Configuration generation complete! Generated #{template_files.size} file(s)."
  end

  private

  def validate_env!
    missing = REQUIRED_VARS.reject { |var| @env[var] }

    if missing.any?
      abort "ERROR: Missing required environment variables: #{missing.join(', ')}"
    end
  end

  def generate_from_template(template_path)
    # Calculate relative path from templates directory
    relative_path = template_path.sub("#{TEMPLATES_DIR}/", '')

    # Remove .erb extension for output file
    output_filename = relative_path.sub(/\.erb$/, '')
    output_path = File.join(OUTPUT_DIR, output_filename)

    # Read and render template
    template = ERB.new(File.read(template_path), trim_mode: '-')
    result = template.result(binding)

    # Ensure output directory exists
    FileUtils.mkdir_p(File.dirname(output_path))

    # Write rendered config
    File.write(output_path, result)

    puts "Generated: #{output_path}"
  rescue StandardError => e
    puts "ERROR generating #{template_path}: #{e.message}"
    raise
  end

  # Dynamic method for accessing environment variables
  def method_missing(method_name, *args)
    var_name = method_name.to_s.upcase
    return @env[var_name] if @env.key?(var_name)

    super
  end

  def respond_to_missing?(method_name, include_private = false)
    @env.key?(method_name.to_s.upcase) || super
  end

  # Helper methods for templates
  def env(key, default = nil)
    @env.fetch(key, default)
  end

  def env?(key)
    @env[key] == 'true'
  end
end

# Run the generator
ConfigGenerator.new.generate_all