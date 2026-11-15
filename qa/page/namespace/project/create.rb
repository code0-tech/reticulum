# frozen_string_literal: true

module QA
  module Page
    module Namespace
      module Project
        class Create < Base
          path_segments 'namespace', :id, 'project', 'create'

          element :name, 'dashboard-namespace-project-create-name'
          element :description, 'dashboard-namespace-project-create-description'
          element :submit, 'dashboard-namespace-project-create-send'
        end
      end
    end
  end
end
