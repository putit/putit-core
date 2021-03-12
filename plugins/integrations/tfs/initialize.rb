module PutitTfs
  # Base class for JIRA integration for putit
  class TfsIntegration < Putit::Integration::IntegrationBase
    listen_for_webhook_on_url 'tfs'

    on_webhook do |data|
      p "From TFS webhook: #{data}"
    end
  end
end
