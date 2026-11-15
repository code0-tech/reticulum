# frozen_string_literal: true

module QA
  module Page
    class Base
      UnknownElementError = Class.new(Error)
      UnknownParameterError = Class.new(Error)

      include Capybara::DSL

      include SemanticLogger::Loggable

      class << self
        def path_segments(*segments)
          @path_segments = segments
        end

        def element(name, qa_selector = nil, selector_override: nil)
          @elements ||= {}
          if qa_selector
            @elements[name] = %([data-qa-selector="#{qa_selector}"])
          elsif selector_override
            @elements[name] = selector_override
          else
            raise ArgumentError, 'Either qa_selector or selector_override must be set'
          end
        end
      end

      def path_segments
        self.class.instance_variable_get(:@path_segments)
      end

      def path(**parameters)
        consumed_segments = []

        constructed_path = path_segments.map do |segment|
          if segment.is_a?(Symbol)
            parameter = parameters.fetch(segment)
            consumed_segments << segment
            parameter
          else
            segment
          end
        end.join('/')

        unused_segments = parameters.keys - consumed_segments
        unless unused_segments.empty?
          raise UnknownParameterError, "Parameter for unknown segments #{unused_segments} provided"
        end

        constructed_path
      end

      def visit!(**parameters)
        visit_path = path(**parameters)

        logger.info('Visiting page', path: visit_path)

        visit(visit_path)

        self
      end

      def on_page?
        current_path_segments = current_path.split('/').reject(&:blank?)

        return false unless current_path_segments.size == path_segments.size

        path_segments.map.with_index do |segment, index|
          segment.is_a?(Symbol) || segment == current_path_segments[index]
        end.all?
      end

      def wait_for_page(**wait_options)
        Support::Waiter.wait_until(
          message: "Expected to be on #{self.class.name}",
          **wait_options
        ) { on_page? }

        self
      rescue Support::Waiter::TimeoutError => e
        raise Support::Waiter::TimeoutError, "#{e.message} (current path: #{current_path.inspect})"
      end

      def current_parameters
        current_path_segments = current_path.split('/').reject(&:blank?)

        path_segments.each_with_index.with_object({}) do |(segment, index), acc|
          acc[segment] = current_path_segments[index] if segment.is_a?(Symbol)
        end
      end

      def element_selector(name)
        elements = self.class.instance_variable_get(:@elements)

        raise UnknownElementError, "Element #{name} is not declared on #{self.class.name}" unless elements.key?(name)

        elements[name]
      end

      def find_element(name, **options)
        find(element_selector(name), **options)
      end

      def click_element(name, **options)
        element = find_element(name, **options)
        logger.info('Clicking element', name: name)
        element.click
      end

      def fill_element(name, value, **options)
        element = find_element(name, **options)
        password_field = element.matches_selector?('[type=password]')
        logger.info('Filling element', name: name, value: password_field ? '***' : value)

        element.set(value)
      end
    end
  end
end
