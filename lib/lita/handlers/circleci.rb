require 'circleci'

module Lita
  module Handlers
    class Circleci < Handler
      # config :organization_name
      CircleCi.configure do |config|
        config.token = ENV["CIRCLECI_TOKEN"] || "8ef23f9b25252ac6f044328a15ed9a92d7e90727"
      end
      ORG = ENV['ORGANIZATION'] || 'marcelinol'
      CIRCLE_WAITING_STATUSES = %w(queued scheduled not_running)

      route(/^build status (.+)\/(\S+)$/, :get_status, command: true, help: {
        'build status' => 'Get the status of the last build of the branch you asked'
      })

      route(/^builds before (.+)\/(\S+)$/, :builds_before, command: true, help: {
        'builds before' => 'Get the amount of builds that will run before the informed one'
      })

      route(/^how many builds before (.+)\/(\S+)$/, :how_many_builds_before, command: true, help: {
        'builds before' => 'Get the amount of builds that will run before the informed one'
      })

      route(/^boost build (.+)\/(\S+)$/, :boost_build, command: true, help: {
        'build status' => 'Get the status of the last build of the branch you asked'
      })

      def get_status(message)
        response = CircleCi::Project.recent_builds_branch(ORG, message.match_data[1], message.match_data[2])
        message.reply(handle_response(response))
      end

      def builds_before(message)
        project = message.match_data[1]
        branch = message.match_data[2]

        waiting_builds = waiting_builds(project)

        branch_build = branch_last_build(project, branch)
        message.reply branch_build['build_num'].to_s

        waiting_builds_before = []
        waiting_builds.reverse.each do |build|
          break if build['build_num'] == branch_build['build_num']
          waiting_builds_before << build
        end

        answer = waiting_builds_before.map do |build|
          "#{build['branch']}(#{build['build_num']})"
        end

        message.reply "Those builds will run before yours: #{answer.join(', ')}"
      end

      def how_many_builds_before(message)
      end

      def branch_last_build(project, branch)
        response = CircleCi::Project.recent_builds_branch(ORG, project, branch)
        response.body.first if response
      end

      def waiting_builds(project)
        recent_builds = CircleCi::Project.recent_builds(ORG, project).body

        recent_builds.map do |build|
          build if CIRCLE_WAITING_STATUSES.include?(build['status'])
        end.compact!
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
        CIRCLE_WAITING_STATUSES.include?(build['status'])
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
