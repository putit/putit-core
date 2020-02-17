class CredentialFileWriter < PutitService
  def initialize(base_dir, release_order)
    super
    @base_dir = base_dir
    @release_order = release_order
  end

  def <<(application_with_version)
    @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    save_env_keys!(application_with_version)
    save_host_keys!(application_with_version)
  end

  private

  def save_env_keys!(application_with_version)
    @release_order.release_order_application_with_versions.each do |roavw|
      roavw.envs.each do |env|
        keys_directory = File.join(@base_dir, application_with_version.dir_name, env.name, 'keys')
        next unless env.credential

        private_key_file = File.join(keys_directory, env.credential.get_env_private_key_filename(env, application_with_version.application))
        public_key_file = File.join(keys_directory, env.credential.get_env_public_key_filename(env, application_with_version.application))

        begin
          PutitService.make_dir(keys_directory)
          File.open(private_key_file, 'w') do |f|
            f.puts(env.credential.sshkey.private_key)
          end
          File.open(public_key_file, 'w') do |f|
            f.puts(env.credential.sshkey.ssh_public_key)
          end
        rescue StandardError => e
          raise PutitExceptions::MakePlaybookServiceError, "Unable save env credential ssh keys to #{@keys_directory} due to: #{e.message}"
        end
        FileUtils.chmod 0o600, private_key_file
      end
    end
  end

  def save_host_keys!(application_with_version)
    @release_order.release_order_application_with_versions.each do |roavw|
      roavw.envs.each do |env|
        keys_directory = File.join(@base_dir, application_with_version.dir_name, env.name, 'keys')
        env.hosts.each do |host|
          next unless host.credential

          private_key_file = File.join(keys_directory, host.credential.get_host_private_key_filename(env, host, application_with_version.application))
          public_key_file = File.join(keys_directory, host.credential.get_host_public_key_filename(env, host, application_with_version.application))
          begin
            PutitService.make_dir(keys_directory)
            File.open(private_key_file, 'w') do |f|
              f.puts(host.credential.sshkey.private_key)
            end
            File.open(public_key_file, 'w') do |f|
              f.puts(host.credential.sshkey.ssh_public_key)
            end
          rescue StandardError => e
            raise PutitExceptions::MakePlaybookServiceError, "Unable to save host credential ssh keys to #{keys_directory} due to: #{e.message}"
          end
          FileUtils.chmod 0o600, private_key_file
        end
      end
    end
  end
end
