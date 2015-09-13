require 'circleci'

module Lita
  module Handlers
    class Circleci < Handler
      # config :organization_name
      # config :project_name
      CircleCi.configure do |config|
        config.token = ENV["CIRCLECI_TOKEN"] || ""
      end
      ORG = ENV['ORGANIZATION'] || 'NASA'

      route(/^circle status (.+)\/(\S+)$/, :get_status, command: true)

      def get_status(message)
        response = CircleCi::Project.recent_builds_branch(ORG, message.match_data[1], message.match_data[2])
        message.reply "Last build status for this branch: #{response.body.first['status']}"
      end

      Lita.register_handler(self)
    end
  end
end
