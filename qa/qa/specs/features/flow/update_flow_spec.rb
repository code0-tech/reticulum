# frozen_string_literal: true

# Issue #1188 workflow tests: "flow update".
module QA
  RSpec.describe "Workflow", product_group: :flow do
    let(:runtime) { Resource::Runtime.global.wait_until_running! }
    let(:flow_type_id) { Resource::Flow.discover_flow_type_id(runtime: runtime) }
    let(:namespace) { Resource::Namespace.personal }
    let(:project) { Resource::Project.fabricate_via_api! { |p| p.namespace = namespace } }

    after do
      @flow&.remove_via_api!
      project&.remove_via_api!
    end

    it "renames an existing flow", :orchestrated, :authenticated do
      @flow = Resource::Flow.fabricate_via_api! do |f|
        f.project = project
        f.flow_type_id = flow_type_id
      end
      new_name = "qa-flow-renamed-#{SecureRandom.hex(4)}"

      @flow.update!(name: new_name)

      expect(@flow.name).to eq(new_name)
    end
  end
end
