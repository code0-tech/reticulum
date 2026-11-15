# frozen_string_literal: true

module QA
  module Runtime
    module Browser
      extend Helpers

      module_function

      include SemanticLogger::Loggable

      SCULPTOR_GRAPHQL_ERROR_MARKER = '[ERROR]'

      def capybara_driver
        env('QA_CAPYBARA_DRIVER', default: 'firefox_bidi').to_sym
      end

      def headless?
        bool('QA_HEADLESS', default: true)
      end

      def selenium_remote_url
        env('QA_SELENIUM_REMOTE_URL', default: 'http://localhost:4444')
      end

      def screenshots_dir
        File.expand_path(env('QA_SCREENSHOTS_DIR', default: 'tmp/screenshots'), "#{__dir__}/..")
      end

      def firefox_options
        options = Selenium::WebDriver::Firefox::Options.new
        options.add_argument('-headless') if headless?
        options.add_argument('--width=1280')
        options.add_argument('--height=800')
        options.enable_bidi! # for console streaming
        options
      end

      def chrome_options
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless=new') if headless?
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument('--window-size=1280,800')
        options.enable_bidi! # for console streaming
        options
      end

      def register_drivers!
        Capybara.register_driver(:firefox_bidi) do |app|
          Capybara::Selenium::Driver.new(app, browser: :firefox, options: firefox_options)
        end

        Capybara.register_driver(:firefox_bidi_remote) do |app|
          Capybara::Selenium::Driver.new(
            app,
            browser: :remote,
            url: selenium_remote_url,
            options: firefox_options
          )
        end

        Capybara.register_driver(:chrome_bidi) do |app|
          Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
        end

        Capybara.register_driver(:chrome_bidi_remote) do |app|
          Capybara::Selenium::Driver.new(
            app,
            browser: :remote,
            url: selenium_remote_url,
            options: chrome_options
          )
        end
      end

      def configure!
        FileUtils.mkdir_p(screenshots_dir)
        register_drivers!

        Capybara.app_host = Env.base_url
        Capybara.run_server = false
        Capybara.default_driver = capybara_driver
        Capybara.save_path = screenshots_dir

        logger.info('Capybara configured', base_url: Env.base_url, driver: capybara_driver)
      end

      def stream_console_to_logger!
        driver = Capybara.current_session.driver.browser
        return unless driver.respond_to?(:script)

        driver.script.add_console_message_handler do |message|
          text = console_message_text(message)

          if text.start_with?(SCULPTOR_GRAPHQL_ERROR_MARKER)
            logger.error('Browser console', message: text)
          else
            logger.debug('Browser console', level: message.level, message: text)
          end
        end
      rescue StandardError => e
        logger.warn('Could not attach console message handler', error: e.message)
      end

      def console_message_text(message)
        parts = Array(message.args).map { |arg| stringify_remote_value(arg) }
        parts.join(' ')
      rescue StandardError
        message.text
      end

      def stringify_remote_value(value)
        case value['type']
        when 'string', 'number', 'boolean'
          value['value'].to_s
        when 'object'
          pairs = Array(value['value']).map { |k, v| "#{k}: #{stringify_remote_value(v)}" }
          "{#{pairs.join(', ')}}"
        when 'array'
          "[#{Array(value['value']).map { |v| stringify_remote_value(v) }.join(', ')}]"
        when 'null'
          'null'
        else
          value['value'].inspect
        end
      end
    end
  end
end
