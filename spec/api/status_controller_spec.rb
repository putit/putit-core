describe StatusController do
  describe 'should return Status for every env for WEBv1 application' do
    it 'should return proper status for UAT' do
      get '/status/WEBv1/uat'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:version]).to eq '2.0.0'
      expect(result[:status]).to eq 'failure'
      expect(result[:deployment_date]).to be_truthy
      expect(result[:log_url]).to match 'localhost:9292/status/WEBv1/uat/5/logs'
    end

    it 'should return proper status for dev' do
      get '/status/WEBv1/dev'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:version]).to eq '2.0.0'
      expect(result[:status]).to eq 'success'
      expect(result[:deployment_date]).to be_truthy
      expect(result[:log_url]).to be_truthy
    end

    it 'should return proper status for prod' do
      get '/status/WEBv1/prod'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:version]).to eq '1.0.0'
      expect(result[:status]).to eq 'success'
      expect(result[:deployment_date]).to be_truthy
      expect(result[:log_url]).to be_truthy
    end
  end

  it 'should return 404 when there were no deployments' do
    get '/status/TEST%20APPLICATION/prod'

    expect(last_response.status).to eq 404
  end
end
