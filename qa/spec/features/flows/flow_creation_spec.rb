# frozen_string_literal: true

require 'spec_helper'

module QA
  RSpec.describe 'Flows' do
    describe 'Flow creation', :browser do
      it 'creates a flow' do
        organization = Resource::Organization.fabricate!(as: :test)
        project = Resource::Project.fabricate!(as: :test) { |p| p.namespace_id = organization.namespace_id }

        Page::Auth::Login.new.visit!.login(:test)

        project_page = Page::Namespace::Project::Show.new
        project_page.visit!(namespace_id: organization.namespace_model_id, id: project.model_id)
        project_page.wait_for_page

        name = "QA Flow #{SecureRandom.hex(4)}"

        project_page.create_flow(name: name)

        project_page.select_flow(name)

        flow_page = Page::Namespace::Project::Flow::Show.new
        flow_page.wait_for_page
        flow_parameters = flow_page.current_parameters

        flow = Resource::Flow.fetch! do |f|
          f.namespace_id = project.namespace_id
          f.project_id = project.id
          f.id = Resource::Flow.to_global_id(flow_parameters[:id])
        end

        expect(flow.name).to eq(name)
      end
    end
  end
end
