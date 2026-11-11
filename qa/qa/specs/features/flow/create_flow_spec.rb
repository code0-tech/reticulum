# frozen_string_literal: true

# Issue #1188 workflow tests: "create flows".
#
# Orchestrated through the API: a flow needs a project and a flow-type GlobalID,
# and flow types are supplied by a connected action's module. So these specs
# require the full runtime (taurus) + REST action to be up — a real E2E stack.
module QA
  RSpec.describe "Workflow", product_group: :flow do
    let(:runtime) { Resource::Runtime.global.wait_until_running! }
    let(:flow_type_id) { Resource::Flow.discover_flow_type_id(runtime: runtime) }
    let(:namespace) { Resource::Namespace.personal }
    let(:project) do
      Resource::Project.fabricate_via_api! { |p| p.namespace = namespace }
    end

    after do
      @flow&.remove_via_api!
      project&.remove_via_api!
    end

    it "creates a flow in a project", :orchestrated, :smoke, :authenticated do
      @flow = Resource::Flow.fabricate_via_api! do |f|
        f.project = project
        f.flow_type_id = flow_type_id
      end

      expect(@flow.id).not_to be_nil
      expect(@flow.name).to start_with("qa-flow-")
    end
  end
end
