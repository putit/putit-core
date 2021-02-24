describe PipelineController do
  it 'should return all pipeline templates' do
    get '/pipeline/templates'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 2
  end

  it 'should add new pipeline template' do
    pipeline = {
      name: 'Run httpd service'
    }

    post '/pipeline/templates', pipeline.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 201

    result = DeploymentPipeline.templates.all
    expect(result.length).to eq 3
  end

  it 'should get template pipeline by name' do
    get '/pipeline/templates/copy_files'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:name]).to eq 'copy_files'
  end

  it 'should get all steps added to template' do
    get '/pipeline/templates/copy_files/steps'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 1
    expect(result[0][:name]).to eq 'copy_artifacts'
  end

  it 'should add step template to pipeline template' do
    Step.create!(template: true, name: 'Step2')
    Step.create!(template: true, name: 'Step3')

    payload = [{
      name: 'Step2'
    }, {
      name: 'Step3'
    }]

    post '/pipeline/templates/copy_files/steps', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response).to be_ok

    pipeline = DeploymentPipeline.templates.find_by_name('copy_files')
    expect(pipeline.steps.length).to eq 3
    expect(pipeline.steps.second.name).to eq 'Step2'
    expect(pipeline.steps.second.template).to eq false
  end

  it 'should delete pipeline template' do
    delete '/pipeline/templates/copy_files'

    expect(last_response.status).to eq 202

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(DeploymentPipeline.templates.exists?(name: 'copy_files')).to eq false
  end

  it 'should remove step from pipeline template' do
    delete '/pipeline/templates/copy_files/steps/copy_artifacts'

    expect(last_response.status).to eq 202

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(DeploymentPipeline.templates.find_by_name('copy_files').steps.length).to eq 0
  end

  it 'should reorder steps in template' do
    Step.templates.create!(name: 'Step2')
    Step.templates.create!(name: 'Step3')

    payload = [{
      name: 'Step2'
    }, {
      name: 'Step3'
    }]

    post '/pipeline/templates/copy_files/steps', payload.to_json
    put '/pipeline/templates/copy_files/steps/Step3/order/move_to_top'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    template = DeploymentPipeline.templates.find_by_name('copy_files')
    expect(template.steps.first.name).to eq 'Step3'
  end
end
