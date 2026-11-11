# frozen_string_literal: true

module QA
  module Page
    module Flow
      # The flow builder (an @xyflow/react canvas) with its bottom control panel and
      # the manual-execution dialog.
      #
      # Selectors:
      #   flow-builder-canvas, flow-builder-node, flow-builder-trigger
      #   flow-builder-control-panel(-add|-delete|-execute)
      #   flow-builder-manual-execution-form(-input|-trigger)
      #
      # The builder URL is `/namespace/<ns>/project/<project>/flow/<flow>`. The id
      # segments are sculptor's own id/slug format, which differs from GraphQL
      # GlobalIDs — confirm the exact format against a live stack before relying on
      # `#visit_builder`; browser specs otherwise navigate here from the project page.
      class Builder < Page::Base
        view_selectors %w[flow-builder-canvas]

        def self.path_for(namespace:, project:, flow:)
          "/namespace/#{namespace}/project/#{project}/flow/#{flow}"
        end

        def visit_builder(namespace:, project:, flow:)
          visit(self.class.path_for(namespace: namespace, project: project, flow: flow))
          self
        end

        def loaded?
          wait_for_element("flow-builder-canvas", timeout: 20)
          true
        end

        def node_count
          all(element_css("flow-builder-node")).size
        end

        # Open the "add node" affordance in the control panel. Selecting a specific
        # function/action node from the resulting picker is drag/drop on the canvas;
        # that interaction depends on live DOM and should be completed against a
        # running stack.
        def open_add_node
          click_element("flow-builder-control-panel-add")
          self
        end

        def has_control_panel?
          has_element?("flow-builder-control-panel")
        end

        # --- Manual execution ---------------------------------------------------

        # Open the execute dialog from the control panel.
        def open_execute_dialog
          click_element("flow-builder-control-panel-execute")
          wait_for_element("flow-builder-manual-execution-form")
          self
        end

        def has_execution_input?
          has_element?("flow-builder-manual-execution-input")
        end

        # Fill the manual-execution input (if the trigger requires one) and run it.
        def execute(input: nil)
          fill_element("flow-builder-manual-execution-input", input) if input && has_execution_input?
          click_element("flow-builder-manual-execution-trigger")
          self
        end
      end
    end
  end
end
