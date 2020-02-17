describe SetupWizardController do
  describe '/apply' do
    it 'should not apply the settings if an env is duplicate' do
      payload = {
        application: {
          name: 'WEBv1'
        },
        envs: [
          { name: 'dev' }, { name: 'uat2' }, { name: 'prod2' }
        ],
        hosts: {
          dev: [
            name: 'dev.myapp.lan',
            fqdn: 'dev.myapp.lan',
            ip: '127.0.0.1'
          ],
          uat: [
            name: 'uat.myapp.lan',
            fqdn: 'uat.myapp.lan',
            ip: '127.0.0.1'
          ],
          prod: [
            name: 'prod.myapp.lan',
            fqdn: 'prod.myapp.lan',
            ip: '127.0.0.1'
          ]
        },
        credentials: {
          dev: 'myapp',
          uat: 'myapp',
          prod: 'myapp'
        }
      }

      post(
        '/setup_wizard/apply',
        payload.to_json,
        'CONTENT_TYPE': 'application/json'
      )

      expect(last_response.status).to eq 409

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:conflicts][:application].length).to eq 0
      expect(result[:conflicts][:envs]).to eq ['dev']
      expect(result[:conflicts][:hosts].length).to eq 0
      expect(result[:conflicts][:credentials].length).to eq 0
    end

    it 'should apply the settings' do
      payload = {
        application: {
          name: 'SetupWizardApplication'
        },
        envs: [
          { name: 'dev' }, { name: 'uat' }, { name: 'prod' }
        ],
        hosts: {
          dev: [
            name: 'dev.myapp.lan',
            fqdn: 'dev.myapp.lan',
            ip: '127.0.0.1'
          ],
          uat: [
            name: 'uat.myapp.lan',
            fqdn: 'uat.myapp.lan',
            ip: '127.0.0.1'
          ],
          prod: [
            name: 'prod.myapp.lan',
            fqdn: 'prod.myapp.lan',
            ip: '127.0.0.1'
          ]
        },
        credentials: {
          dev: 'myapp',
          uat: 'myapp',
          prod: 'myapp'
        }
      }

      post(
        '/setup_wizard/apply',
        payload.to_json,
        'CONTENT_TYPE': 'application/json'
      )

      expect(last_response.status).to eq 200

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:results][:application].length).to eq 1

      app = Application.find_by_id(result[:results][:application][0][:application_id])

      app_envs = app.envs.sort_by(&:id).map do |env|
        { name: env.name }
      end

      app_hosts = {}
      app.envs.each do |env|
        app_hosts[env.name.to_sym] = env.hosts.map do |host|
          {
            name: host.name,
            fqdn: host.fqdn,
            ip: host.ip
          }
        end
      end

      app_credentials = {}
      app.envs.each do |env|
        app_credentials[env.name.to_sym] = env.credential.depuser.username
      end

      expect(app.name).to eq payload[:application][:name]
      expect(app_envs).to eq payload[:envs]
      expect(app_hosts).to eq payload[:hosts]
      expect(app_credentials).to eq payload[:credentials]
    end
  end
end
