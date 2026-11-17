# frozen_string_literal: true

module QA
  module Page
    module Namespace
      module Project
        module Flow
          class Show < Base
            path_segments 'namespace', :namespace_id, 'project', :project_id, 'flow', :id
          end
        end
      end
    end
  end
end
