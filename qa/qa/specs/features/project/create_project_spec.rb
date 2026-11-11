# frozen_string_literal: true

# Issue #1188 "basic test: project creation". Modelled on GitLab's
# create_project_spec: do the creation through the UI, then verify the result.
module QA
  RSpec.describe "Tenant scale", product_group: :project do
    describe "Project creation" do
      it "creates a project through the UI and lists it", :browser, :smoke do
        name = "qa-project-#{SecureRandom.hex(4)}"

        dashboard = sign_in_via_ui
        dashboard.open_project_create.create_project(name: name)

        # The new project shows up in the dashboard's project list.
        expect(dashboard.loaded?).to be(true)
        expect(dashboard).to have_project(name)
      end

      it "creates a project via the API in the personal namespace", :api, :smoke, :authenticated do
        namespace = Resource::Namespace.personal
        project = Resource::Project.fabricate_via_api! do |p|
          p.namespace = namespace
        end

        expect(project.id).not_to be_nil
        expect(project.name).to start_with("qa-project-")
      ensure
        project&.remove_via_api!
      end
    end
  end
end
