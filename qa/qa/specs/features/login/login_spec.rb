# frozen_string_literal: true

# REFERENCE SPEC — the smallest end-to-end browser test. New specs follow this
# shape: tag the scenario area + a layer tag (:browser / :api / :orchestrated),
# drive via page objects and/or resources, assert via the UI and/or the API.
#
# Covers the issue's "basic test: login" and proves the whole stack is wired:
# nginx -> sculptor UI -> sagittarius GraphQL.
module QA
  RSpec.describe "Platform access", product_group: :authentication do
    describe "User login", :browser, :smoke do
      it "signs in with valid credentials and reaches the dashboard" do
        Page::Auth::Login.new.visit!.login_as_qa_user!

        # After login sculptor routes to "/" and renders the dashboard navigation.
        expect(page).to have_css(%([data-qa-selector="dashboard-navigation"]), wait: 20)
      end
    end

    # The same capability exercised purely through the API — fast, deterministic,
    # and the mechanism every :orchestrated spec uses to authenticate.
    describe "API login", :api, :smoke do
      it "issues a session token via the usersLogin mutation" do
        client = Runtime::ApiClient.new
        token = client.login!

        expect(token).to be_a(String)
        expect(token).not_to be_empty
      end
    end
  end
end
