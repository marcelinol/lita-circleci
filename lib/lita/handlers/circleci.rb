require 'circleci'

module Lita
  module Handlers
    class Circleci < Handler
      # config :organization_name
      CircleCi.configure do |config|
        config.token = ENV["CIRCLECI_TOKEN"] || "8ef23f9b25252ac6f044328a15ed9a92d7e90727"
      end
      ORG = ENV['ORGANIZATION'] || 'marcelinol'

      route(/^build status (.+)\/(\S+)$/, :get_status, command: true, help: {
        'build status' => 'Get thde status of the last build of the branch you asked'
      })

      def get_status(message)
        response = CircleCi::Project.recent_builds_branch(ORG, message.match_data[1], message.match_data[2])
        message.reply(handle_response(response))
      end

      private
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

      Lita.register_handler(self)
    end
  end
end
