# frozen_string_literal: true

require_relative '../load'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.formatter = :documentation

  config.include Capybara::DSL
  config.include SemanticLogger::Loggable

  config.define_derived_metadata do |metadata|
    metadata[:file_path]&.gsub!('./spec', './qa/spec') if ENV['CI']
  end

  config.before(:suite) do
    QA::Runtime::Logger.configure!
    QA::Runtime::Browser.configure!
    QA::Runtime::Browser.stream_console_to_logger!

    QA::Resource::User.provision_test_user! if QA::Runtime::Credentials.create_test_user?
  end

  config.after(:each, :browser) do |example|
    if example.exception
      name = example.full_description.gsub(/[^\w]+/, '_')[0, 100]
      dir = QA::Runtime::Browser.screenshots_dir
      begin
        # rubocop:disable Lint/Debugger
        page.save_screenshot(File.join(dir, "#{name}.png"))
        page.save_page(File.join(dir, "#{name}.html"))
        # rubocop:enable Lint/Debugger
        example.example_group.logger.warn("Saved failure artifacts to #{dir}/#{name}.{png,html}")
      rescue StandardError => e
        example.example_group.logger.warn("Could not save failure artifacts: #{e.message}")
      end
    end

    Capybara.reset_sessions!
  end

  config.after(:each) do
    QA::Runtime::ResourceRegistry.clear!(:example)
  end

  config.after(:suite) do
    QA::Runtime::ResourceRegistry.clear!(:suite)
  end
end
