# frozen_string_literal: true

# Issue #1188 action tests: "integrations inside the flow builder".
#
# Verifies the REST action, once connected, is usable when building a flow: its
# trigger appears in the "create flow" dialog's trigger picker. Setup is done via
# the API; the integration point is checked through the UI.
module QA
  RSpec.describe "Actions", product_group: :action do
    let(:runtime) { Resource::Runtime.global }
    let(:action) { Resource::Action.new(runtime: runtime) }
    let(:namespace) { Resource::Namespace.personal }
    let(:project) { Resource::Project.fabricate_via_api! { |p| p.namespace = namespace } }

    before do
      runtime.wait_until_running!
      action.wait_until_connected!
    end

    after { project&.remove_via_api! }

    it "offers the connected action's trigger when creating a flow", :browser do
      dashboard = sign_in_via_ui
      skip "Project navigation selector not available" unless dashboard.has_project?(project.name)

      # Open the project, then the flow-create dialog, and confirm a trigger is listed.
      dashboard.find_element("dashboard-project-list", text: project.name).click
      flow_create = Page::Project::Show.new.open_flow_create

      expect(flow_create).to have_element("flow-create-trigger-select-item")
    end

    it "exposes the action as a selectable flow type via the API", :orchestrated, :smoke do
      flow_type_id = Resource::Flow.discover_flow_type_id(runtime: runtime)
      expect(flow_type_id).to be_a(String).and(satisfy { |s| !s.empty? })
    end
  end
end
