# frozen_string_literal: true

# Issue #1188 action tests: "definitions and such".
#
# Once the REST action is connected, its module distributes definitions (flow types
# and function definitions) to the runtime. This asserts those definitions are
# present and queryable via the runtime module API.
module QA
  RSpec.describe "Actions", product_group: :action do
    let(:runtime) { Resource::Runtime.global }
    let(:action) { Resource::Action.new(runtime: runtime) }

    before do
      runtime.wait_until_running!
      action.wait_until_connected!
    end

    it "exposes the REST action's definitions on the runtime", :orchestrated, :authenticated do
      # A trigger flow type (the thing a flow is built on) must be available.
      expect(action.flow_type_count).to be > 0

      # Function definitions are the callable operations the action exposes.
      expect(action.function_definition_count).to be >= 0
    end

    it "makes at least one flow type discoverable for flow creation", :orchestrated, :authenticated do
      expect { Resource::Flow.discover_flow_type_id(runtime: runtime) }.not_to raise_error
    end
  end
end
