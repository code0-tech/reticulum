# frozen_string_literal: true

module QA
  module Page
    module Dashboard
      class Home < Base
        path_segments # is at root, no segments

        element :user_menu, 'dashboard-navigation-user'

        element :user_menu_settings, selector_override: 'a[href="/users/@me/settings"]'

        def open_user_settings
          click_element :user_menu
          click_element :user_menu_settings
        end
      end
    end
  end
end
