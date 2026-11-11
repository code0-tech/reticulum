# frozen_string_literal: true

require "capybara/dsl"

module QA
  module Page
    # Base class for sculptor page objects.
    #
    # sculptor annotates interactive elements with `data-qa-selector="<name>"`
    # (90+ of them across auth / dashboard / flow-builder). Page objects reference
    # those names, NOT CSS/text, so specs stay stable across UI refactors — exactly
    # the GitLab QA model.
    #
    # Declare the selectors a page uses and a path, e.g.:
    #
    #   class Login < Page::Base
    #     path "/login"
    #     view_selectors %w[auth-login-email auth-login-password auth-login-send]
    #   end
    #
    # REFERENCE IMPLEMENTATION: qa/page/auth/login.rb.
    class Base
      include Capybara::DSL

      class << self
        # URL path (relative to QA_BASE_URL) this page lives at.
        def path(value = nil)
          @path = value if value
          @path
        end

        # Optional: document which qa-selectors this page relies on (asserted by #on_page?).
        def view_selectors(list = nil)
          @view_selectors = list if list
          @view_selectors || []
        end
      end

      def path
        self.class.path
      end

      # --- Navigation ----------------------------------------------------------

      def visit!
        raise "#{self.class} has no path" unless self.class.path

        visit(self.class.path)
        self
      end

      # True when all declared view selectors are present.
      def on_page?
        self.class.view_selectors.all? { |name| has_element?(name) }
      end

      # --- data-qa-selector helpers -------------------------------------------

      def element_css(name)
        %([data-qa-selector="#{name}"])
      end

      def find_element(name, **options)
        find(element_css(name), **options)
      end

      def has_element?(name, **options)
        has_css?(element_css(name), **options)
      end

      def has_no_element?(name, **options)
        has_no_css?(element_css(name), **options)
      end

      def click_element(name, **options)
        find_element(name, **options).click
      end

      def fill_element(name, value, **options)
        find_element(name, **options).set(value)
      end

      # Element identified by qa-selector AND containing the given text. Useful for
      # list rows, e.g. has_element_with_text?("dashboard-project-row", project.name).
      def has_element_with_text?(name, text, **options)
        has_css?(element_css(name), text: text, **options)
      end

      # --- Waiting -------------------------------------------------------------

      # Block-based wait that re-queries the DOM; delegates to Capybara's waiting.
      def wait_until(timeout: Capybara.default_max_wait_time, &block)
        Support::Waiter.wait_until(timeout: timeout, interval: 0.5, &block)
      end

      # Wait for an element to appear (by qa-selector).
      def wait_for_element(name, timeout: Capybara.default_max_wait_time)
        has_element?(name, wait: timeout) ||
          raise(Capybara::ElementNotFound, "qa-selector #{name.inspect} not found after #{timeout}s")
      end
    end
  end
end
