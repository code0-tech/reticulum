# frozen_string_literal: true

require 'spec_helper'

module QA
  RSpec.describe 'Projects' do
    describe 'Project creation', :browser do
      it 'creates a project in a fabricated organization via the UI' do
        organization = Resource::Organization.fabricate!

        Page::Auth::Login.new.visit!.login

        namespace_page = Page::Namespace::Show.new
        namespace_page.visit!(id: organization.namespace_model_id)

        project_name = "QA Project #{SecureRandom.hex(4)}"
        namespace_page.create_project(name: project_name, description: 'Created by QA e2e suite')

        expect(namespace_page.find_element(:project_table)).to have_text(project_name)

        namespace_page.click_element(:project_list, text: project_name)

        project_page = Page::Namespace::Project::Show.new.wait_for_page
        project = Resource::Project.fetch! do |p|
          p.namespace_id = organization.namespace_id
          p.id = Resource::Project.to_global_id(project_page.current_parameters[:id])
        end

        expect(project.name).to eq(project_name)
      end
    end
  end
end
