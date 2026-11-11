# frozen_string_literal: true

# Issue #1188 workflow tests: "flow delete".
module QA
  RSpec.describe "Workflow", product_group: :flow do
    let(:runtime) { Resource::Runtime.global.wait_until_running! }
    let(:flow_type_id) { Resource::Flow.discover_flow_type_id(runtime: runtime) }
    let(:namespace) { Resource::Namespace.personal }
    let(:project) { Resource::Project.fabricate_via_api! { |p| p.namespace = namespace } }

    after { project&.remove_via_api! }

    it "deletes a flow and it no longer resolves", :orchestrated, :authenticated do
      flow = Resource::Flow.fabricate_via_api! do |f|
        f.project = project
        f.flow_type_id = flow_type_id
      end
      flow_id = flow.id

      flow.remove_via_api!

      # The flow no longer resolves via the namespace -> project -> flow path.
      data = Runtime::ApiClient.default.query(<<~GQL, variables: { nsid: namespace.id, pid: project.id, fid: flow_id })
        query($nsid: NamespaceID!, $pid: NamespaceProjectID!, $fid: FlowID!) {
          namespace(id: $nsid) {
            project(id: $pid) {
              flow(id: $fid) { id }
            }
          }
        }
      GQL
      expect(data.dig("namespace", "project", "flow")).to be_nil
    end
  end
end
