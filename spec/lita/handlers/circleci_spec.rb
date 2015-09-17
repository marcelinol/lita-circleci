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

    it 'calls circleci gem with correct parameters' do
      expect(CircleCi::Project).to receive(:recent_builds_branch).with(organization_name, project_name, branch)
      send_command(message)
    end

    context do
      before { send_command(message) }

      context 'when there is no connection with circle' do
        xit do
          send_command(message)
          expect(replies.last).to include('Sorry, I got no response from CircleCI')
        end
      end

      context 'when the build is valid' do
        it { expect(replies.last).to match(/Last build status for this branch/) }
      end

      context 'with invalid information' do
        context 'of project' do
          let(:message) { 'circle status wrong_project/feature-branch' }

          it 'replies with an error message' do
            expect(replies.last).to eq('Project not found')
          end
        end

        context 'of branch' do
          let(:message) { 'circle status lita-circleci/inexistent-branch' }

          it 'replies with an error message' do
            expect(replies.last).to eq('Branch not found')
          end
        end
      end
    end
  end
end
