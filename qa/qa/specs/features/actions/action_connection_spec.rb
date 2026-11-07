# frozen_string_literal: true

# Issue #1188 action tests: "connection of the action to the platform".
#
# The REST action is a separate service that logs on to the platform (aquila) and
# whose module is distributed to the runtime. This asserts that connection is
# observable: the runtime is RUNNING and reports the REST action's module as RUNNING.
module QA
  RSpec.describe "Actions", product_group: :action do
    let(:runtime) { Resource::Runtime.global }
    let(:action) { Resource::Action.new(runtime: runtime) }

    it "reports the REST action connected to the runtime", :orchestrated, :smoke do
      runtime.wait_until_running!
      expect(runtime.status).to eq(Resource::Runtime::RUNNING)

      action.wait_until_connected!
      expect(action.connected?(identifier: action.default_identifier)).to be(true)
    end
  end
end
