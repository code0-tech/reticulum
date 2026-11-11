# frozen_string_literal: true

module QA
  module Page
    module Project
      # The "Create new project" dialog (ProjectCreateDialogComponent), opened from
      # the dashboard. A modal, so it has no path of its own.
      class Create < Page::Base
        view_selectors %w[dashboard-namespace-project-create-name dashboard-namespace-project-create-send]

        # Fill the form and submit. Returns self.
        def create_project(name:, description: "Created by the QA suite")
          wait_for_element("dashboard-namespace-project-create-name")
          fill_element("dashboard-namespace-project-create-name", name)
          fill_element("dashboard-namespace-project-create-description", description) if has_element?("dashboard-namespace-project-create-description")
          click_element("dashboard-namespace-project-create-send")
          self
        end
      end
    end
  end
end
