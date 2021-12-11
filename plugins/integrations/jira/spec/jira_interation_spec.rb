describe 'JIRA Integration' do
  describe 'API' do
    it 'should parse payload and create JiraVersionReleasedIncomingWebhook' do
      payload = {
        "timestamp": 1599604370956,
        "webhookEvent": "jira:version_released",
        "version": {
            "self": "https://putit.atlassian.net/rest/api/2/version/10000",
            "id": "10000",
            "description": "",
            "name": "1.0",
            "archived": false,
            "released": true,
            "overdue": false,
            "userReleaseDate": "09/Sep/20",
            "projectId": 10002
        }
      }

      post '/handlers/jira/', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'
      
      incoming_webhook = PutitJira::JiraVersionReleasedIncomingWebhook.first
      expect(incoming_webhook.name).to eq '1.0'
      expect(incoming_webhook.description).to eq ''
      expect(incoming_webhook.project_id).to eq 10002
    end

    it 'should return status 400 and error when payload is wrong' do
      payload = {}

      post '/handlers/jira/', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 400
    end

    it 'should return all JiraVersionReleasedIncomingWebhook' do
      [1,2,3].each do |i| 
        PutitJira::JiraVersionReleasedIncomingWebhook.create({ name: i, description: i, project_id: 1000 + i })
      end

      get '/handlers/jira/releases/'

      expect(last_response.status).to eq 200

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 3

      expect(result[0][:name]).to eq '1'
      expect(result[0][:description]).to eq '1'
      expect(result[0][:project_id]).to eq 1001

      expect(result[1][:name]).to eq '2'
      expect(result[1][:description]).to eq '2'
      expect(result[1][:project_id]).to eq 1002

      expect(result[2][:name]).to eq '3'
      expect(result[2][:description]).to eq '3'
      expect(result[2][:project_id]).to eq 1003
    end
  end
end