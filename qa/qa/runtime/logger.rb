# frozen_string_literal: true

require "logger"
require "rainbow"

module QA
  module Runtime
    # Thin wrapper around Ruby's Logger with coloring, shared process-wide.
    module Logger
      LEVELS = { debug: ::Logger::DEBUG, info: ::Logger::INFO,
                 warn: ::Logger::WARN, error: ::Logger::ERROR }.freeze

      module_function

      def logger
        @logger ||= ::Logger.new($stdout).tap do |l|
          l.level = LEVELS.fetch(Env.log_level, ::Logger::INFO)
          l.formatter = proc do |severity, time, _progname, msg|
            color = { "DEBUG" => :dimgray, "INFO" => :cyan,
                      "WARN" => :yellow, "ERROR" => :red }[severity] || :white
            "#{Rainbow("[QA #{severity}]").color(color)} #{time.strftime('%H:%M:%S')} #{msg}\n"
          end
        end
      end

      def debug(msg) = logger.debug(msg)
      def info(msg)  = logger.info(msg)
      def warn(msg)  = logger.warn(msg)
      def error(msg) = logger.error(msg)
    end
  end
end
