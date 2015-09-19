require 'circleci'

module Lita
  module Handlers
    class Circleci < Handler
      # config :organization_name
      CircleCi.configure do |config|
        config.token = ENV["CIRCLECI_TOKEN"] || "8ef23f9b25252ac6f044328a15ed9a92d7e90727"
      end
      ORG = ENV['ORGANIZATION'] || 'marcelinol'
      CIRCLE_STATUSES = %w(queued scheduled not_running)

      route(/^build status (.+)\/(\S+)$/, :get_status, command: true, help: {
        'build status' => 'Get the status of the last build of the branch you asked'
      })

      route(/^boost build (.+)\/(\S+)$/, :boost_build, command: true, help: {
        'build status' => 'Get the status of the last build of the branch you asked'
      })

      def get_status(message)
        response = CircleCi::Project.recent_builds_branch(ORG, message.match_data[1], message.match_data[2])
        message.reply(handle_response(response))
      end

      def boost_build(message)
        handle_boost(message.match_data[1], message.match_data[2])
        message.reply("thats all right")
      end

      # private
      def handle_response(response)
        return "Sorry, I got no response from CircleCI :disappointed:" unless response
        if response.errors.any?
          error_message = JSON.parse(response.errors[0].message)['message']
          error_message
        elsif response.body.empty?
          "Branch not found"
        else
          "Last build status for this branch: #{response.body.first['status']}"
        end
      end

      def handle_boost(project, branch)
        #VERIFICAR SE A BRANCH EXISTE!
        builds = active_builds(project, branch)

        builds.each do |build_num|
          retry_build(project, build_num)
          cancel_build(project, build_num)
        end
      end

      def active_builds(project, branch)
        recent_builds = CircleCi::Project.recent_builds(ORG, project)
        recent_builds.body.reverse
        active_builds = []
        recent_builds.body.each do |build|
          return active_builds if build['branch'] == branch
          active_builds << build['build_num'] if must_retry(build)
        end
        active_builds
      end

      def must_retry(build)
        CIRCLE_STATUSES.include?(build['status'])
      end

      def cancel_build(project, build_num)
        CircleCi::Build.cancel(ORG, project, build_num)
      end

      def retry_build(project, build_num)
        CircleCi::Build.retry(ORG, project, build_num)
      end

      Lita.register_handler(self)
    end
  end
end
