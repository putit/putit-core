describe ApplicationController do
  describe 'Adding applications' do
    it 'should add new application' do
      application = {
        name: 'Application 2',
        version: '2.0.0'
      }

      post '/application', application.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:id]).to eq 3
      expect(result[:name]).to eq 'Application 2'
      expect(result[:versions][0]).to eq '2.0.0'
    end

    it 'should add new application without version' do
      application = {
        name: 'Application 2'
      }

      post '/application', application.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:name]).to eq 'Application 2'
      expect(result[:versions].length).to eq 0
    end

    it 'should add version to application added without version' do
      application = {
        name: 'Application 2'
      }

      version = {
        version: '1.3.0'
      }

      post '/application', application.to_json, 'CONTENT_TYPE': 'application/json'
      post '/application/Application%202/versions', version.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'
      versions = Application.find_by_name('Application 2').versions
      expect(versions.length).to eq 1
      expect(versions[0].version).to eq '1.3.0'
    end
  end

  describe 'Removing applications' do
    it 'should remove Application' do
      application = {
        name: 'Application 2',
        version: '2.0.0'
      }

      post '/application', application.to_json, 'CONTENT_TYPE': 'application/json'

      version_id = Application.find_by_name('Application 2').versions.first.id

      delete '/application/Application%202'

      expect(last_response.status).to eq 202

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'
      expect(Application.find_by_name('Application 2')).to be_nil
      expect(ApplicationWithVersion.exists?(version_id)).to eq false
    end

    it 'should return 404 when Application to delete does not exists' do
      delete '/application/Application%203'

      expect(last_response.status).to eq 404
    end
  end

  describe 'Getting application' do
    it 'should get Application by name' do
      get '/application/WEBv1'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:name]).to eq 'WEBv1'
      expect(result[:versions]).to include('1.0.0')
      expect(result[:versions]).to include('2.0.0')
    end

    it 'should get Versions for name' do
      get '/application/WEBv1/versions'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 2
      expect(result).to include(include(id: 1, name: 'WEBv1', version: '1.0.0'))
      expect(result).to include(include(id: 2, name: 'WEBv1', version: '2.0.0'))
    end
  end

  describe 'Adding artifacts' do
    it 'should add artifact with version to application with version' do
      payload = {
        name: 'other',
        version: '1.4.1'
      }

      post '/application/WEBv1/versions/1.0.0/artifacts', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 202
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      a = ApplicationWithVersionArtifactWithVersion.last.artifact_with_version.artifact
      v = ApplicationWithVersionArtifactWithVersion.last.artifact_with_version.version

      expect(a.name).to eq 'other'
      expect(v.version).to eq '1.4.1'
    end

    it 'should return error when version of application does not exists' do
      payload = {
        name: 'other',
        version: '1.4.4'
      }

      post '/application/WEBv1/versions/1.0.0/artifacts', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 404
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:status]).to eq 'error'
      expect(result[:msg]).to eq 'Version "1.4.4" for artifact "other" does not exists'
    end
  end

  describe 'Removing artifacts' do
    it 'should remove artifact from Application with Version' do
      payload = {
        name: 'other',
        version: '1.4.1'
      }

      post '/application/WEBv1/versions/1.0.0/artifacts', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 202
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      delete '/application/WEBv1/versions/1.0.0/artifacts/other/1.4.1'

      expect(last_response.status).to eq 202
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'
    end
  end

  describe 'Envs' do
    it 'should add env to application' do
      payload = [{
        name: 'prod'
      }]

      post '/application/TEST%20APPLICATION/envs', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      payload = {
        name: 'prod-1'
      }

      post '/application/TEST%20APPLICATION/envs', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      app = Application.find_by_name('TEST APPLICATION')

      expect(app.envs.length).to eq 3
      expect(app.envs.map(&:name)).to match_array %w[prod prod-1 test]
    end

    it 'should not add any envs if any of them already exists' do
      payload = [
        { name: 'should_not_exist' },
        { name: 'test' },
        { name: 'should_not_exist_too' }
      ]

      post '/application/TEST%20APPLICATION/envs', payload.to_json, 'CONTENT_TYPE': 'application/json'
      expect(last_response.status).to eq 409

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:conflicts]).to match_array ['test']

      app = Application.find_by_name('TEST APPLICATION')
      expect(app.envs.map(&:name)).not_to include 'should_not_exist'
      expect(app.envs.map(&:name)).not_to include 'should_not_exist_too'
    end

    it 'should delete env from application' do
      delete '/application/WEBv1/envs/uat'

      expect(last_response.status).to eq 202

      app = Application.find_by_name('WEBv1')
      expect(app.envs.length).to eq 2
      expect(app.envs.map(&:name)).to match_array %w[prod dev]
    end

    it 'should return 404 when env for delete does not exists' do
      delete '/application/WEBv1/envs/not%20exists'

      expect(last_response.status).to eq 404

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Env "not exists" for Application "WEBv1" does not exists.'
    end

    it 'should add Credential to env by name' do
      credential = Credential.first

      put "/application/WEBv1/envs/dev/credential/#{URI.encode_www_form_component(credential.name)}"

      expect(last_response.status).to eq 202

      app = Application.find_by_name('WEBv1')
      env = app.envs.find_by_name('dev')

      expect(env.credential).to eq credential
    end

    it 'should return 404 when Credential does not exists' do
      put '/application/WEBv1/envs/dev/credential/not%20exists'

      expect(last_response.status).to eq 404

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Credential "not exists" does not exists.'
    end

    it 'should return Credential for env' do
      app = Application.find_by_name('WEBv1')
      env = app.envs.find_by_name('dev')
      env.credential = Credential.second

      get '/application/WEBv1/envs/dev/credential'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:name]).to eq 'credential2'
    end

    describe 'Pipelines' do
      it 'get pipelines for Env' do
        get 'application/WEBv1/envs/dev/pipelines'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 2
        expect(result[0][:name]).to eq 'copy_files'
        expect(result[1][:name]).to eq 'send_notifications'
      end

      it 'should add pipeline to Env' do
        DeploymentPipeline.create(template: true, name: 'P1')
        DeploymentPipeline.create(template: true, name: 'P2')

        payload = [{
          name: 'P1'
        }, {
          name: 'P2'
        }]

        post '/application/WEBv1/envs/dev/pipelines', payload.to_json

        expect(last_response).to be_ok

        a = Application.find_by_name('WEBv1')
        e = a.envs.find_by_name('dev')

        expect(e.pipelines.length).to eq 4
        expect(e.pipelines[2].name).to eq 'P1'
        expect(e.pipelines[2].template).to eq false
        expect(e.pipelines[3].name).to eq 'P2'
        expect(e.pipelines[3].template).to eq false
      end

      it 'should remove pipeline from env' do
        delete '/application/WEBv1/envs/dev/pipelines/send_notifications'

        expect(last_response.status).to eq 202

        a = Application.find_by_name('WEBv1')
        e = a.envs.find_by_name('dev')

        expect(e.pipelines.length).to eq 1
      end

      it 'should return 404 when pipeline does not exists' do
        delete '/application/WEBv1/envs/dev/pipelines/not%20exists'

        expect(last_response.status).to eq 404
      end

      it 'should reorder pipeline' do
        DeploymentPipeline.create(template: true, name: 'P1')
        DeploymentPipeline.create(template: true, name: 'P2')

        payload = [{
          name: 'P1'
        }, {
          name: 'P2'
        }]

        post '/application/WEBv1/envs/dev/pipelines', payload.to_json
        put '/application/WEBv1/envs/dev/pipelines/P2/order/move_to_top'

        expect(last_response.status).to eq 202

        a = Application.find_by_name('WEBv1')
        e = a.envs.find_by_name('dev')

        expect(e.pipelines.first.name).to eq 'P2'
      end
    end
  end

  describe 'Hosts' do
    it 'should add Host to env' do
      properties = {
        name: 'host-3',
        fqdn: 'testowyhost-3.com',
        ip: '127.0.0.3'
      }

      post '/application/WEBv1/envs/dev/hosts', properties.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      app = Application.find_by_name('WEBv1')
      env = app.envs.find_by_name('dev')

      expect(env.hosts.length).to eq 3
    end

    it 'should not add any hosts if any of them already exists' do
      payload = [
        {
          name: 'should_not_exist',
          fqdn: 'should_not_exist.com',
          ip: '127.0.0.1'
        },
        {
          name: 'host-1',
          fqdn: 'testowyhost-1.com',
          ip: '127.0.0.1'
        },
        {
          name: 'should_not_exist_too',
          fqdn: 'should_not_exist_too.com',
          ip: '127.0.0.1'
        }
      ]

      post '/application/WEBv1/envs/dev/hosts', payload.to_json, 'CONTENT_TYPE': 'application/json'
      expect(last_response.status).to eq 409

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:conflicts]).to match_array ['testowyhost-1.com']

      app = Application.find_by_name('WEBv1')

      env = app.envs.find_by_name('dev')
      expect(env.hosts.map(&:fqdn)).not_to include 'should_not_exist.com'
      expect(env.hosts.map(&:fqdn)).not_to include 'should_not_exist_too.com'
    end

    it 'should get hosts from env' do
      get '/application/WEBv1/envs/dev/hosts'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result).to include(id: 1, name: 'host-1', fqdn: 'testowyhost-1.com', ip: '127.0.0.1')
      expect(result).to include(id: 2, name: 'host-2', fqdn: 'testowyhost-2.com', ip: '127.0.0.2')
    end

    it 'should delete host from env' do
      env = Application.find_by_name('WEBv1').envs.find_by_name('dev')
      delete '/application/WEBv1/envs/dev/hosts/testowyhost-1.com'

      expect(last_response.status).to eq 202

      app = Application.find_by_name('WEBv1')
      env = app.envs.find_by_name('dev')

      expect(env.hosts.length).to eq 1
      expect(env.hosts.first.fqdn).to eq 'testowyhost-2.com'
    end

    it 'should return 404 when host for delete does not exists' do
      delete '/application/WEBv1/envs/dev/hosts/not%20exists'

      expect(last_response.status).to eq 404

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Host "not exists" for Env "dev" does not exists.'
    end

    it 'should add Credential to host by name' do
      credential = Credential.first

      put "/application/WEBv1/envs/dev/hosts/testowyhost-1.com/credential/#{URI.encode_www_form_component(credential.name)}"

      expect(last_response.status).to eq 202

      app = Application.find_by_name('WEBv1')
      env = app.envs.find_by_name('dev')
      host = env.hosts.find_by_fqdn('testowyhost-1.com')

      expect(host.credential).to eq credential
    end

    it 'should return 404 when Credential does not exists' do
      put '/application/WEBv1/envs/dev/hosts/testowyhost-1.com/credential/not%20exists'

      expect(last_response.status).to eq 404

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Credential "not exists" does not exists.'
    end

    it 'should return Credential for host' do
      app = Application.find_by_name('WEBv1')
      env = app.envs.find_by_name('dev')
      host = env.hosts.find_by_fqdn('testowyhost-1.com')
      host.credential = Credential.second

      get '/application/WEBv1/envs/dev/hosts/testowyhost-1.com/credential'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:name]).to eq 'credential2'
    end
  end

  describe 'Listing applications' do
    it 'should list applications' do
      get '/application/'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 2

      app = result[0]
      expect(app[:id]).to eq 1
      expect(app[:name]).to eq 'WEBv1'
      expect(app[:created_at]).not_to be_nil
      expect(app[:updated_at]).not_to be_nil
      expect(app[:versions]).to be_an(Array)
      expect(app[:versions].length).to eq 2
    end

    it 'should list applications with envs' do
      get '/application/?include=envs'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 2

      app = result[0]
      expect(app[:envs]).to be_an(Array)
      expect(app[:envs].length).to eq 3

      expect(app[:envs]).to include(include(id: 3, name: 'prod'))
      expect(app[:envs]).to include(include(id: 2, name: 'uat'))
      expect(app[:envs]).to include(include(id: 1, name: 'dev'))
    end
  end

  describe 'Releases' do
    describe 'Orders' do
      it 'should return orders where release is open by default' do
        get '/application/WEBv1/orders'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 4
      end

      it 'should return all orders for application where release is open or closed when includeClosedReleases is given' do
        get '/application/WEBv1/orders?includeClosedReleases=true'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 5
      end

      it 'should return releases for application with release order results' do
        get '/application/WEBv1/orders?include=release_order_results'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result[0][:release_order_results].length).to eq 2
      end

      it 'should return releases for application and a given date range' do
        start_date = (Time.now - 2.days).strftime('%Y-%m-%d')
        end_date = (Time.now + 1.days).strftime('%Y-%m-%d')

        get "/application/WEBv1/orders?start_date=#{start_date}&end_date=#{end_date}"
        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 2

        expect(result[0][:name]).to eq 'Release order 2'
        expect(result[1][:name]).to eq 'Release order for second release'
      end

      it 'should return orders filtered by release name' do
        get '/application/WEBv1/orders?release=Second%20release%20for%20tests'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 1
      end

      it 'should return orders filtered by given string' do
        get '/application/WEBv1/orders?q=second'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 1
        expect(result[0][:name]).to eq 'Release order for second release'
      end

      it 'should return orders filtered by status' do
        get '/application/WEBv1/orders?status=deployed'

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 1
      end
    end

    it 'should return releases count per env' do
      get '/application/WEBv1/envs/dev/results/count'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:count]).to eq 2
    end

    it 'should return upcoming releases' do
      get '/application/WEBv1/orders/upcoming'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:count]).to eq 4
      expect(result[:date]).to be_a(String)
    end

    it 'should return releases grouped by env' do
      get '/application/WEBv1/results/by_env'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:dev][:count]).to eq 2
      expect(result[:dev][:status][:success]).to eq 1
      expect(result[:dev][:status][:failure]).to eq 1

      expect(result[:uat][:count]).to eq 2
      expect(result[:uat][:status][:failure]).to eq 2

      expect(result[:prod][:count]).to eq 1
      expect(result[:prod][:status][:success]).to eq 1
    end

    it 'should not throw when there are no release order results for by env' do
      Application.create!(name: 'new_application')

      get '/application/new_application/results/by_env'

      expect(last_response).to be_ok
    end
  end

  describe 'Envs orders' do
    it 'should return orders for env for open releases' do
      get '/application/WEBv1/envs/dev/orders'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result.length).to eq 4
    end

    it 'should return orders for env for all releases when includeClosedReleases param is given' do
      get '/application/WEBv1/envs/dev/orders?includeClosedReleases=true'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result.length).to eq 5
    end
  end

  describe 'Envs properties' do
    it 'should add properties for given Application and Env' do
      a = Application.find_by_name('WEBv1')
      dev_env = a.envs.find_by_name('dev')

      properties = {
        'property1' => 'value1',
        'property2' => 'value2'
      }
      post '/application/WEBv1/envs/dev/properties', properties.to_json

      expect(last_response.status).to eq 201
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      expect(PROPERTIES_STORE[dev_env.properties_key]).to eq properties
    end

    it 'should return properties for given Application and Env' do
      a = Application.find_by_name('WEBv1')
      dev_env = a.envs.find_by_name('dev')

      properties = {
        'property41' => 'value41'
      }
      PROPERTIES_STORE[dev_env.properties_key] = properties

      get '/application/WEBv1/envs/dev/properties'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result['property41']).to eq 'value41'
    end
  end

  describe 'errors' do
    it 'should return 404 when Application does not exists' do
      get '/application/not%20exists'

      expect(last_response.status).to eq 404
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:msg]).to eq 'Application with name "not exists" does not exists.'
    end
  end

  describe 'events' do
    it 'should add and return all Events for given Env' do
      event = {
        data: 'some data that could be anything'
      }
      post '/application/WEBv1/envs/dev/events?severity=major&eventType=devel&source=teamcity', event.to_json

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      expect(Event.all.length).to eq 1

      get '/application/WEBv1/envs/dev/events'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)

      event = result[0]
      expect(event[:data]).to eq 'some data that could be anything'
      expect(event[:severity]).to eq 'major'
      expect(event[:event_type]).to eq 'devel'
      expect(event[:source]).to eq 'teamcity'
    end

    describe 'select actions' do
      it 'should trigger action from query string' do
        env = Env.find_by_name('dev')
        env.env_actions.create!(name: 'A', data: { run_by_service: 'A' })
        env.env_actions.create!(name: 'B', data: { run_by_service: 'B' })
        env.env_actions.create!(name: 'C', data: { run_by_service: 'C' })

        event = {
          data: 'some data that could be anything'
        }
        post '/application/WEBv1/envs/dev/events?actions=B', event.to_json

        expect(last_response.status).to eq 201

        expect(AService.called).to be false
        expect(BService.called).to be true
        expect(CService.called).to be false
      end

      it 'should trigger actions from query string' do
        env = Env.find_by_name('dev')
        env.env_actions.create!(name: 'A', data: { run_by_service: 'A' })
        env.env_actions.create!(name: 'B', data: { run_by_service: 'B' })
        env.env_actions.create!(name: 'C', data: { run_by_service: 'C' })

        event = {
          data: 'some data that could be anything'
        }
        post '/application/WEBv1/envs/dev/events?actions[]=A&actions[]=B', event.to_json

        expect(last_response.status).to eq 201

        expect(AService.called).to be true
        expect(BService.called).to be true
        expect(CService.called).to be false
      end
    end
  end

  describe 'env actions' do
    it 'should add and return all Env Actions for given Env' do
      data_json = { run_by_service: 'db_journal', enabled: true }.to_json
      env_action = {
        name: 'some action',
        data: data_json,
        status: 'disabled',
        description: 'some description'
      }
      post '/application/WEBv1/envs/dev/env_actions', env_action.to_json

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      expect(EnvAction.all.length).to eq 1

      get '/application/WEBv1/envs/dev/env_actions'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)
      env_action = result[0]
      expect(env_action[:data]).to eq data_json
      expect(env_action[:name]).to eq 'some action'
      expect(env_action[:status]).to eq 'disabled'
      expect(env_action[:description]).to eq 'some description'
    end
  end
end
