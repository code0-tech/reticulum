# config-generator/generate.rb
require 'erb'
require 'fileutils'

class ConfigGenerator
  TEMPLATES_DIR = '/config-generator/templates'
  OUTPUT_DIR = '/generated-configs'

  def initialize
    @env = ENV.to_h
    @missing_envs = []
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

    if @missing_envs.any?
      abort "ERROR: Missing required environment variables: #{@missing_envs.join(', ')}"
    end

    puts "Configuration generation complete! Generated #{template_files.size} file(s)."
  end

  private

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

  # Helper methods for templates
  def env(key, default = nil)
    @env.fetch(key, default)
  end

  def env!(key)
    result = @env.fetch(key, nil)

    @missing_envs << key if result.nil?

    result
  end

  def env?(key)
    @env[key] == 'true'
  end

  def env_set?(key)
    @env.fetch(key, nil) != nil
  end

  def find_envs(pattern, group: false)
    if group
      @env.each_with_object({}) do |(key, value), groups|
        match = key.match(pattern)
        next unless match

        group_key = match[1]
        suffix = key.sub(/.*#{Regexp.escape(group_key)}_?/, '')
        (groups[group_key] ||= {})[suffix] = value
      end
    else
      @env.select { |key, _| key =~ pattern }
    end
  end
end

# Run the generator
ConfigGenerator.new.generate_all
