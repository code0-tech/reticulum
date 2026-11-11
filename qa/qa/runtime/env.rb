# frozen_string_literal: true

module QA
  module Runtime
    # Central, read-only view of every environment variable the suite understands.
    # See qa/README.md for the full table. Keep all ENV reads here so configuration
    # has exactly one source of truth.
    module Env
      module_function

      # --- Target deployment ---------------------------------------------------

      # Base URL of the deployment under test (the nginx front door).
      def base_url
        env("QA_BASE_URL", "http://localhost").chomp("/")
      end

      def graphql_url
        "#{base_url}#{env('QA_GRAPHQL_PATH', '/graphql')}"
      end

      # docker-compose | terraform | external
      def deployment
        env("QA_DEPLOYMENT", "external")
      end

      def compose_dir
        env("QA_COMPOSE_DIR", File.expand_path("../../../docker-compose", __dir__))
      end

      # Whether to seed users/runtime before the suite. Only meaningful for local
      # deployments (docker-compose / terraform); never seed a remote environment.
      def seed?
        bool("QA_SEED", false)
      end

      # --- Credentials ---------------------------------------------------------

      # Defaults match the docker-compose stack's native seeding
      # (sagittarius db/fixtures/production: INITIAL_ROOT_MAIL/PASSWORD + the root
      # user, and INITIAL_RUNTIME_TOKEN). So against a stock local stack the suite
      # needs no extra seeding. Override all of these for staging/external.
      def user_email
        env("QA_USER_EMAIL", "root@code0.tech")
      end

      def user_username
        env("QA_USER_USERNAME", "root")
      end

      def user_password
        env("QA_USER_PASSWORD", "root")
      end

      def runtime_token
        env("QA_RUNTIME_TOKEN", "runtime")
      end

      # --- Browser -------------------------------------------------------------

      def browser
        env("QA_BROWSER", "chrome").to_sym
      end

      def headless?
        bool("QA_HEADLESS", true)
      end

      # Remote Selenium/WebDriver endpoint (e.g. a selenium-standalone CI service).
      # When nil, a local driver is used.
      def selenium_url
        value = env("QA_SELENIUM_URL", nil)
        value && !value.empty? ? value : nil
      end

      # Accept self-signed certs (docker-compose serves HTTPS with one).
      def webdriver_insecure?
        bool("QA_WEBDRIVER_INSECURE", true)
      end

      def screenshots_dir
        File.expand_path(env("QA_SCREENSHOTS_DIR", "tmp/screenshots"), project_root)
      end

      # --- Misc ----------------------------------------------------------------

      def log_level
        env("QA_LOG_LEVEL", "info").to_sym
      end

      def project_root
        File.expand_path("../../..", __dir__)
      end

      # --- Helpers -------------------------------------------------------------

      def env(key, default)
        value = ENV.fetch(key, nil)
        value.nil? || value.empty? ? default : value
      end

      def bool(key, default)
        value = ENV.fetch(key, nil)
        return default if value.nil? || value.empty?

        %w[1 true yes on].include?(value.downcase)
      end
    end
  end
end
