require 'net/http'
require 'uri'

Config.load_and_set_settings(File.join(File.dirname(__FILE__), 'settings.yml'))

module PutitJira
  # Base class for JIRA integration for putit
  class PutitJiraIntegration < Putit::Integration::IntegrationBase
    listen_for_webhook_on_url 'jira'

    on_webhook do |data|
      json = JSON.parse(data, symbolize_names: true)
      body = json[:body][:version]
      JiraVersionReleasedIncomingWebhook.create!(
        release_id: body[:id],
        project_id: body[:projectId],
        name: body[:name],
        description: body[:description],
        release_date: body[:userReleaseDate],
        raw: data
      )

      uri = URI('https://putit.atlassian.net/rest/api/3/search')
      uri.query = URI.encode_www_form({ jql: "Project = #{body[:projectId]} and fixVersion = #{body[:name]}" })

      req = Net::HTTP::Get.new(uri)
      req.basic_auth 'matmaw@gmail.com', 'l6a8tTpTLKOzT8bebhuw48DD'

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
    end
  end
end
