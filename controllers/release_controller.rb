class ReleaseController < SecureController
  helpers Sinatra::Streaming

  before '/*' do
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    logger.debug("Requests for release: \"#{name}\"")
    @release = Release.find_by_name(name)

    if @release.nil?
      request_halt("Release with name \"#{name}\" does not exists.", 404)
    end
  end

  before '/:name/dependent-releases/*' do
    subname = params['splat'][0].split('/')[0]
    @subrelease = Release.find_by_name(subname)

    if @subrelease.nil?
      request_halt("Release with name \"#{subname}\" doesn't exists.", 404)
    end
  end

  before '/:name/orders/*' do
    release_order_name = params['splat'][0].split('/')[0]
    @release_order = @release.release_orders.find_by_name(release_order_name)

    if @release_order.nil?
      request_halt("Release Order with name \"#{release_order_name}\" does not exists.", 404)
    end
  end

  ['/:name/orders/:order_name/applications/*', '/:name/orders/:order_name/status/*', '/:name/orders/:order_name/results/*'].each do |path|
    before path do
      app_name, version, __, env_name = params['splat'][0].split('/')

      @application = Application.find_by_name(app_name)
      if @application.nil?
        request_halt("Application with name \"#{app_name}\" does not exists.", 404)
      end

      return if version.nil?

      @avw = @application.versions.find_by_version(version)
      if @avw.nil?
        request_halt("Application has no version: \"#{version}\".", 404)
      end

      @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(@avw.id)
      if @roavw.nil?
        request_halt("Application \"#{app_name}\" in version \"#{version}\" hasn't been added to Release Order \"#{@release_order.name}\"", 404)
      end

      unless env_name.nil?
        @app_env = @application.envs.find_by_name(env_name)
        if @app_env.nil?
          request_halt("Env \"#{env_name}\" hasn't been added to Application \"#{app_name}\"", 404)
        end

        @env_for_release_order = @roavw.release_order_application_with_version_envs.find_by_env_id(@app_env.id)
        if @env_for_release_order.nil?
          request_halt("Env \"#{env_name}\" hasn't been added to Application \"#{app_name}\" in version \"#{version}\" in Release Order \"#{@release_order.name}\"", 404)
        end
      end
    end
  end

  before '/:name/orders/:order_name/results/:application_name/:version/envs/:env/*' do
    @result = @release_order.release_order_results.where(release_order_id: @release_order.id, env_id: @env_for_release_order.env.id, application_id: @application.id, application_with_version_id: @avw.id).first
    if @result.nil?
      request_halt("Results for release order with name \"#{@release_order.name}\" for application: \"#{@application.name}\" in version \"#{@avw.version}\" for env: \"#{@app_env.name}\" does not exists.", 404)
    end
  end

  get '/' do
    param :includeClosedReleases, Boolean, required: false, raise: true

    if params[:includeClosedReleases] == true
      Release.all.to_json
    else
      Release.open.to_json
    end
  end

  post '/' do
    json = JSON.parse(request.body.read, symbolize_names: true)

    release = Release.find_by_name(json[:name])
    if release.nil?
      status 201
      Release.create!(json)
    else
      request_halt("Release with name \"#{json[:name]}\" exists.", 409)
    end
  end

  get '/:name' do |_name|
    @release.to_json
  end

  delete '/:name' do
    status 202
    @release.destroy

    { status: 'ok' }.to_json
  end

  get '/:name/status' do |_name|
    status 201

    @release.status.to_json
  end

  patch '/:name/status' do |_name|
    status 202
    s = JSON.parse(request.body.read, symbolize_names: true)

    @release.validate_status(s[:status])
    @release.update!(status: s[:status])
    @release.to_json
  end

  put '/:name/dependent-releases/:subname' do |_name, _subname|
    Subrelease.create!(release_id: @release.id, subrelease_id: @subrelease.id)

    status 202
    { status: 'ok' }.to_json
  end

  delete '/:name/dependent-releases/:subname' do |_name, _subname|
    Subrelease.where(release_id: @release.id, subrelease_id: @subrelease.id).destroy_all

    status 202
    { status: 'ok' }.to_json
  end

  get '/:name/orders' do
    param :status,     String, in: ReleaseOrder.statuses.map(&:first), required: false, raise: true
    param :upcoming,   Boolean, required: false, raise: true

    @release.get_orders(params).to_json
  end

  post '/:name/orders' do |name|
    status 201

    json = JSON.parse(request.body.read, symbolize_names: true)

    if @release.closed?
      request_halt("Release with name \"#{name}\" is closed, can't add change to it.", 403)
    else
      ro = @release.release_orders.find_by_name(json[:name])
      if ro.nil?
        @release.release_orders.create!(json)
        status 201
      else
        request_halt("Release Order with name \"#{json[:name]}\" exists.", 409)
      end
    end
    { status: 'ok' }.to_json
  end

  get '/:name/orders/:order_name' do |_name, _order_name|
    @release_order.to_json
  end

  delete '/:name/orders/:order_name' do |_name, _order_name|
    status 202
    @release_order.destroy

    { status: 'ok' }.to_json
  end

  get '/:name/orders/:order_name/status' do
    @release_order.status.to_json
  end

  get '/:name/orders/:order_name/applications' do |_name, _order_name|
    @release_order.application_with_versions.to_json
  end

  delete '/:name/orders/:order_name/applications/:application_name' do |_name, _order_name, _application_name|
    @release_order.application_with_versions.where(application_id: @application.id).each do |avw|
      roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(avw.id)
      roavw.destroy!
    end

    status 202
    { status: 'ok' }.to_json
  end

  post '/:name/orders/:order_name/applications' do |_name, order_name|
    status 201

    applications_with_version = JSON.parse(request.body.read, symbolize_names: true)

    applications_with_version.each do |app|
      app_name = app[:application_name]
      a = Application.find_by_name(app_name)
      if a.nil?
        request_halt("Application with name #{app_name} does not exists.", 404)
      end
      version_name = app[:version_name]
      avw = ApplicationWithVersion.find_by_application_id_and_version(a.id, version_name)
      if avw.nil?
        request_halt("Application with name #{app_name} does not have version: #{version_name}", 404)
      end

      if @release.closed?
        request_halt("Cannot add Application \"#{app_name}\" to Release order \"#{order_name}\" which belongs to closed Release \"#{@release.name}\"", 403)
      end

      ReleaseOrderApplicationWithVersion.find_or_create_by!(release_order_id: @release_order.id, application_with_version_id: avw.id)
    end

    { status: 'ok' }.to_json
  end

  # dry run - only generate
  get '/:name/orders/:order_name/generate_deploy_playbook' do |_name, order_name|
    logger_data = { current_user: RequestStore.read(:current_user), request_id: RequestStore.read(:request_id) }
    envs = params[:envs] || []
    o = @release.release_orders.find_by_name(order_name)
    begin
      MakePlaybookService.new(o, logger_data).make_playbook!
    rescue Errno::ENOENT, Errno::ENOSPC, Errno::EACCES => e
      log_msg = "Deployment has failed. Unable to generate deployment playbook for change: #{o.name} due to error: #{e.message}."
      request_halt(log_msg, 500)
    end
  end

  get '/:name/orders/:order_name/execute' do |_name, order_name|
    response.headers['X-Accel-Buffering'] = 'no'
    content_type 'application/octet-stream'

    param :stream, Boolean, required: false, is: true, raise: true
    stream_to_out = params[:stream] || false

    # request is ended before streams ends. Below is necessary to pass request_id and current_user into logs from services run in stream block.
    logger_data = { current_user: RequestStore.read(:current_user), request_id: RequestStore.read(:request_id) }

    envs = params[:envs] || []
    o = @release.release_orders.find_by_name(order_name)
    begin
      MakePlaybookService.new(o, logger_data).make_playbook!
    # catch only errors which were not catch inside MakePlaybookService
    rescue Errno::ENOENT, Errno::ENOSPC, Errno::EACCES => e
      log_msg = "Unable to generate deployment playbook for change: #{o.name} due to error: #{e.message}."
      request_halt(log_msg, 500)
    else
      logger.info("Deployment playbooks for change: #{@release_order.name} generated.")
    end

    ArchivePlaybookService.new(o, logger_data).run!

    # no request object below
    stream do |out|
      RunPlaybookService.new(o, envs, out, stream_to_out, logger_data).run!
    end
  end

  get '/:name/orders/:order_name/archive' do |name, order_name|
    response.headers['content_type'] = 'application/x-gtar'
    attachment("#{name}_release_order_#{order_name}_playbook.tar.gz")
    response.write(Marshal.load(@release_order.archive))
  end

  put '/:name/orders/:order_name/productionize' do |_name, _order_name|
    if !@release_order.approvals.empty?
      if @release_order.valid_approvals?
        @release_order.approved!
      else
        @release_order.waiting_for_approvals!
        @release_order.send_approval_emails
      end
    else
      @release_order.approved!
    end

    status 204
    { status: 'ok' }.to_json
  end

  post '/:name/orders/:order_name/approvers' do |_name, _order_name|
    approvers = JSON.parse(request.body.read, symbolize_names: true)
    approvers.each do |a|
      u = User.find_by_email(a[:email])
      if u.nil?
        request_halt("Approver with email \"#{a[:email]}\" does not exists.", 404)
      end
      @release_order.approvals.create!(user_id: u.id)
    end

    status 204
    { status: 'ok' }.to_json
  end

  delete '/:name/orders/:order_name/approvers/:email' do |_name, _order_name, _email|
    u = User.find_by_email(params[:email])
    request_halt('Approver with email "email" does not exists.', 404) if u.nil?
    @release_order.approvals.where(user_id: u.id).delete_all

    status 204
    { status: 'ok' }.to_json
  end

  get '/:name/orders/:order_name/applications/:application_name/:version/envs' do
    @roavw.envs.to_json
  end

  post '/:name/orders/:order_name/applications/:application_name/:version/envs' do
    status 201
    json = JSON.parse(request.body.read, symbolize_names: true)

    Array.wrap(json).each do |e|
      env_name = e[:env_name]
      env = @application.envs.find_by_name(env_name)
      if env.nil?
        request_halt("Env \"#{env_name}\" does not exist for application \"#{@application.name}\"", 404)
      elsif @roavw.release_order_application_with_version_envs.exists?(env_id: env.id)
        request_halt("Env \"#{env_name}\" has been already added into \"#{@release_order.name}\" for application: \"#{@application.name}\"", 409)
      else
        @roavw.release_order_application_with_version_envs.create(env_id: env.id)
      end
    end

    { status: 'ok' }.to_json
  end

  delete '/:name/orders/:order_name/applications/:application_name/:version/envs/:env_name' do
    status 202

    roavwe = @roavw.release_order_application_with_version_envs.find_by_id(@env_for_release_order.id)
    roavwe.destroy

    { status: 'ok' }.to_json
  end

  put '/:name/orders/:order_name/results/:application_name/:version/envs/:env' do
    status 202
    json = JSON.parse(request.body.read, symbolize_names: true)
    enums = ReleaseOrderResult.statuses.map(&:first)
    unless enums.include? json[:status]
      raise PutitExceptions::EnumError, "Invalid status: #{json[:status]}, valids are: \"#{enums}\""
    end

    env_name = @app_env.name

    begin
      @release_order.release_order_results.create! do |result|
        result.env_id = @env_for_release_order.env.id
        result.application_id = @application.id
        result.application_with_version_id = @avw.id
        result.status = json[:status].to_sym
      end
    rescue ActiveRecord::RecordNotUnique => e
      log_msg = "Duplication of deploy result for change: #{@release_order.name} for #{@application.name} in version: #{@avw.version} on env: #{env_name}."
      logger.debug(log_msg + 'due to error:' + e.message)
      raise PutitExceptions::DuplicateDeploymentResult, log_msg
    end
    @release_order.deployed!
    logger.info("Set status: #{json[:status]} for #{@application.name} in version: #{@avw.version} on env: #{env_name}")
    { status: 'ok' }.to_json
  end

  get '/:name/orders/:order_name/results/:application_name/:version/envs/:env/status' do
    status 200
    { deploy_status: @result.status.to_s }.to_json
  end

  get '/:name/orders/:order_name/results/:application_name/:version/envs/:env/all' do
    status 200

    log_url = "#{Settings.putit_core_url}/status/#{@application.url_name}/#{@app_env.name}/#{@result.id}/logs"
    {
      release: @result.release_order.release.name,
      change: @result.release_order.name,
      version: @avw.version,
      env: @result.env.name,
      status: @result.status,
      deployment_date: @result.updated_at,
      log_url: log_url
    }.to_json
  end

  get '/:name/orders/:order_name/results/:application_name/:version/envs/:env/logs' do
    param :as_attachment, Boolean, required: false, raise: true

    content_type 'text/plain'
    status 200

    logs = @result.log

    if logs.nil?
      request_halt("No logs for release order with name \"#{@release_order.name}\" for application: \"#{@application.name}\" in version \"#{@avw.version}\" for env: \"#{@app_env.name}\" does not exists.", 404)
    end

    if params[:as_attachment]
      attachment "#{@release.name}_#{@release_order.name}_#{@application.name}_#{@avw.version}_#{@app_env.name}.log"
    end

    logs
  end
end
