class StepController < SecureController

  before '/templates/*' do
    name = params['splat'][0].split('/')[0]
    pass if name.blank?
    @step_template = Step.templates.find_by_name(name)

    if @step_template.nil?
      request_halt("Step template with name \"#{name}\" does not exists.", 404)
    end
  end

  get '/templates' do
    Step.templates.to_json
  end

  post '/templates' do
    status 201

    json = JSON.parse(request.body.read)

    step = Step.templates.create!(name: json['name'])
    step.update!(json)
    logger.info("Created step template with name: #{json['name']}")

    step.to_json
  end

  head '/templates/:name' do |_name|
    status 200
  end

  get '/templates/:name' do |_name|
    @step_template.to_json
  end

  delete '/templates/:name' do
    status 202
    @step_template.destroy
    logger.info("Deleted step template with name: #{@step_template.name}")

    { status: 'ok' }.to_json
  end

  patch '/templates/:name' do
    status 202
    json = JSON.parse(request.body.read, symbolize_names: true)
    old_name = @step_template.name
    @step_template.update!(name: json[:name])
    logger.info("Changed step name from: \"#{old_name}\" to \"#{json[:name]}\" in pipeline : \"#{@step_template.name}\"")

    { status: 'ok' }.to_json
  end

  put '/templates/:name' do |_name|
    status 202
    json = JSON.parse(request.body.read)

    @step_template.update!(json)

    ANSIBLE_TABLES.each do |t|
      @step_template.send(t).physical_files.destroy_all
    end

    @step_template.to_json
  end

  get '/:name' do |name|
    step = Step.find_by_name(name)
    if step.nil?
      request_halt("Step with name \"#{name}\" does not exists.", 404)
    end
    step.to_json
  end

  ANSIBLE_TABLES.each do |t|
    post "/templates/:name/#{t}" do |_name|
      request_halt("Error with uploading file...", 501) unless params[:file]
      filename = params[:file][:filename]
      content = File.read(params[:file][:tempfile])

      @step_template.send(t).physical_files.create!(name: filename, content: content)
      logger.info("Uploaded file #{filename} into step template: #{@step_template.name}")
      201
    end

    get "/templates/:name/#{t}" do |_name|
      @step_template.send(t).physical_files.to_json
    end

    get "/templates/:name/#{t}/:filename" do |_name, filename|
      file = @step_template.send(t).physical_files.find_by_name(filename)

      content_type 'application/octet-stram'
      attachment filename
      file.content
    end

    get "/:id/#{t}" do |id|
      step = Step.find(id)
      step.send(t).physical_files.to_json
    end
  end
end
