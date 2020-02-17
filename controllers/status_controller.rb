class StatusController < SecureController

  ['/:application/:env/*', '/:application/:env'].each do |path|
    before path do 
      app_name, env_name = params.fetch_values('application', 'env')
      @application = Application.find_by_name(app_name)

      if @application.nil?
        request_halt("Application with name \"#{app_name}\" does not exists.", 404)
      end

      @app_env = @application.envs.find_by_name(env_name)

      if @app_env.nil?
        request_halt("Environment with name \"#{env_name}\" does not exists.", 404)
      end
    end
  end

  get '/:application' do
    @deployment_results = []
    @application.envs.each do |app_env|
      @deployment_results << DeploymentStatusService.new.get_deployment_status(@application, app_env)
    end
    @deployment_results.compact.to_json
  end

  get '/:application/:env' do
    DeploymentStatusService.new.get_deployment_status(@application, @app_env).to_json
  end

  get '/:application/:env/:id/logs' do |_app_name, _env_name, ror_id|
    ror = ReleaseOrderResult.where(application_id: @application.id, env_id: @app_env.id).find_by_id(ror_id)

    if ror.nil?
      request_halt("No results for application: #{@application.name} on environment: #{@app_env.name}", 404)
    else
      ror.log
    end
  end
end
