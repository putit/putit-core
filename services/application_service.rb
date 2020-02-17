class ApplicationService < PutitService
  def add_application(payload)
    app = Application.find_or_create_by!(name: payload[:name])

    if payload[:version]
      app.versions.find_or_create_by!(version: payload[:version])
    end

    logger.info(
      "Application #{payload[:name]} with #{payload[:version]} added."
    )

    app
  end

  def add_envs(application, payload)
    result = []
    conflicts = []

    Array.wrap(payload).each do |env|
      Application.transaction do
        begin
          e = application.envs.create!(name: env[:name])
          result.push(env_id: e.id)
        rescue ActiveRecord::RecordInvalid
          conflicts.push(env[:name])
          raise ActiveRecord::Rollback
        end
        default_properties = {
          'putit_app_name' => application.name,
          'putit_env_name' => e.name
        }
        PROPERTIES_STORE[e.properties_key] = default_properties
      end
    end

    [result, conflicts]
  end

  def add_hosts(application, env_name, payload, raise_on_errors = true)
    result = []
    errors = []
    conflicts = []

    Array.wrap(payload).map do |host|
      Application.transaction do
        begin
          unless FQDN_REGEX.match(host[:fqdn])
            error = "Host FQDN \"#{host[:fqdn]}\" does not match regex: #{FQDN_REGEX}."
            if raise_on_errors
              request_halt(error, 400)
            else
              errors.push(fqdn: host[:fqdn], error: error)
              return
            end
          end

          unless host[:ip]
            begin
              host[:ip] = Resolv::DNS.new.getaddress(host[:fqdn]).to_s
            rescue StandardError
              error = "DNS has no information for \"#{host[:fqdn]}\""
              if raise_on_errors
                raise PutitExceptions::HostDNSError
              else
                errors.push(ip: host[:ip], error: error)
                return
              end
            end
          end

          env = application.envs.find_by_name(env_name)

          host = env.hosts.create!(
            name: host[:name], fqdn: host[:fqdn], ip: host[:ip]
          )

          logger.info("Added #{host.inspect} to env: #{env.name}")
          result.push(host_id: host.id)
        rescue ActiveRecord::RecordInvalid
          conflicts.push(host[:fqdn])
          raise ActiveRecord::Rollback
        end
      end
    end

    [result, conflicts, errors]
  end
end
