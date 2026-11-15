# frozen_string_literal: true

module QA
  module Page
    module Namespace
      class Show < Base
        path_segments 'namespace', :id

        element :create_project, 'dashboard-project-create'
        element :project_table, 'dashboard-project-table'
        element :project_list, 'dashboard-project-list'

        def create_project(name:, description:)
          click_element :create_project

          create_page = Project::Create.new
          create_page.fill_element :name, name
          create_page.fill_element :description, description
          create_page.click_element :submit

          Support::Waiter.wait_until(message: 'Expected project to show up') do
            find_element(:project_table).has_text?(name)
          end
        end
      end
    end
  end
end
