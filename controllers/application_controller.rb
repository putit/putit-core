class ApplicationController < SecureController
  include Wisper::Publisher

  before '/*' do
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    @application = Application.find_by_name(name)

    if @application.nil?
      request_halt("Application with name \"#{name}\" does not exists.", 404)
    end
  end

  before '/:name/versions/*' do
    version_name = params['splat'][0].split('/')[0]
    # version is part of application_with_version model - different than in artifact_with_version, where version is separate table/model
    @application_version = @application.versions.find_by_version(version_name)

    if @application_version.nil?
      request_halt("Version \"#{version_name}\" for Application \"#{@application.name}\" does not exists.", 404)
    end
  end

  before '/:name/envs/*' do
    env = params['splat'][0].split('/')[0]
    @env_for_application = @application.envs.find_by_name(env)

    if @env_for_application.nil?
      request_halt("Env \"#{env}\" for Application \"#{@application.name}\" does not exists.", 404)
    end
  end

  before '/:name/envs/:env/hosts/*' do
    fqdn = params['splat'][0].split('/')[0]
    @host = @env_for_application.hosts.find_by_fqdn(fqdn)

    if @host.nil?
      request_halt("Host \"#{fqdn}\" for Env \"#{@env_for_application.name}\" does not exists.", 404)
    end
  end

  before '/:name/envs/:env/events/*' do
    name = params['splat'][0].split('/')[0]
    @event = @env_for_application.events.find_by_(name)

    if @event.nil?
      request_halt("Event \"#{name}\" for Env \"#{@env_for_application.name}\" does not exists.", 404)
    end
  end

  before '/:name/envs/:env/pipelines/*' do
    pipeline = params['splat'][0].split('/')[0]
    @pipeline = @env_for_application.pipelines.find_by_name(pipeline)

    if @pipeline.nil?
      request_halt("Pipeline \"#{pipeline}\" for Env \"#{@env_for_application.name}\" does not exists.", 404)
    end
  end

  before '/:name/envs/:env/properties/*' do
    @properties_key = params['splat'][0].split('/')[0]
    unless PROPERTIES_STORE[@env_for_application.properties_key].key?(@properties_key)
      request_halt("Properties with key \"#{@properties_key}\" for Env \"#{@env_for_application.name}\" does not exists.", 404)
    end
  end

  before '/:name/envs/:env/pipelines/:pipeline_name/order/:order_action' do
    @order_action = params['order_action']
    if @order_action == 'insert_at'
      param :position, Integer, min: 0, required: true, raise: true
      @position = params[:position]
    end
  end

  before '/:name/*/credential/*' do
    credential = params['splat'].last.split('/')[0]
    @credential = Credential.find_by_name(credential)

    if @credential.nil?
      request_halt("Credential \"#{credential}\" does not exists.", 404)
    end
  end

  get '/' do
    content_type :json
    param :include, String, is: 'envs', required: false, raise: true

    query = Application

    to_json_options = {}
    if params[:include]
      to_json_options[:include] = {}
      included_relations = params[:include].split(',')

      if included_relations.include?('envs')
        query = query.eager_load(:envs)
        # to_json_options[:include][:envs] = {only: [:id, :name]}
        to_json_options[:include][:envs] = { only: %i[id name pipelines credentials], include: %i[pipelines credential] }
        to_json_options[:include][:envs][:pipelines] = { only: :name }
        to_json_options[:include][:versions] = { only: %i[id version] }
      end
    end

    query.all.to_json(to_json_options)
  end

  post '/' do
    content_type :json
    status 201

    payload = JSON.parse(request.body.read, symbolize_names: true)
    app = ApplicationService.new.add_application(payload)
    app.to_json
  end

  get '/:name' do
    @application.to_json
  end

  delete '/:name' do |_name|
    status 202
    if @application.is_deletable?
      @application.destroy
    else
      request_halt("Cannot delete application: #{@application.name} due to upcoming releases.", 400)
    end
    { status: 'ok' }.to_json
  end

  get '/:name/versions/:version_name' do |_name, version_name|
    @application.versions.find_by_version(version_name).to_json(with_release_orders: true)
  end

  get '/:name/versions' do
    versions_sorted = @application.versions.sort_by &:version
    versions_sorted.to_json
  end

  post '/:name/versions' do |_name|
    content_type :json
    status 201
    json = JSON.parse(request.body.read, symbolize_names: true)

    if json[:term] && !json[:version]
      options = {}
      options[:pre] = json[:pre] if json[:pre]
      options[:build] = json[:build] if json[:build]

      latest_version = @application.versions.max_by(&:version)
      unless latest_version
        request_halt("Appliction with name \"#{@application.name}\" does not have any defined version yet. Please set at least one version like: 1.0.1", 404)
      end

      PutitVersioning.validate_term(json[:term])
      # check if latest version is match SemVer
      unless latest_version.version.is_version?
        raise PutitExceptions::SemanticNotValidVersion, "Last version: #{latest_version.version} for application: #{@application.name} is not valid SemVer. Cannot proceed. Please set version manually."
      end

      version = PutitVersioning.new(latest_version.version)
      new_version = version.set_version(json[:term] + '!', options)
      @application.versions.find_or_create_by!(version: new_version.to_s)
    elsif json[:version]
      @application.versions.find_or_create_by!(version: json[:version])
    end
    { status: 'ok' }.to_json
  end

  get '/:name/versions/:version_name/artifacts' do |_name, _version_name|
    @application_version.artifact_with_versions.all.to_json
  end

  post '/:name/versions/:version_name/artifacts' do |_name, _version_name|
    status 202

    json = JSON.parse(request.body.read, symbolize_names: true)

    artifact = Artifact.find_by_name(json[:name])
    if artifact.nil?
      request_halt("Artifact with name \"#{json[:name]}\" does not exists", 404)
    end

    version = artifact.versions.find_by_version(json[:version])
    if version.nil?
      request_halt("Version \"#{json[:version]}\" for artifact \"#{json[:name]}\" does not exists", 404)
    end

    avw = ArtifactWithVersion.find_or_create_by!(artifact_id: artifact.id, version_id: version.id)
    ApplicationWithVersionArtifactWithVersion.find_or_create_by!(artifact_with_version_id: avw.id, application_with_version_id: @application_version.id)

    logger.info("Artifact with name: \"#{json[:name]}\" in version: \"#{json[:version]}\ added into application: \"#{@application.name}\" in version: \"#{@application_version.version}\"")
    { status: 'ok' }.to_json
  end

  delete '/:name/versions/:version_name/artifacts/:artifact_name/:artifact_version' do |_name, _version_name, artifact_name, artifact_version|
    status 202

    artifact = Artifact.find_by_name(artifact_name)
    if artifact.nil?
      request_halt("Artifact with name \"#{artifact_name}\" does not exists", 404)
    end

    version = artifact.versions.find_by_version(artifact_version)
    if version.nil?
      request_halt("Version \"#{artifact_version}\" for artifact \"#{artifact_name}\" does not exists", 404)
    end

    avw = ArtifactWithVersion.find_by(artifact_id: artifact.id, version_id: version.id)
    ApplicationWithVersionArtifactWithVersion.where(artifact_with_version_id: avw.id, application_with_version_id: @application_version.id).destroy_all

    logger.info("Artifact with name: \"#{artifact_name}\" in version: \"#{artifact_version}\ deleted from application: \"#{@application.name}\" in version: \"#{@application_version.version}\"")
    { status: 'ok' }.to_json
  end

  get '/:name/envs' do |_name|
    @application.envs.distinct.to_json
  end

  post '/:name/envs' do
    status 201

    envs = JSON.parse(request.body.read, symbolize_names: true)

    result = nil
    conflicts = nil
    Application.transaction do
      result, conflicts = ApplicationService.new.add_envs(@application, envs)

      raise ActiveRecord::Rollback unless conflicts.empty?
    end

    if conflicts.empty?
      result.to_json
    else
      status 409
      return {
        status: 'error',
        msg: 'Validation failed: Some names have already been taken',
        conflicts: conflicts
      }.to_json
    end
  end

  head '/:name/envs/:env' do
    if @env_for_application
      status 200
    else
      status 404
    end
  end

  delete '/:name/envs/:env' do |_name, env|
    status 202
    if @env_for_application.is_deletable?
      @env_for_application.destroy
      logger.info("Deleted environment: #{env} for the application: #{@application.name} with properties.")
    else
      request_halt("There is an upcoming change for the application: #{@application.name} on environment: #{env}", 400)
    end

    { status: 'ok' }.to_json
  end

  get '/:name/envs/:env_name/credential' do
    @env_for_application.credential.to_json
  end

  put '/:name/envs/:env_name/credential/:credential_name' do |_name, _env, _credential_name|
    status 202
    @env_for_application.credential = @credential
    logger.info("Added credential with name: #{@credential.name} to the application: #{@application.name} on Env #{@env_for_application.name}")

    { status: 'ok' }.to_json
  end

  delete '/:name/envs/:env_name/credential/:credential_name' do |_name, _env, _credential_name|
    status 202
    credential = @env_for_application.credential
    if credential.nil?
      request_halt("No credential assigned to the application: #{@application.name} on Env #{@env_for_application.name}", 404)
    end

    env_cred = EnvCredential.where(env_id: @env_for_application.id, credential_id: credential.id).first
    if env_cred.nil?
      request_halt("No such credential with name: #{@credential.name} assigned to the application: #{@application.name} on Env #{@env_for_application.name}", 404)
    else
      env_cred.destroy
      logger.info("Unassigned credential with name: #{@credential.name} to the application: #{@application.name} on Env #{@env_for_application.name}")
    end
    { status: 'ok' }.to_json
  end

  get '/:name/envs/:env/hosts' do |_name, _env|
    @env_for_application.hosts.to_json
  end

  post '/:name/envs/:env/hosts' do |_name, env|
    status 201

    hosts = JSON.parse(request.body.read, symbolize_names: true)

    result = nil
    conflicts = nil
    errors = nil

    Application.transaction do
      result, conflicts, errors = ApplicationService.new.add_hosts(
        @application, env, hosts
      )

      raise ActiveRecord::Rollback unless conflicts.empty?
    end

    if conflicts.empty?
      result.to_json
    else
      status 409
      return {
        status: 'error',
        msg: 'Validation failed: Some fqdns have already been taken',
        conflicts: conflicts
      }.to_json
    end
  end

  get '/:name/envs/:env/hosts/:fqdn' do |_name, _env, _fqdn|
    @host.to_json
  end

  delete '/:name/envs/:env/hosts/:fqdn' do |_name, _env, _fqdn|
    status 202
    @host.destroy
    logger.info("Deleted host: #{@host.name} with FQDN: #{@host.fqdn}")
    { status: 'ok' }.to_json
  end

  post '/:name/envs/:env/tags/aws' do
    status 201
    json = JSON.parse(request.body.read, symbolize_names: true)

    @env_for_application.update!(aws_tags: json[:tags])
    { status: 'ok' }.to_json
  end

  get '/:name/envs/:env/tags/aws' do
    tags = @env_for_application.aws_tags
    { tags: tags }.to_json
  end

  delete '/:name/envs/:env/tags/aws' do
    status 202
    @env_for_application.update!(aws_tags: nil)
  end

  get '/:name/envs/:env_name/hosts/:fqdn/credential' do
    @host.credential.to_json
  end

  put '/:name/envs/:env_name/hosts/:fqdn/credential/:credential_name' do
    status 202
    @host.credential = @credential
    logger.info("Added credential with name: #{@credential.name} to the application: #{@application.name} on Env #{@env_for_application.name} and on Host: #{@host.fqdn}")

    { status: 'ok' }.to_json
  end

  delete '/:name/envs/:env_name/hosts/:fqdn/credential/:credential_name' do
    status 202

    credential = @host.credential
    if credential.nil?
      request_halt("No credential assigned to the application: #{@application.name} on env #{@env_for_application.name} and host #{@host.fqdn}", 404)
    end

    host_cred = HostCredential.where(host_id: @host.id, credential_id: credential.id).first
    if host_cred.nil?
      request_halt("No such credential with name: #{@credential.name} assigned to the application: #{@application.name} on Env #{@env_for_application.name} and host #{@host.fqdn}", 404)
    else
      host_cred.destroy
      logger.info("Unassigned credential with name: #{@credential.name} from the application: #{@application.name} on Env #{@env_for_application.name} and on Host: #{@host.fqdn}")
    end
    { status: 'ok' }.to_json
  end

  get '/:name/envs/:env_name/properties' do
    PROPERTIES_STORE.fetch(@env_for_application.properties_key, {}).to_json
  end

  get '/:name/envs/:env_name/properties/:key' do
    PROPERTIES_STORE[@env_for_application.properties_key].fetch(@properties_key, {}).to_json
  end

  post '/:name/envs/:env_name/properties' do
    status 201

    properties = JSON.parse(request.body.read)

    current_properties = PROPERTIES_STORE.fetch(@env_for_application.properties_key, {})

    if current_properties.nil?
      PROPERTIES_STORE[@env_for_application.properties_key] = properties
    else
      current_properties.merge!(properties)
      PROPERTIES_STORE[@env_for_application.properties_key] = current_properties
    end

    properties = PropertiesAnonymizer.anonymize(properties)
    logger.info("Properties set for application #{@application.name} on environment #{@env_for_application.name}", properties)

    { status: 'ok' }.to_json
  end

  delete '/:name/envs/:env_name/properties/:key' do
    status 202

    hash = PROPERTIES_STORE.fetch(@env_for_application.properties_key, {})
    hash.delete(@properties_key)
    PROPERTIES_STORE[@env_for_application.properties_key] = hash

    logger.info("Properties with #{@properties_key} deleted for application #{@application.name} on environment #{@env_for_application.name}")

    { status: 'ok' }.to_json
  end

  # get orders for app
  get '/:name/orders' do
    param :status,                String, in: ReleaseOrder.statuses.map(&:first), required: false, raise: true
    param :upcoming,              Boolean, required: false, raise: true
    param :start_date,            Date, required: false, raise: true
    param :end_date,              Date, required: false, raise: true
    param :include,               String, is: 'release_order_results', required: false, raise: true
    param :includeClosedReleases, Boolean, required: false, raise: true
    param :release,               String, required: false, raise: true
    param :q,                     String, required: false, raise: true

    included_relations = []
    included_relations = params[:include].split(',') if params[:include]

    orders = ReleaseOrder.joins(:application_with_versions)
                         .where('application_with_versions.application_id = ?', @application.id)

    orders = orders.where(status: params['status']) if params.include?('status')

    if params['includeClosedReleases'].to_s != 'true'
      orders = orders.joins(:release).where('releases.status = ?', Release.statuses[:open])
    end

    if params['release']
      orders = orders.joins(:release).where('releases.name = ?', params['release'])
    end

    if params['q']
      q = params['q'].downcase
      release_name_matches_q = Release.arel_table[:name].lower.matches("%#{q}%")
      release_order_name_matches_q = ReleaseOrder.arel_table[:name].lower.matches("%#{q}%")

      orders = orders.joins(:release)
                     .where(
                       release_name_matches_q.or(release_order_name_matches_q)
                     )
    end

    if params.include?('start_date')
      orders = orders.where('start_date >= ?', params['start_date'])
    end

    if params.include?('end_date')
      orders = orders.where('start_date < ?', params['end_date'])
    end

    orders.to_json(include: included_relations)
  end

  # get orders for this app and env
  get '/:name/envs/:env_name/orders' do
    param :status,     String, in: ReleaseOrder.statuses.map(&:first), required: false, raise: true
    param :upcoming,   Boolean, required: false, raise: true

    orders = @env_for_application.get_orders(params).map(&:release_order)

    if params['includeClosedReleases'].to_s != 'true'
      orders = orders.select { |ro| ro.release.open? }
    end

    orders.to_json
  end

  # used by UI
  get '/:name/orders/upcoming' do
    upcoming_orders = @application.upcoming_orders
    if upcoming_orders.empty?
      {}.to_json
    else
      {
        count: upcoming_orders.count,
        date: upcoming_orders.first.start_date
      }.to_json
    end
  end

  # used by UI
  get '/:name/results/by_env' do
    ReleaseOrderResult.where(application_id: @application.id)
                      .group_by { |r| r.env.name }
                      .transform_values do |r|
      {
        count: r.length,
        status: r.group_by(&:status).transform_values(&:count)
      }
    end .to_json
  end

  get '/:name/envs/:env/results/count' do
    count = ReleaseOrderResult.where(application_id: @application.id, env_id: @env_for_application.id).count

    { count: count }.to_json
  end

  get '/:name/envs/:env/pipelines' do
    @env_for_application.pipelines.to_json
  end

  post '/:name/envs/:env/pipelines' do
    json = JSON.parse(request.body.read, symbolize_names: true)

    Array.wrap(json).each do |pipeline|
      p = DeploymentPipeline.templates.find_by_name(pipeline[:name])
      if p.nil?
        request_halt("No template for pipeline with name: \"#{pipeline[:name]}\"", 404)
      end
      unless @env_for_application.pipelines.exists?(name: pipeline[:name])
        @env_for_application.pipelines << p.amoeba_dup
      end
      logger.info("Pipeline template \"#{pipeline[:name]}\" added to application: \"#{@application.name}\" for env: \"#{@env_for_application.name}\"")
    end

    @env_for_application.pipelines.to_json
  end

  patch '/:name/envs/:env/pipelines/:pipeline_name' do
    status 202
    json = JSON.parse(request.body.read, symbolize_names: true)
    old_name = @pipeline.name
    @pipeline.update!(name: json[:name])
    logger.info("Changed pipeline name from: \"#{old_name}\" to \"#{json[:name]}\" for application: \"#{@application.name}\" for env: \"#{@env_for_application.name}\"")

    { status: 'ok' }.to_json
  end

  put '/:name/envs/:env/pipelines/:pipeline_name/order/:order_action' do
    status 202
    # move to new_position
    if @order_action == 'insert_at' && @position >= 0
      @pipeline.insert_at(@position)
      log_msg = "Reorder action: insert_at to postion: #{@position} made on pipeline: #{@pipeline.name} for application: \"#{@application.name}\" for env: \"#{@env_for_application.name}\""
    # reorder by actions: move_to_top etc.
    elsif @order_action
      @pipeline.respond_to?(@order_action) ? @pipeline.send(@order_action) : request_halt("Invalid order action #{@order_action} for pipeline with name: \"#{@pipeline.name}\"", 400)
      log_msg = "Reorder action: #{@order_action} made on pipeline: #{@pipeline.name} for application: \"#{@application.name}\" for env: \"#{@env_for_application.name}\""
    else
      request_halt('Invalid payload. Missing one of attributes: :order_action or :position)', 400)
    end
    logger.info(log_msg)

    { status: 'ok' }.to_json
  end

  delete '/:name/envs/:env/pipelines/:pipeline' do |_name, _env, _pipeline|
    status 202

    @pipeline.destroy

    { status: 'ok' }.to_json
  end

  post '/:name/envs/:env/events' do
    param :severity,     String, required: false, raise: true
    param :eventType,    String, required: false, raise: true

    status 201
    body = request.body.read
    payload = {}

    if !body.to_s.empty?
      json = JSON.parse(body, symbolize_names: true)
      payload['data'] = json[:data] unless json.empty?
    else
      puts 'no body'
    end

    payload['severity'] = params['severity'] if params.include?('severity')
    payload['event_type'] = params['eventType'] if params.include?('eventType')

    payload['source'] = if params.include?('source')
                          params['source']
                        else
                          'not_set'
                        end

    event = if payload.empty?
              @env_for_application.events.create!
            else
              @env_for_application.events.create!(payload) do |e|
                e.run_actions = params['actions']
              end
            end

    logger.info("Event created for application: \"#{@application.name}\" for env: \"#{@env_for_application.name}\"")

    broadcast(:event_created, event)

    { status: 'ok' }.to_json
  end

  get '/:name/envs/:env/events' do
    @env_for_application.events.to_json
  end

  get '/:name/envs/:env/env_actions' do
    @env_for_application.env_actions.to_json
  end

  # add new env_action
  post '/:name/envs/:env/env_actions' do
    status 201
    json = JSON.parse(request.body.read, symbolize_names: true)
    env_action = @env_for_application.env_actions.create!(json)
    logger.info("Env action created for application: \"#{@application.name}\" for env: \"#{@env_for_application.name}\"")

    { status: 'ok' }.to_json
  end
end
