# frozen_string_literal: true

module QA
  module Page
    module Namespace
      module Project
        class Show < Base
          path_segments 'namespace', :namespace_id, 'project', :id
        end
      end
    end
  end
end
