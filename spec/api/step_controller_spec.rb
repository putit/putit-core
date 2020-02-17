describe StepController do
  it 'should return all step templates' do
    get '/step/templates'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 2
  end

  it 'should return step template' do
    get '/step/templates/copy_artifacts'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:id]).to eq 1
  end

  it 'should check is step template exists via HEAD' do
    head '/step/templates/copy_artifacts'

    expect(last_response).to be_ok
  end

  it 'should return 404 when template does exists asked via HEAD' do
    head '/step/templates/not%20exists'

    expect(last_response.status).to eq 404
  end

  it 'should return 404 when step template does not exist' do
    get '/step/templates/not%20exists'

    expect(last_response.status).to eq 404
    result = JSON.parse(last_response.body, symbolize_names: true)

    expect(result[:msg]).to eq 'Step template with name "not exists" does not exists.'
  end

  it 'should add new step template' do
    step = {
      name: 'Run_httpd_service',
      description: 'Run httpd service using system tools'
    }

    post '/step/templates', step.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 201

    result = Step.templates.all
    expect(result.length).to eq 3

    new_template = result[2]
    expect(new_template[:name]).to eq 'Run_httpd_service'
    expect(new_template[:description]).to eq 'Run httpd service using system tools'
  end

  describe 'step' do
    it 'should get file from files table' do
      get '/step/1/files'

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 1
      expect(result[0][:name]).to eq 'putit_test.file'
    end
  end

  describe 'ansible specific directories' do
    ANSIBLE_TABLES.each do |t|
      it "should add file to #{t} table" do
        file = Rack::Test::UploadedFile.new('Rakefile', 'text/plain', true)

        step = Step.create!(name: 'file_upload', template: true)
        name = step.name

        post "/step/templates/#{name}/#{t}", file: file

        expect(last_response.status).to eq 201

        created_file = step.send(t).physical_files.first
        expect(created_file.name).to eq 'Rakefile'
        expect(created_file.content).to start_with "require './config/environment.rb'\n"
      end

      it "should get file description from #{t} table" do
        file = Rack::Test::UploadedFile.new('Rakefile', 'text/plain', true)

        step = Step.create!(name: 'file_upload', template: true)
        name = step.name

        post "/step/templates/#{name}/#{t}", file: file

        expect(last_response.status).to eq 201

        get "/step/templates/#{name}/#{t}"

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 1
        expect(result[0][:name]).to eq 'Rakefile'
      end

      it "should download file from #{t} table" do
        file = Rack::Test::UploadedFile.new('Rakefile', 'text/plain', true)

        step = Step.create!(name: 'file_upload', template: true)
        name = step.name

        post "/step/templates/#{name}/#{t}", file: file

        expect(last_response.status).to eq 201

        get "/step/templates/#{name}/#{t}/Rakefile"

        expect(last_response).to be_ok

        expect(last_response.header['Content-Disposition']).to eq 'attachment; filename="Rakefile"'
        expect(last_response.body).to start_with "require './config/environment.rb'\n"
      end
    end
  end

  it 'should update step template with new files' do
    step = {
      name: 'httpd',
      description: 'Run httpd service using system tools'
    }

    post '/step/templates', step.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 201

    rakefile = Rack::Test::UploadedFile.new('Rakefile', 'text/plain', true)
    config_ru = Rack::Test::UploadedFile.new('config.ru', 'text/plain', true)
    post '/step/templates/httpd/files', file: rakefile
    post '/step/templates/httpd/files', file: config_ru

    expect(Step.templates.find_by_name('httpd').files.physical_files.length).to eq 2

    put '/step/templates/httpd', step.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to be 202

    expect(Step.templates.find_by_name('httpd').files.physical_files.length).to eq 0

    post '/step/templates/httpd/files', file: config_ru

    expect(Step.templates.find_by_name('httpd').files.physical_files.length).to eq 1
  end

  describe 'delete' do
    it 'should delete step template' do
      s = Step.templates.first
      sf_id = s.files.id
      st_id = s.templates.id
      sh_id = s.handlers.id
      st_id = s.tasks.id
      sv_id = s.vars.id
      sd_id = s.defaults.id

      delete "/step/templates/#{s.name}"

      expect(last_response.status).to eq 202

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      expect(Step.templates.exists?(s.id)).to eq false

      expect(AnsibleFiles.exists?(sf_id)).to eq false
      expect(AnsibleTemplates.exists?(st_id)).to eq false
      expect(AnsibleHandlers.exists?(sh_id)).to eq false
      expect(AnsibleTasks.exists?(st_id)).to eq false
      expect(AnsibleVars.exists?(sv_id)).to eq false
      expect(AnsibleDefaults.exists?(sd_id)).to eq false
    end
  end
end
