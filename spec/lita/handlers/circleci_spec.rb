require "spec_helper"

describe Lita::Handlers::Circleci, lita_handler: true do

  ## Routes
  it { is_expected.to route_command('circle status some-branch').to(:get_status) }

  ## Commands
  describe '#get_status' do
    let(:organization) { 'NASA' }
    let(:project) { 'spaceship' }
    let(:branch) { 'feature-branch' }
    let(:message) { 'circle status feature-branch' }

    before do
      allow_any_instance_of(CircleCi::Project).to receive(:build_branch).and_return(false)
    end

    it 'calls circleci gem with correct parameters' do
      expect(CircleCi::Project).to receive(:build_branch).with(organization, project, branch)
      send_command(message)
    end

    context 'when the build is invalid' do
    end

    context 'when the build is valid' do
    end
  end

end
