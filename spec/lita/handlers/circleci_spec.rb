require "spec_helper"

describe Lita::Handlers::Circleci, lita_handler: true, vcr: true do

  ## Routes
  it { is_expected.to route_command('circle status project_name/some-branch').to(:get_status) }

  ## Commands
  describe '#get_status' do
    let(:organization_name) { 'marcelinol' }
    let(:project_name) { 'lita-circleci' }
    let(:branch) { 'master' }
    let(:message) { 'circle status lita-circleci/master' }

    before do
      allow_any_instance_of(CircleCi::Project).to receive(:recent_builds_branch).and_return(false)
    end

    xit 'calls circleci gem with correct parameters' do
      expect(CircleCi::Project).to receive(:recent_builds_branch).with(organization_name, project_name, branch)
      send_command(message)
    end

    context 'when the build is valid' do
      xit { expect(replies.last).to include('Last build status for this branch:') }
    end

    context 'with invalid information' do
      context 'of project' do
        let(:message) { 'circle status wrong_project/feature-branch' }

        xit 'replies with an error message' do
          expect(replies.last).to eq('Project not found')
        end
      end

      context 'of branch' do
        let(:message) { 'circle status spaceship/inexistent-branch' }

        xit 'replies with an error message' do
          expect(replies.last).to eq('Branch not found')
        end
      end
    end

  end

end
