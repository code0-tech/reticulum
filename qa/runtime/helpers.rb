# frozen_string_literal: true

module QA
  module Runtime
    module Helpers
      def env(key, default: nil)
        value = ENV.fetch(key, nil)
        if value.nil? || value.empty?
          if default.nil? && block_given?
            yield
          else
            default
          end
        else
          value
        end
      end

      def bool(key, default: false)
        value = ENV.fetch(key, nil)
        return default if value.nil? || value.empty?

        %w[1 true yes on].include?(value.downcase)
      end
    end
  end
end
