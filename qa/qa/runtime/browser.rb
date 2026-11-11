# frozen_string_literal: true

require "capybara"
require "capybara/dsl"
require "selenium-webdriver"
require "fileutils"

module QA
  module Runtime
    # Configures Capybara + Selenium for the suite. Call `.configure!` once (done by
    # spec_helper). Supports a local Chrome driver or a remote Selenium grid
    # (QA_SELENIUM_URL), headless by default, and accepts the stack's self-signed cert.
    module Browser
      module_function

      def configure!
        FileUtils.mkdir_p(Env.screenshots_dir)

        Capybara.app_host = Env.base_url
        Capybara.run_server = false              # we drive an external deployment
        Capybara.default_max_wait_time = 15      # generous: the stack is eventually-consistent
        Capybara.default_normalize_ws = true
        Capybara.save_path = Env.screenshots_dir
        Capybara.default_driver = :codezero
        Capybara.javascript_driver = :codezero

        register_driver!
        Logger.info("Capybara configured for #{Env.base_url} " \
                    "(#{Env.selenium_url ? "remote #{Env.selenium_url}" : 'local'}, " \
                    "headless=#{Env.headless?})")
      end

      def register_driver!
        Capybara.register_driver(:codezero) do |app|
          if Env.selenium_url
            Capybara::Selenium::Driver.new(app,
                                           browser: :remote,
                                           url: Env.selenium_url,
                                           capabilities: chrome_options)
          else
            Capybara::Selenium::Driver.new(app,
                                           browser: Env.browser,
                                           capabilities: chrome_options)
          end
        end
      end

      def chrome_options
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless=new") if Env.headless?
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1920,1080")
        # The docker-compose stack serves HTTPS with a self-signed cert.
        options.add_argument("--ignore-certificate-errors") if Env.webdriver_insecure?
        options.accept_insecure_certs = true if Env.webdriver_insecure?
        options
      end
    end
  end
end
