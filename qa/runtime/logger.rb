# frozen_string_literal: true

module QA
  module Runtime
    module Logger
      extend Helpers

      module_function

      class NoProcessColorFormatter < SemanticLogger::Formatters::Color
        def initialize(**args)
          args[:color_map] ||= ::SemanticLogger::Formatters::Color::ColorMap.new(
            debug: ::SemanticLogger::AnsiColors::CYAN,
            info: ::SemanticLogger::AnsiColors::GREEN,
            warn: ::SemanticLogger::AnsiColors::YELLOW,
            error: ::SemanticLogger::AnsiColors::RED,
            fatal: ::SemanticLogger::AnsiColors::RED
          )

          super
        end

        def process_info
          nil
        end
      end

      def log_level
        env('QA_LOG_LEVEL', default: 'info').to_sym
      end

      def configure!
        SemanticLogger.application = 'QA'
        SemanticLogger.default_level = log_level
        SemanticLogger.push_tags('QA')
        SemanticLogger.add_appender(io: $stderr, level: log_level, formatter: NoProcessColorFormatter.new)
      end
    end
  end
end
