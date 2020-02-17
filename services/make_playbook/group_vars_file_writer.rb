class GroupVarsFileWiter < PutitService
  def initialize(base_dir, release_order)
    super
    @base_dir = base_dir
    @release_order = release_order
  end

  def <<(application_with_version)
    @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    make_group_and_host_vars!(application_with_version)
    make_artifacts_yml!(application_with_version)
    make_properties_yml_files!(application_with_version)
    make_credential_vars_yml_files!(application_with_version)
  end

  private

  def make_group_and_host_vars!(application_with_version)
    @roavw.envs.each do |env|
      logger.debug("Creating dirs: group_vars/all and host_vars for host: #{application_with_version.inspect}")
      group_vars_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'group_vars')
      host_vars_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'host_vars')
      group_vars_all_dir = File.join(group_vars_dir, 'all')
      PutitService.make_dir(group_vars_dir)
      PutitService.make_dir(host_vars_dir)
      PutitService.make_dir(group_vars_all_dir)
      logger.debug("Done creating dirs: group_vars/all and host_vars for host: #{application_with_version.inspect}")
    end
  end

  def make_artifacts_yml!(application_with_version)
    @roavw.envs.each do |env|
      group_vars_all_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'group_vars/all')
      artifacts_yml = File.join(group_vars_all_dir, 'artifacts.yml')
      logger.debug('Saving file with artifacts information: artifacts_yml')

      artifacts = application_with_version.artifact_with_versions.each_with_object({}) do |avw, acc|
        properties = PROPERTIES_STORE.fetch(avw.properties_key, {})
        acc[avw.artifact.full_name] = avw.serializable_hash.merge('properties' => properties)
      end

      data = {
        'artifacts' => artifacts
      }

      begin
        File.open(artifacts_yml, 'w') do |f|
          f.puts(data.to_yaml)
        end
      rescue StandardError => e
        raise PutitExceptions::MakePlaybookServiceError, "Unable to write artifacts.yml file under the path: #{artifacts_yml} due to error: #{e.message}"
      end
      logger.debug('Saved file with artifacts information: artifacts_yml')
    end
  end

  def make_properties_yml_files!(application_with_version)
    roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    roavw.envs.each do |env|
      group_vars_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'group_vars')
      properties = PROPERTIES_STORE.load(env.properties_key)
      next if properties.nil?

      group_dir_all = File.join(group_vars_dir, 'all')
      logger.debug("Saving file with application-env properties under: #{group_dir_all}")
      begin
        File.open(File.join(group_dir_all, 'properties.yml'), 'w') do |f|
          f.puts(properties.to_yaml)
        end
      rescue StandardError => e
        raise PutitExceptions::MakePlaybookServiceError, "Unable to write application properties file under the path: \"#{group_dir_all}/properties.yml\" due to error: #{e.message}"
      end
      logger.debug("Saved file with application-env properties under: #{group_dir_all}")
    end
  end

  def make_credential_vars_yml_files!(application_with_version)
    roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    roavw.envs.each do |env|
      group_vars_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'group_vars')
      host_vars_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'host_vars')
      application = roavw.application_with_version.application
      group_dir_all = File.join(group_vars_dir, 'all')

      # write deploy user and public key path to group_vars/group-name/credential_vars.yml
      credential_vars = File.join(group_dir_all, 'credential_vars.yml')
      logger.debug("Saving credential_vars file: #{credential_vars} for #{env.name}-#{application.dir_name}")

      if env.credential
        data = {
          'ansible_ssh_user' => env.credential.depuser.username.to_s,
          'putit_ansible_ssh_deploy_user' => env.credential.depuser.username.to_s,
          'putit_ansible_ssh_deploy_public_key_file' => "./keys/#{env.credential.get_env_public_key_filename(env, application)}",
          'ansible_ssh_private_key_file' => "./keys/#{env.credential.get_env_private_key_filename(env, application)}"
        }
      end

      begin
        File.open(credential_vars, 'w') do |f|
          f.write(YAML.dump(data))
        end
      rescue StandardError => e
        raise PutitExceptions::MakePlaybookServiceError, "Unable to wrtie group_vars file at: #{credential_vars} due to error: #{e.message}"
      end
      logger.debug("Saved credential_vars file: #{credential_vars} for #{env.name}-#{application.dir_name}")

      # write deploy user and public key path to host_vers/fqdn/credentials_vars.yml if they are set for such host
      save_credentials_for_hosts(env, application, host_vars_dir)
    end
  end

  def save_credentials_for_hosts(env, application, host_vars_dir)
    env.hosts.map do |host|
      logger.debug("Looking for host credentials for host: #{host.inspect}")
      next unless host.credential

      host_dir = File.join(host_vars_dir, host.fqdn)
      credential_vars = File.join(host_dir, 'credential_vars.yml')
      logger.debug("Saving credetial_vars file for host: #{host.inspect} into file: #{credential_vars}")

      data = {
        'ansible_ssh_user' => host.credential.depuser.username.to_s,
        'putit_ansible_ssh_deploy_user' => host.credential.depuser.username.to_s,
        'putit_ansible_ssh_deploy_public_key_file' => "./keys/#{host.credential.get_host_public_key_filename(env, host, application)}",
        'ansible_ssh_private_key_file' => "./keys/#{host.credential.get_host_private_key_filename(env, host, application)}"
      }

      begin
        FileUtils.mkdir_p host_dir
        File.open(credential_vars, 'w') do |f|
          f.write(YAML.dump(data))
        end
      rescue StandardError => e
        raise PutitExceptions::MakePlaybookServiceError, "Unable to wrtie host_vars file at: #{credential_vars} due to error: #{e.message}"
      end
      logger.debug("Saved credetial_vars file for host: #{host.inspect} into file: #{credential_vars}")
    end
  end
end
