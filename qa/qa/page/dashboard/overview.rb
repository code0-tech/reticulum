# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      # The dashboard landing page (`/`), shown after login. Entry point for creating
      # projects and for navigating to existing projects/flows.
      class Overview < Page::Base
        path "/"
        view_selectors %w[dashboard-navigation]

        def loaded?
          wait_for_element("dashboard-navigation", timeout: 20)
          true
        end

        # Open the "Create Project" dialog (ProjectCreateDialogComponent).
        def open_project_create
          click_element("dashboard-project-create")
          Project::Create.new
        end

        # True if a project with the given name is listed in the project list/table.
        def has_project?(name)
          has_element_with_text?("dashboard-project-list", name) ||
            has_element_with_text?("dashboard-project-table", name)
        end
      end
    end
  end
end
