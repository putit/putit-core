class PipelineController < SecureController

  before '/templates/*' do
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    @template = DeploymentPipeline.templates.find_by_name(name)

    if @template.nil?
      request_halt("Pipeline template with name \"#{name}\" does not exists.", 404)
    end
  end

  before '/templates/:name/steps/:step_name*' do
    step_name = params['step_name']
    @step = @template.steps.find_by_name(step_name)
    if @step.nil?
      request_halt("No such step: #{step_name} in pipeline template: #{@template.name}", 404)
    end
  end

  before '/templates/:name/steps/:step_name/order/:order_action' do
    @order_action = params['order_action']
    @step_to_reorder = DeploymentPipelineStep.find_by(deployment_pipeline_id: @template.id, step_id: @step.id)

    if @step.nil?
      request_halt("No such step: #{step_name} in pipeline: #{@template.name}", 404)
    end

    @step_to_reorder = DeploymentPipelineStep.find_by(deployment_pipeline_id: @template.id, step_id: @step.id)
    if @step_to_reorder.nil?
      request_halt("No such step: #{step_name} in pipeline template: #{@template.name}", 404)
    end

    if @order_action == 'insert_at'
      param :position, Integer, min: 0, required: true, raise: true
      @position = params[:position]
    end
  end

  get '/' do
    DeploymentPipeline.where(template: false).to_json
  end

  get '/templates' do
    DeploymentPipeline.templates.to_json
  end

  post '/templates' do
    status 201

    json = JSON.parse(request.body.read)

    template = DeploymentPipeline.create!(template: true, name: json['name'])
    template.update!(json)
    logger.info("Pipeline template with name: #{json['name']} created.")

    template.to_json
  end

  get '/templates/:name' do |_name|
    @template.to_json
  end

  get '/:name' do |name|
    pipeline = DeploymentPipeline.where(template: false, name: name)
    if pipeline.nil?
      request_halt("No such pipeline with name: #{step[:name]}", 404)
    end
    pipeline.to_json
  end

  get '/templates/:name/steps' do |_name|
    @template.steps.to_json
  end

  post '/templates/:name/steps' do |_name|
    json = JSON.parse(request.body.read, symbolize_names: true)

    Array.wrap(json).each do |step|
      s_name = step[:name]
      step = Step.templates.find_by_name(s_name)
      request_halt("No such step with name: #{s_name}", 404) if step.nil?

      # because each assigned step has his own record in step table, we need to avoid duplication here
      assigned_steps_ids = @template.steps.pluck(:origin_step_template_id)
      assigned_steps_ids.each do |id|
        if step.id == id
          request_halt("Step template: #{step.name} already added into pipeline template: #{@template.name}", 409)
        end
      end

      @template.steps << step.amoeba_dup
      logger.info("Step: #{s_name} added into pipeline template: #{@template.name}")
    end

    { status: 'ok' }.to_json
  end

  delete '/templates/:name/steps/:step_name' do
    status 202
    step = DeploymentPipelineStep.where(deployment_pipeline_id: @template.id, step_id: @step.id).first
    if step.nil?
      request_halt("Step template: #{step.name} is not added into pipeline template: #{@template.name}", 404)
    end
    step.destroy
    logger.info("Step: #{@step.name} removed from pipeline template: #{@template.name}")
    { status: 'ok' }.to_json
  end

  patch '/templates/:name' do
    status 202
    json = JSON.parse(request.body.read, symbolize_names: true)
    old_name = @template.name
    @template.update!(name: json[:name])
    logger.info("Changed template pipeline name from: \"#{old_name}\" to \"#{json[:name]}\" in pipeline : \"#{@template.name}\"")
  end

  patch '/templates/:name/steps/:step_name' do
    status 202
    json = JSON.parse(request.body.read, symbolize_names: true)
    old_name = @step.name
    @step.update!(name: json[:name])
    logger.info("Changed step name from: \"#{old_name}\" to \"#{json[:name]}\" in pipeline : \"#{@template.name}\"")
  end

  put '/templates/:name/steps/:step_name/order/:order_action' do
    status 202

    if @order_action == 'insert_at' && @position >= 0
      @step_to_reorder.insert_at(@position)
      log_msg = "Reorder action: insert_at to postion: #{@position} made on step: #{@step.name} in pipeline template: #{@template.name}"
    # reorder by actions: move_to_top etc.
    elsif @order_action
      @step_to_reorder.respond_to?(@order_action) ? @step_to_reorder.send(@order_action) : request_halt("Invalid order action #{@order_action} for step with name: \"#{@step.name}\"", 400)
      log_msg = "Reorder action: #{@order_action} made on pipeline: #{@template.name} for step: #{@step.name}"
    else
      request_halt('Invalid payload. Missing one of attributes: :order_action or :position)', 400)
    end
    logger.info(log_msg)

    { status: 'ok' }.to_json
  end

  delete '/templates/:name' do |_name|
    status 202

    @template.destroy
    logger.info("Deleted template: #{@template.name}")
    { status: 'ok' }.to_json
  end
end
