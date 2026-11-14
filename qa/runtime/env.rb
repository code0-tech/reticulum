# frozen_string_literal: true

module QA
  module Runtime
    module Env
      extend Helpers

      module_function

      def base_url
        env('QA_BASE_URL', default: 'http://localhost/')
      end

      def graphql_url
        env('QA_GRAPHQL_URL', default: "#{base_url.chomp('/')}/graphql")
      end

      def environment_tier
        env('QA_ENVIRONMENT_TIER') do
          next :development if base_url =~ %r{https?://(?:[a-zA-Z0-9-]+\.)?localhost(?::\d+)?/}
          next :ci if bool('CI')

          next :production
        end
      end
    end
  end
end
