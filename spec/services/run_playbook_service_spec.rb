describe RunPlaybookService do
  let(:release_order) { ReleaseOrder.first }

  before(:each) do
    allow(release_order.release).to receive(:playbook_dir).and_return './spec/services/temp_files'
    allow(IO).to receive(:popen)
    release_order.approved!
  end

  it 'should set release order status to deployed after proper deployment' do
    service = RunPlaybookService.new(release_order, STDOUT)
    service.run!

    expect(release_order.deployed?).to be true
  end

  describe 'Release order result' do
    it 'should create ReleaseOrderResult for every env' do
      service = RunPlaybookService.new(release_order, STDOUT)
      service.run!

      expect(release_order.release_order_results.length).to eq 3
    end

    it 'should create ReleaseOrderResut with status :success' do
      service = RunPlaybookService.new(release_order, STDOUT)
      service.run!

      results = release_order.release_order_results
      expect(results.map(&:status)).to eq %w[failure failure success]
    end

    it 'should create ReleaseOrderResut with status :failure' do
      allow(IO).to receive(:popen).and_raise(Exception)

      service = RunPlaybookService.new(release_order, ['dev'], STDOUT)
      service.run!

      results = release_order.release_order_results
      expect(results[0].status).to eq 'failure'
    end
  end
end
