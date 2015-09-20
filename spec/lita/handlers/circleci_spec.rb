require "spec_helper"

describe Lita::Handlers::Circleci, lita_handler: true, vcr: true do

  ## Routes
  it { is_expected.to route_command('build status project_name/some-branch').to(:get_status) }
  it { is_expected.to route_command('builds before project_name/some-branch').to(:builds_before) }
  it { is_expected.to route_command('how many builds before project_name/some-branch').to(:how_many_builds_before) }

  ## Commands
  describe '#get_status' do
    let(:organization_name) { 'marcelinol' }
    let(:project_name) { 'lita-circleci' }
    let(:branch) { 'master' }
    let(:message) { 'build status lita-circleci/master' }

    it 'calls circleci gem with correct parameters' do
      expect(CircleCi::Project).to receive(:recent_builds_branch).with(organization_name, project_name, branch)
      send_command(message)
    end

    context do
      before do
        send_command(message)
        sleep(240)
      end

      context 'when there is no connection with circle' do
        before { allow(CircleCi::Project).to receive(:recent_builds_branch).and_return(nil) }

        it do
          send_command(message)
          expect(replies.last).to match(/Sorry, I got no response from CircleCI/)
        end
      end

      context 'when the build is valid' do
        it { expect(replies.last).to match(/Last build status for this branch: success/) }
      end

      context 'with invalid information' do
        context 'of project' do
          let(:message) { 'build status wrong_project/feature-branch' }

          it 'replies with an error message' do
            expect(replies.last).to eq('Project not found')
          end
        end

        context 'of branch' do
          let(:message) { 'build status lita-circleci/inexistent-branch' }

          it 'replies with an error message' do
            expect(replies.last).to eq('Branch not found')
          end
        end
      end
    end
  end

  describe '#answer_builds_before' do
    let(:organization_name) { 'marcelinol' }
    let(:project_name) { 'lita-circleci' }
    let(:branch) { 'buildup' }

    before do
      send_command(message)
    end

    context 'with invalid parameters' do
      let(:message) { "builds before pipopo/papeira" }

      it 'does not answer the default answer to that command' do
        expect(replies.last).not_to match(/Those builds will run before yours/)
      end
    end

    context 'with valid parameters' do
      let(:message) { "builds before #{project_name}/#{branch}" }

      context "with other branch's build to run before the one asked" do
        let(:right_answer) { 'Those builds will run before yours: master(150), master(151)' }

        it { expect(replies.last).to eq(right_answer) }
      end

      context "with other build from the same branch to run before" do
        let(:right_answer) { 'Those builds will run before yours: master(150), master(151)' }

        it { expect(replies.last).to eq(right_answer) }
      end

      context "with no builds before the one asked" do
        let(:right_answer) { 'Those builds will run before yours: master(150), master(151)' }

        it { expect(replies.last).to eq(right_answer) }
      end

      context "when the build asked is already running" do
        let(:right_answer) { 'Those builds will run before yours: master(150), master(151)' }

        it { expect(replies.last).to eq(right_answer) }
      end
    end
  end
end
