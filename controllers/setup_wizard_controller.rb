class SetupWizardController < SecureController

  post '/apply' do
    application_service = ApplicationService.new
    credential_service = CredentialService.new

    payload = JSON.parse(request.body.read, symbolize_names: true)

    results = {
      application: [],
      envs: [],
      hosts: [],
      credentials: []
    }

    conflicts = {
      application: [],
      envs: [],
      hosts: [],
      credentials: []
    }

    errors = {
      application: [],
      envs: [],
      hosts: [],
      credentials: []
    }

    Application.transaction do
      app = nil
      begin
        app = application_service.add_application(payload[:application])
        results[:application].push(application_id: app.id)
      rescue ActiveRecord::RecordInvalid
        conflicts[:application] = ['name']
        raise ActiveRecord::Rollback
      end

      envs_result, envs_conflicts = application_service.add_envs(
        app, payload[:envs]
      )

      conflicts[:envs].push(*envs_conflicts)
      raise ActiveRecord::Rollback unless conflicts[:envs].empty?

      results[:envs] = envs_result

      payload[:hosts].each do |env, hosts|
        hosts_results, hosts_conflicts, hosts_errors = application_service.add_hosts(
          app, env, hosts, raise_on_errors = false
        )

        results[:hosts].push(*hosts_results)
        conflicts[:hosts].push(*hosts_conflicts)
        errors[:hosts].push(*hosts_errors)
      end

      raise ActiveRecord::Rollback unless conflicts[:hosts].empty?

      payload[:credentials].each do |env_name, user_name|
        Application.transaction do
          key_name = [app.name, env_name, user_name].join('-')

          begin
            ssh_key = credential_service.add_dep_ssh_key(
              bits: 2048,
              comment: 'Generated by setup wizard',
              name: key_name,
              type: 'RSA'
            )
          rescue ActiveRecord::RecordInvalid
            conflicts[:credentials].push('ssh_key')
            raise ActiveRecord::Rollback
          end

          begin
            depuser = credential_service.add_depuser(username: user_name)
          rescue ActiveRecord::RecordInvalid
            conflicts[:credentials].push('user')
          end

          begin
            credential = credential_service.add_depuser_credential(
              depuser, 'credential_' + key_name, ssh_key
            )
          rescue ActiveRecord::RecordInvalid
            conflicts[:credentials].push('credential')
          end

          env = app.envs.find_by_name(env_name)
          env.credential = credential

          results[:credentials].push(credential_id: credential.id)
        end
      end

      raise ActiveRecord::Rollback unless conflicts[:credentials].empty?
    end

    unless conflicts.all? { |_key, value| value.empty? }
      status(409)
      return {
        status: 'conflict',
        msg: 'Conflict',
        conflicts: conflicts
      }.to_json
    end

    unless errors.all? { |_key, value| value.empty? }
      status(400)
      return {
        status: 'error',
        msg: 'Validation error',
        errors: errors
      }.to_json
    end

    status(200)
    return {
      status: 'success',
      results: results
    }.to_json
  end
end
