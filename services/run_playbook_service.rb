class RunPlaybookService < PutitService
  def initialize(release_order, envs = [], out = STDERR, stream_to_out = false, logger_data = {})
    super
    @release_order = release_order
    @out = out
    @stream_to_out = stream_to_out
  end

  def run!
    # raise "Release order is not approved!" unless @release_order.approved?
    @release_order.in_deployment!

    logger.info("Deployment of Release Order '#{@release_order.name}' started.")

    dir = @release_order.release.playbook_dir

    @release_order.application_with_versions.to_a.each do |avw|
      @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(avw.id)
      envs = @roavw.release_order_application_with_version_envs.map(&:env)
      envs.each do |env|
        run_dir = File.join(dir, avw.dir_name, env.name)

        Dir.chdir(run_dir) do
          logger.info("Changed directory to: #{run_dir}")

          result = @release_order.release_order_results.create!
          result.env_id = env.id
          result.application_id = avw.application.id
          result.application_with_version_id = avw.id

          log_msg = "Begin of deployment application: #{avw.application.name} in version #{avw.version} onto env: #{env.name}"
          result.log = 'PUTIT ' + log_msg + "\n"
          logger.info(log_msg)

          Dir.glob(get_deployment_pattern(env)).sort.each do |deployment|
            log_msg = "Begin running on env: #{env.name} with deployment file: #{deployment}"
            result.log << 'PUTIT ' + log_msg + "\n"
            logger.info(log_msg)

            args = set_ansible_playbook_args(env, avw, deployment)
            env_variables = set_env_variables(env, avw, result)
            logger.debug("Env variables: \"#{env_variables.inspect}\"")

            begin
              exit_status = -128
              logger.debug("Going to execute command: \"#{args.inspect}\"")
              Open3.popen2e(env_variables, *args) do |_stdin, oe, wait_thread|
                while line = oe.gets
                  @out << line if @stream_to_out == true
                  result.log << line
                  DEPLOY_LOGGER.info(line.rstrip)
                end

                exit_status = wait_thread.value.exitstatus
              end
              log_msg = "Execution result status: #{exit_status}"
              result.log << 'PUTIT ' + log_msg + "\n"
              logger.info(log_msg, raw_log_file: DEPLOY_LOGGER.appenders[0].filename)
              log_msg = "End deployment application: #{avw.application.name} in version #{avw.version} onto env: #{env.name}"
              result.log << 'PUTIT ' + log_msg + "\n\n"
              logger.info(log_msg)

              if exit_status == 0
                result.status = :success
              else
                result.status = :failure
                log_msg = "Deployment has failed for application: #{avw.application.name} in version #{avw.version} on env: #{env.name}, checkout deployment logs for details: #{DEPLOY_LOGGER.appenders[0].filename}."
                logger.error(log_msg)
              end
            rescue StandardError => e
              log_msg = "Deployment has failed for application: #{avw.application.name} in version #{avw.version} on env: #{env.name} due to error: \"#{e.message}\""
              logger.error(log_msg)

              result.status = :failure
            ensure
              result.save!
            end
          end # Dir.glob.each
        end # Dir.chdir
      end # envs.each
    end

    @release_order.deployed!
    logger.info("Deployment of Release Order '#{@release_order.name}' finished.")
  end

  private

  def get_deployment_pattern(env)
    "*#{env.name}*.yml"
  end

  # mange ansible-playbook ruh args
  def set_ansible_playbook_args(env, avw, deployment)
    properties = PROPERTIES_STORE.fetch(env.properties_key, {})
    run_args = ['ansible-playbook']

    if (properties['putit_debug_deploy'] == 1) || (properties['putit_debug_deploy'] == true)
      run_args.push('-vvv')
    end

    # by default run on some inventory where would be FQDN of servers, local run take precedence over run using aws_tags deploy
    if (properties['putit_deploy_run_local'] == 1) || (properties['putit_deploy_run_local'] == true)
      run_args.push('--connection=local')
    elsif env.aws_tags
      begin
       @env_variables = {
         'ANSIBLE_HOSTS' => Settings.putit_ansible_ec2_py_path,
         'EC2_INI_PATH' => Settings.putit_ansible_ec2_ini_path
       }
      rescue StandardError => e
        raise PutitExceptions::MakePlaybookServiceError, "Unable to read 'ANSIBLE_HOSTS' and/or 'EC2_INI_PATH' files defined in settings file."
     end
    else
      run_args.push('-i')
      run_args.push("inventory_#{env.name}")
    end
    run_args.push(deployment)
    logger.debug("Run args has been set to: #{run_args.inspect} for env: #{env.name} and #{avw.application.name}")
    run_args
    run_args = ['echo $PATH']
  end

  # set ENV vars which will be used during the playbok run
  def set_env_variables(env, avw, result)
    env_variables = {
      'PUTIT_APPLICATION' => avw.application.name,
      'PUTIT_APPLICATION_VERSION' => avw.version,
      'PUTIT_ENV' => env.name,
      'PUTIT_RESULT_URL' => "#{Settings.putit_core_url}/deployment/#{URI.escape(avw.application.name)}/#{env.name}/#{result.id}"
      'PATH' => ENV['PATH']
    }
    if env.aws_tags
      begin
        ec2_variables = {
          'ANSIBLE_HOSTS' => Settings.putit_ansible_ec2_py_path,
          'EC2_INI_PATH' => Settings.putit_ansible_ec2_ini_path
        }
        env_variables = env_variables.merge(ec2_variables)
      rescue StandardError => e
        raise PutitExceptions::MakePlaybookServiceError, "Unable to read 'ANSIBLE_HOSTS' and/or 'EC2_INI_PATH' files defined in settings file."
      end
    end
    logger.debug("Env variables set: #{env_variables.inspect}")
    env_variables
  end
end
