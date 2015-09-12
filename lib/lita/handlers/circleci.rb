require 'circleci'

module Lita
  module Handlers
    class Circleci < Handler

      #TODO: puts config on config file
      CircleCi.configure do |config|
        config.token = ENV["CIRCLECI_TOKEN"] || ""
      end
      ORG = ENV['ORGANIZATION'] || 'NASA'
      PROJECT = ENV['PROJECT'] || 'spaceship'



      route(/^circle status (.+)$/, :get_status, command: true)

      def get_status(message)
        response = CircleCi::Project.build_branch(ORG, PROJECT, message.match_data[1])
        # message.reply "Last build status for this branch: #{response.body['status']}"
      end

      Lita.register_handler(self)
    end
  end
end
