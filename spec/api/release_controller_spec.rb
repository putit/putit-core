describe ReleaseController do
  describe 'get all releases' do
    it 'should return only open releases by default' do
      get '/release'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 2
      expect(result[0][:status]).to eq 'open'
      expect(result[1][:status]).to eq 'open'
    end

    it 'should return all releases with includeClosedReleases query parameter' do
      get '/release?includeClosedReleases=true'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 3
      expect(result[0][:status]).to eq 'open'
      expect(result[1][:status]).to eq 'open'
      expect(result[2][:status]).to eq 'closed'
    end
  end

  it 'should create new release' do
    properties = {
      name: 'Release 2'
    }
    post '/release', properties.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 201
  end

  it 'should delete release' do
    r = Release.first
    name = URI.encode_www_form_component(r.name).gsub('+', '%20')
    ro = r.release_orders.first
    r_id = r.id
    ids = r.release_orders.map(&:id)

    applications = [{
      application_name: 'WEBv1',
      version_name: '2.0.0'
    }]
    post "/release/#{name}/orders/#{URI.encode_www_form_component(ro.name).gsub('+', '%20')}/applications", applications.to_json,
         'CONTENT_TYPE': 'application/json'

    avw_ids = r.reload.release_orders.first.application_with_versions.ids

    delete "/release/#{name}"

    expect(last_response.status).to eq 202
    result = JSON.parse(last_response.body, symbolize_names: true)

    expect(result[:status]).to eq 'ok'

    expect(Release.exists?(r_id)).to eq false

    ids.each do |id|
      expect(ReleaseOrder.exists?(id)).to eq false
    end

    avw_ids.each do |id|
      expect(ReleaseOrderApplicationWithVersion.exists?(id)).to eq false
    end
  end

  it 'should return 409 when Release exists' do
    properties = {
      name: 'Release 2'
    }
    post '/release', properties.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 201

    post '/release', properties.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 409
    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:msg]).to eq 'Release with name "Release 2" exists.'
  end

  it 'should return 422 when creating Release with wrong payload' do
    properties = {
      name: 'Release 2/'
    }
    post '/release', properties.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 400
    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:msg]).to eq 'Validation failed: Name is invalid'
  end

  it 'should return release for given name' do
    get '/release/Web%20html%20flat%20release'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:name]).to eq 'Web html flat release'
  end

  it 'should return 404 when Release does not exists' do
    get '/release/not%20exists'

    expect(last_response.status).to eq 404
    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:msg]).to eq 'Release with name "not exists" does not exists.'
  end

  describe 'status' do
    it 'should set status for release' do
      properties = {
        status: 'closed'
      }
      patch '/release/Web%20html%20flat%20release/status', properties.to_json, 'CONTENT_TYPE': 'application/json'

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'closed'
      expect(last_response.status).to eq 202
    end
  end

  describe 'release orders' do
    it 'should get all release orders' do
      get '/release/Web%20html%20flat%20release/orders'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result.length).to eq 4
    end

    it 'should return given release order' do
      name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')
      get "/release/Web%20html%20flat%20release/orders/#{name}"

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:description]).to eq ReleaseOrder.first.description
    end

    it 'should make new release order' do
      properties = {
        start_date: '2017-12-18T21:05:23Z',
        end_date: '2017-12-20T21:05:23Z',
        name: 'New release order',
        description: 'New release order'
      }

      post '/release/Web%20html%20flat%20release/orders', properties.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      get '/release/Web%20html%20flat%20release/orders'

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result.length).to eq 5
      expect(result[4][:description]).to eq 'New release order'
    end

    it 'should throw 409 when release exists' do
      properties = {
        start_date: Time.now - 2.days,
        end_date: Time.now + 2.days,
        name: 'New release order',
        description: 'New release order'
      }

      post '/release/Web%20html%20flat%20release/orders', properties.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      post '/release/Web%20html%20flat%20release/orders', properties.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 409

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Release Order with name "New release order" exists.'
    end

    it 'should throw 403 when release is Closed' do
      properties = {
        start_date: Time.now - 2.days,
        end_date: Time.now + 2.days,
        name: 'New release order',
        description: 'New release order'
      }

      Release.first.closed!

      post '/release/Web%20html%20flat%20release/orders', properties.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 403
    end

    it 'should throw 422 when payload is wrong' do
      properties = {
        start_date: Time.now - 2.days,
        end_date: Time.now + 2.days,
        name: 'New release order /',
        description: 'New release order'
      }

      post '/release/Web%20html%20flat%20release/orders', properties.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 400

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Validation failed: Name is invalid'
    end

    describe 'deleting' do
      it 'should delete release order' do
        ro = ReleaseOrder.first
        name = URI.encode_www_form_component(ro.name).gsub('+', '%20')
        ro_id = ro.id

        delete "/release/Web%20html%20flat%20release/orders/#{name}"

        expect(last_response.status).to eq 202

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result[:status]).to eq 'ok'

        expect(ReleaseOrder.exists?(ro_id)).to eq false
      end
    end

    describe 'applications' do
      it 'should get applications from Release order' do
        name = URI.encode_www_form_component(ReleaseOrder.second.name).gsub('+', '%20')

        get "/release/Web%20html%20flat%20release/orders/#{name}/applications"

        expect(last_response).to be_ok

        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result).to include(include(id: 1, name: 'WEBv1', version: '1.0.0'))
        expect(result).to include(include(id: 3, name: 'TEST APPLICATION', version: '2.0.0'))
      end

      it 'should delete applications from Release Order' do
        ro = ReleaseOrder.second
        name = URI.encode_www_form_component(ro.name).gsub('+', '%20')
        app = Application.find_by_name('WEBv1')

        ids = ro.application_with_versions.where(application_id: app.id).ids

        delete "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1"

        expect(last_response.status).to eq 202

        ids.each do |id|
          expect(ReleaseOrderApplicationWithVersion.exists?(id)).to eq false
        end
      end

      it 'should return 404 when ReleaseOrder does not exists' do
        get '/release/Web%20html%20flat%20release/orders/not%20exists'

        expect(last_response.status).to eq 404
        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result[:msg]).to eq 'Release Order with name "not exists" does not exists.'
      end

      it 'should add applications to Release order' do
        name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')

        get "/release/Web%20html%20flat%20release/orders/#{name}/applications"

        expect(last_response).to be_ok
        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 0

        applications = [{
          application_name: 'WEBv1',
          version_name: '2.0.0'
        }]
        post "/release/Web%20html%20flat%20release/orders/#{name}/applications", applications.to_json,
             'CONTENT_TYPE': 'application/json'

        expect(last_response.status).to eq 201

        get "/release/Web%20html%20flat%20release/orders/#{name}/applications"
        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result.length).to eq 1
      end

      it 'should add applications to Release order' do
        name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')
        Release.first.closed!

        applications = [{
          application_name: 'WEBv1',
          version_name: '2.0.0'
        }]
        post "/release/Web%20html%20flat%20release/orders/#{name}/applications", applications.to_json,
             'CONTENT_TYPE': 'application/json'

        expect(last_response.status).to eq 403
        result = JSON.parse(last_response.body, symbolize_names: true)
        expect(result[:msg]).to eq 'Cannot add Application "WEBv1" to Release order "Release order 1" which belongs to closed Release "Web html flat release"'
      end

      describe 'envs' do
        it 'should get envs attached to Application with Version' do
          name = URI.encode_www_form_component(ReleaseOrder.second.name).gsub('+', '%20')

          get "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1/1.0.0/envs"

          expect(last_response).to be_ok

          result = JSON.parse(last_response.body, symbolize_names: true)
          expect(result.length).to eq 2
          expect(result).to include(include(name: 'dev'))
          expect(result).to include(include(name: 'prod'))

          get "/release/Web%20html%20flat%20release/orders/#{name}/applications/TEST%20APPLICATION/2.0.0/envs"

          expect(last_response).to be_ok

          result = JSON.parse(last_response.body, symbolize_names: true)
          expect(result.length).to eq 1
          expect(result).to include(include(name: 'test'))
        end

        it 'should add env to Application with Version' do
          name = URI.encode_www_form_component(ReleaseOrder.second.name).gsub('+', '%20')

          envs = [{
            env_name: 'uat'
          }]
          post "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1/1.0.0/envs", envs.to_json,
               'CONTENT_TYPE': 'application/json'

          expect(last_response.status).to eq 201

          get "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1/1.0.0/envs"

          expect(last_response).to be_ok

          result = JSON.parse(last_response.body, symbolize_names: true)
          expect(result.length).to eq 3
          expect(result).to include(include(name: 'dev'))
          expect(result).to include(include(name: 'uat'))
          expect(result).to include(include(name: 'prod'))
        end

        it 'should delete env from Application with Version' do
          name = URI.encode_www_form_component(ReleaseOrder.second.name).gsub('+', '%20')

          delete "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1/1.0.0/envs/prod"

          expect(last_response.status).to eq 202

          get "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1/1.0.0/envs"

          expect(last_response).to be_ok

          result = JSON.parse(last_response.body, symbolize_names: true)
          expect(result.length).to eq 1
          expect(result).to include(include(name: 'dev'))
        end

        it 'should return error when Env does not exists for Application' do
          name = URI.encode_www_form_component(ReleaseOrder.second.name).gsub('+', '%20')

          envs = [{
            env_name: 'not_exists'
          }]
          post "/release/Web%20html%20flat%20release/orders/#{name}/applications/WEBv1/1.0.0/envs", envs.to_json,
               'CONTENT_TYPE': 'application/json'

          expect(last_response.status).to eq 404
        end
      end
    end

    it 'should add approvers to Release Order' do
      name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')

      approvers = [
        {
          email: 'approver1@putit.io'
        },
        {
          email: 'approver2@putit.io'
        }
      ]
      post "/release/Web%20html%20flat%20release/orders/#{name}/approvers", approvers.to_json,
           'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 204

      get "/release/Web%20html%20flat%20release/orders/#{name}"

      result = JSON.parse(last_response.body, symbolize_names: true)

      expect(result[:approvers]).to be_an Array
      approvers = result[:approvers]
      expect(approvers[0]).to eq 'approver1@putit.io'
      expect(approvers[1]).to eq 'approver2@putit.io'
    end

    it 'should remove approvers from Release Order' do
      name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')

      approvers = [
        {
          email: 'approver1@putit.io'
        },
        {
          email: 'approver2@putit.io'
        }
      ]
      post "/release/Web%20html%20flat%20release/orders/#{name}/approvers", approvers.to_json,
           'CONTENT_TYPE': 'application/json'

      delete "/release/Web%20html%20flat%20release/orders/#{name}/approvers/approver1%40putit.io"
      expect(last_response.status).to eq 204

      approvals = ReleaseOrder.first.approvals
      expect(approvals.length).to eq 1
    end

    it 'should add productionize release order without any approvals' do
      name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')

      put "/release/Web%20html%20flat%20release/orders/#{name}/productionize"

      expect(last_response.status).to eq 204

      expect(ReleaseOrder.first.status).to eq 'approved'
    end

    it 'should add productionize release order and send approvals' do
      name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')

      approvers = [
        {
          email: 'approver1@putit.io'
        },
        {
          email: 'approver2@putit.io'
        }
      ]
      post "/release/Web%20html%20flat%20release/orders/#{name}/approvers", approvers.to_json,
           'CONTENT_TYPE': 'application/json'

      expect(ApprovalMailer).to receive(:deliver_approval_email).twice

      put "/release/Web%20html%20flat%20release/orders/#{name}/productionize"

      expect(last_response.status).to eq 204

      expect(ReleaseOrder.first.status).to eq 'waiting_for_approvals'
    end

    it 'should productionize release order with approved approvals' do
      name = URI.encode_www_form_component(ReleaseOrder.first.name).gsub('+', '%20')

      approvers = [
        {
          email: 'approver1@putit.io'
        },
        {
          email: 'approver2@putit.io'
        }
      ]
      post "/release/Web%20html%20flat%20release/orders/#{name}/approvers", approvers.to_json,
           'CONTENT_TYPE': 'application/json'

      Approval.first.update!(accepted: true)
      expect(ReleaseOrder.first.status).to eq 'working'

      Approval.second.update!(accepted: true)
      expect(ReleaseOrder.first.status).to eq 'approved'
    end
  end

  describe 'dependent releases' do
    it 'should add dependent release' do
      Release.create!(name: 'Dependent 1')

      put '/release/Web%20html%20flat%20release/dependent-releases/Dependent%201'

      expect(last_response.status).to eq 202

      get '/release/Web%20html%20flat%20release'

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:dependent_releases].length).to eq 1
      expect(result[:dependent_releases][0][:name]).to eq 'Dependent 1'
    end

    it 'should add detach dependent release' do
      release = Release.find_by_name('Web html flat release')
      subrelease = Release.create!(name: 'Dependent 1')

      Subrelease.create!(release_id: release.id, subrelease_id: subrelease.id)

      delete '/release/Web%20html%20flat%20release/dependent-releases/Dependent%201'

      expect(last_response.status).to eq 202

      expect(release.dependent_releases.length).to eq 0
    end
  end
end
