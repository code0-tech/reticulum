# frozen_string_literal: true

module QA
  module Page
    module Flow
      # The "Create new flow" dialog (FlowCreateDialogComponent). The user first picks
      # a trigger (or a template), then names the flow and confirms.
      #
      # Selectors: flow-create-list, flow-create-trigger-select-item,
      # flow-create-template-mode, flow-create-template-select-item,
      # flow-create-form, flow-create-name, flow-create-send.
      class Create < Page::Base
        view_selectors %w[flow-create-list]

        # Pick the first available trigger from the list.
        def select_first_trigger
          wait_for_element("flow-create-trigger-select-item")
          all_trigger_items.first.click
          self
        end

        # Name the flow and confirm creation. Must be called after a trigger/template
        # is selected (the flow-create-form only appears then).
        def create_flow(name:)
          wait_for_element("flow-create-name")
          fill_element("flow-create-name", name)
          click_element("flow-create-send")
          self
        end

        private

        def all_trigger_items
          all(element_css("flow-create-trigger-select-item"), minimum: 1)
        end
      end
    end
  end
end
