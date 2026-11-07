# frozen_string_literal: true

# Load path: qa/ is the root, so "qa" and "qa/..." resolve.
$LOAD_PATH.unshift(File.expand_path("../..", __dir__))

require "rspec"
require "rspec/retry"
require "capybara/rspec"
require "qa"

module QA
  module Specs
    # Helpers available in every spec (included below).
    module Helpers
      # Log in through the sculptor UI and return the loaded dashboard page object.
      # Use at the start of :browser specs that need an authenticated session.
      def sign_in_via_ui
        QA::Page::Auth::Login.new.visit!.login_as_qa_user!
        QA::Page::Dashboard::Overview.new.tap(&:loaded?)
      end
    end
  end
end

RSpec.configure do |config|
  config.include QA::Specs::Helpers
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :defined # feature specs often build on prior state within a file
  config.formatter = :documentation

  # Retry browser specs once (they are the flaky ones); API specs are deterministic.
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.around(:each, :browser) { |ex| ex.run_with_retry(retry: 2) }

  # Make the Capybara DSL + QA helpers available in every spec.
  config.include Capybara::DSL
  config.include QA

  # One-time setup: configure the browser, seed local data, log the API client in.
  config.before(:suite) do
    QA::Runtime::Logger.info("Target: #{QA::Runtime::Env.base_url} " \
                             "(deployment=#{QA::Runtime::Env.deployment})")
    QA::Runtime::Browser.configure!
    QA::Runtime::Seed.perform!
    QA::Runtime::ApiClient.default # memoized login; fails fast if creds/URL are wrong
  end

  # Capture a screenshot + HTML on browser-spec failure for debugging.
  config.after(:each, :browser) do |example|
    next unless example.exception

    name = example.full_description.gsub(/[^\w]+/, "_")[0, 100]
    dir = QA::Runtime::Env.screenshots_dir
    begin
      page.save_screenshot(File.join(dir, "#{name}.png"))
      page.save_page(File.join(dir, "#{name}.html"))
      QA::Runtime::Logger.warn("Saved failure artifacts to #{dir}/#{name}.{png,html}")
    rescue StandardError => e
      QA::Runtime::Logger.warn("Could not save failure artifacts: #{e.message}")
    end
  end

  # Reset the session between browser examples so each starts logged out.
  config.after(:each, :browser) { Capybara.reset_sessions! }
end
