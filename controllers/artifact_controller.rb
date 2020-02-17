class ArtifactController < SecureController

  before '/*' do
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    @artifact = Artifact.find_by_name(name)

    if @artifact.nil?
      request_halt("Artifact with name \"#{name}\" does not exists.", 404)
    end
  end

  before '/:name/version/*' do
    version = params['splat'][0].split('/')[0]
    @version = @artifact.versions.find_by_version(version)

    if @version.nil?
      request_halt("Version \"#{version}\" for Artifact \"#{@artifact.name}\" does not exists.", 404)
    end
    @awv = ArtifactWithVersion.find_by_artifact_id_and_version_id(@artifact.id, @version.id)
  end

  get '/' do
    Artifact.all.to_json
  end

  post '/' do
    status 201

    artifacts = JSON.parse(request.body.read, symbolize_names: true)

    shouldCloneProperies = params['dontCloneProperties'] != 'true'

    artifacts.map do |artifact|
      name = artifact[:name]
      a = Artifact.find_or_create_by!(name: name)

      if shouldCloneProperies
        last_version = a.versions.order('id asc').last
        last_properties = get_properties_for_last_version(a, last_version)
      end

      if artifact[:term] && !artifact[:version]
        options = {}
        options[:pre] = artifact[:pre] if artifact[:pre]
        options[:build] = artifact[:build] if artifact[:build]
        PutitVersioning.validate_term(artifact[:term])
        latest_version = a.versions.max_by(&:version)
        unless latest_version.version.is_version?
          raise PutitExceptions::SemanticNotValidVersion, "Last version: #{latest_version.version} for artifact: #{a.name} is not valid SemVer. Cannot proceed. Please set version manually."
        end

        version = PutitVersioning.new(latest_version.version)
        new_version = version.set_version(artifact[:term] + '!', options)
        @v = a.versions.find_or_create_by!(version: new_version.to_s)
      elsif artifact[:version]
        @v = a.versions.find_or_create_by!(version: artifact[:version])
      end

      new_avw = ArtifactWithVersion.find_or_create_by!(artifact_id: a.id, version_id: @v.id)
      if shouldCloneProperies && !last_properties.empty?
        logger.debug("Cloning properties from previous version #{last_version.version} for artifact: #{a.name} version: #{@v.version}")
        new_version = {
          'artifact_version' => @v.version,
          'artifact_with_version' => a.name + '-' + @v.version
        }
        logger.debug("Last properties: #{last_properties.inspect}")
        PROPERTIES_STORE[new_avw.properties_key] = last_properties.dup.merge(new_version)
      else
        logger.debug "Adding default properties to the artifact: #{a.name} version: #{@v.version}"
        default_properties = {
          'artifact_name' => a.name,
          'artifact_version' => @v.version,
          'artifact_with_version' => a.name + '-' + @v.version
        }
        PROPERTIES_STORE[new_avw.properties_key] = default_properties
      end
      a.save!
      logger.info("Artifact \"#{name}\" has been added in version: \"#{@v.version}\"")
      a
    end.to_json
  end

  get '/:name' do |_name|
    @artifact.to_json
  end

  delete '/:name' do
    status 202
    @artifact.destroy

    { status: 'ok' }.to_json
  end

  get '/:name/versions' do |_name|
    @artifact.versions.to_json
  end

  post '/:name/version/:version_name/properties' do
    status 202

    avw = ArtifactWithVersion.find_by_artifact_id_and_version_id(@artifact.id, @version.id)
    if avw.nil?
      avw = ArtifactWithVersion.create!(artifact_id: @artifact.id, version_id: @version.id)
    end
    properties = JSON.parse(request.body.read)

    current_properties = PROPERTIES_STORE.fetch(@awv.properties_key, {})

    PROPERTIES_STORE[avw.properties_key] = if current_properties.nil?
                                             properties
                                           else
                                             current_properties.merge(properties)
                                           end

    properties = PropertiesAnonymizer.anonymize(properties)
    logger.info("Properties set for artifact #{@artifact.name} in version #{@version.version}", properties)

    { status: 'ok' }.to_json
  end

  get '/:name/version/:version_name/properties' do
    PROPERTIES_STORE.fetch(@awv.properties_key, {}).to_json
  end

  get '/:name/version/:version_name' do |_name, _version_name|
    {
      id: @artifact.id,
      version_id: @version.id
    }.to_json
  end

  delete '/:name/version/:version_name' do |name, version_name|
    status 202
    @awv.destroy
    logger.info("Deleted artifact: #{name} in version: #{version_name}")
    { status: 'ok' }.to_json
  end

  private

  def get_properties_for_last_version(artifact, version)
    return {} unless version

    awv = ArtifactWithVersion.find_by_artifact_id_and_version_id(artifact.id, version.id)
    if awv
      PROPERTIES_STORE.fetch(awv.properties_key, {})
    else
      return {}
    end
  end
end
