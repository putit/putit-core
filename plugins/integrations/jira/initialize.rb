module PutitJira
  # Base class for JIRA integration for putit
  class PutitJiraIntegration < Putit::Integration::IntegrationBase
    listen_for_webhook_on_url 'jira'

    on_webhook do |data|
      p "From JIRA webhook: #{data}"
    end
  end
end
