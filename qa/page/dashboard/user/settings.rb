# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      module User
        class Settings < Base
          path_segments 'users', '@me', 'settings'

          element :email, selector_override: 'input[type=email]'
        end
      end
    end
  end
end
