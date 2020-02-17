class DeploymentYmlFileWriter < PutitService
  def initialize(base_dir, release_order)
    super
    @base_dir = base_dir
    @release_order = release_order
  end

  def <<(application_with_version)
    make_deployment_yml_files!(application_with_version)
  end

  private

  def make_deployment_yml_files!(application_with_version)
    @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    envs = @roavw.release_order_application_with_version_envs.map(&:env)

    envs.each do |env|
      logger.debug("Writing deployment file for env: #{env.name}")
      pipes = env.pipelines
      if pipes.empty?
        raise PutitExceptions::MakePlaybookServiceError, "Unable to create playbook deployment file as there are no deployment pipelines for this env: #{env.name}"
      end

      application_env_dir = File.join(@base_dir, application_with_version.dir_name, env.name)
      pipes.each_with_index do |pipeline, index|
        deployment_file = File.join(application_env_dir, "#{index}_#{env.name}_pipeline_#{pipeline.name}.yml")
        logger.debug("Creating deployment file: #{deployment_file}")
        hosts_str = set_ansible_hosts(env, application_with_version)

        data = [{
          'name' => "Deploy playbook from pipeline #{pipeline.name} for application: #{application_with_version.application.name} on environment #{env.name}",
          'hosts' => hosts_str,
          'roles' => pipeline.steps.map { |step| "#{pipeline.name}/#{step.name}" }
        }]
        begin
          logger.info("Writing deployment file with content: #{data.inspect} ")
          File.open(deployment_file, 'w') do |f|
            f.write(YAML.dump(data))
          end
          logger.debug("Created playbook file: #{deployment_file}")
        rescue StandardError => e
          raise PutitExceptions::MakePlaybookServiceError, "Unable to create playbook file at: #{deployment_file} due to error: #{e.message}"
        end
      end
    end
  end

  private

  def set_ansible_hosts(env, application_with_version)
    properties = PROPERTIES_STORE.fetch(env.properties_key, {})
    # by default run on some inventory where would be FQDN of servers
    hosts_str = 'all'
    if env.aws_tags
      hosts_str = env.aws_tags
    elsif (properties['putit_deploy_run_local'] == 1) || (properties['putit_deploy_run_local'] == true)
      hosts_str = 'localhost'
    end

    logger.debug("Host has been set to: #{@hosts} for env: #{env.name} and #{application_with_version.application.name}")
    hosts_str
  end
end
