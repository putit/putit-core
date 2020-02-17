describe OrderController do
  it 'should return ReleaseOrder objects for open releases by default' do
    get '/orders'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to be 5
  end

  it 'should return ReleaseOrder objects for all releases when includeClosedReleases param is given' do
    get '/orders?includeClosedReleases=true'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to be 6
  end

  it 'should return ReleaseOrder objects for a given date range' do
    start_date = (Time.now - 2.days).strftime('%Y-%m-%d')
    end_date = (Time.now + 1.days).strftime('%Y-%m-%d')

    get "/orders/?start_date=#{start_date}&end_date=#{end_date}"
    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 2

    expect(result[0][:name]).to eq 'Release order 2'
  end

  it 'should return ReleaseOrder objects with release order results' do
    get '/orders?include=release_order_results'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[0][:release_order_results].length).to eq 3
  end

  it 'should search through release name' do
    get '/orders?q=Web'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to be 4
    proper_release_names = result.all? { |r| r[:release][:name] == 'Web html flat release' }
    expect(proper_release_names).to be true
  end

  it 'should search through order name' do
    get '/orders?includeClosedReleases=true&q=Closed'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to be 1
  end

  it 'should filter for deployed orders' do
    get '/orders?status=deployed'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 1
    expect(result[0][:name]).to eq 'Future release order 2'
  end

  it 'should return only upcoming orders' do
    get '/orders?upcoming=true'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 3
  end
end
