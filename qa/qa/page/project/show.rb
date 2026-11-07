# frozen_string_literal: true

module QA
  module Page
    module Project
      # A project's view, listing its flows and offering flow creation
      # (`dashboard-flow-create` opens the FlowCreateDialogComponent).
      #
      # The project URL uses ids/slugs rendered by sculptor; browser specs normally
      # reach this page by navigating from the dashboard rather than by a built URL.
      class Show < Page::Base
        view_selectors %w[dashboard-flow-create]

        # Open the "Create new flow" dialog.
        def open_flow_create
          wait_for_element("dashboard-flow-create")
          click_element("dashboard-flow-create")
          Flow::Create.new
        end

        # True if a flow with the given name is listed.
        def has_flow?(name)
          has_element_with_text?("dashboard-flow-item", name) ||
            has_element_with_text?("dashboard-flow-recent-list", name)
        end

        def has_no_flow?(name)
          has_no_element?("dashboard-flow-item", text: name)
        end
      end
    end
  end
end
