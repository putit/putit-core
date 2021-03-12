describe PutitJira::PutitJiraIntegration do
  it 'should handle webhook from jira' do
    VCR.use_cassette('putit_jira_integration_plugin') do
      payload = { "body": {
        "timestamp": 1_599_604_370_956,
        "webhookEvent": 'jira:version_released',
        "version": {
          "self": 'https://putit.atlassian.net/rest/api/2/version/10000',
          "id": '10000',
          "description": '',
          "name": '1.0',
          "archived": false,
          "released": true,
          "overdue": false,
          "userReleaseDate": '09/Sep/20',
          "projectId": 10_002
        }
      } }

      post '/handlers/jira', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response).to be_ok

      expect(PutitJira::JiraVersionReleasedIncomingWebhook.all.length).to eq 1
    end
  end
end
