# frozen_string_literal: true

module QA
  module Page
    module Namespace
      module Project
        class Show < Base
          path_segments 'namespace', :namespace_id, 'project', :id

          element :create_flow, 'dashboard-flow-create'
          element :flow_create_trigger_select, 'flow-create-trigger-select-item'
          element :flow_create_form, 'flow-create-form'
          element :flow_create_name_input, selector_override: 'div[role=textbox]'
          element :flow_create_submit, 'flow-create-send'

          element :flow_list_item, 'dashboard-flow-item'

          def create_flow(name:, trigger: 'Manual')
            Support::Waiter.wait_until(timeout: 10, log_retry_message: 'Flow trigger not found') do
              click_element :create_flow

              click_element :flow_create_trigger_select, text: trigger
            end

            within(find_element(:flow_create_form)) do
              fill_element :flow_create_name_input, name
            end

            click_element :flow_create_submit
          end

          def select_flow(name)
            click_element :flow_list_item, text: name
          end
        end
      end
    end
  end
end
