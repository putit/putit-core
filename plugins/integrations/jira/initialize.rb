require 'net/http'
require 'uri'

# Extend ReleaseOrder class from putit-core with new method to find all Release Orders by JIRA release
class ReleaseOrder
  def self.find_by_jira_release_id(jira_release_id)
    where("metadata->>'jira_release = ?'", jira_release_id)
  end
end

module PutitJira
  # Base class for JIRA integration for putit
  class PutitJiraIntegration < Putit::Integration::IntegrationBase
    listen_for_webhook_on_url 'jira'

    on_webhook do |data, request|
      case request.path.chomp('/')
        when '/handlers/jira/releases'
          [200, JiraVersionReleasedIncomingWebhook.all.to_json]
        when '/handlers/jira'
          json = JSON.parse(data, symbolize_names: true)

          if !json[:version] 
            [400, { status: 'error' }]
          else
            body = json[:version]
            JiraVersionReleasedIncomingWebhook.create!(
              release_id: body[:id],
              project_id: body[:projectId],
              name: body[:name],
              description: body[:description],
              release_date: body[:userReleaseDate],
              raw: data
            )

            [201, { status: 'ok' }.to_json]
          end
        when /\/handlers\/jira\/release\/(\d+)\/attachToReleaseOrder\/(\d+)/
          ro = ReleaseOrder.find($2)
          if ro.nil?
            return [404, { status: 'error', msg: "Cannot find Release Order with id=#{$2}"}]
          end

          ro.metadata = ro.metadata.merge ({ jira_release: "#{$1}" })
          ro.save!

          # update JIRA with Release Order name/id
          [200, { status: 'ok' }.to_json]
        # search
        else
          [404, '']
      end
    end
  end
end
