# == Schema Information
#
# Table name: events
#
#  id         :integer          not null, primary key
#  env_id     :integer
#  source     :string
#  status     :integer
#  severity   :integer
#  uuid       :string(36)
#  data       :string
#  event_type :integer          default("performance")
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

describe Event, type: :model do
  it { is_expected.to validate_presence_of(:source) }
  it { is_expected.to validate_presence_of(:event_type) }

  it {
    is_expected.to define_enum_for(:event_type)
      .with_values(%i[operational performance tests devel])
  }

  it {
    is_expected.to define_enum_for(:status)
      .with_values(%i[open closed acked])
  }

  it {
    is_expected.to define_enum_for(:severity)
      .with_values(%i[low moderate major critical])
  }

  it { is_expected.to belong_to(:env) }

  describe '.run_action' do
    it 'should be accessible and always wrap to array' do
      event = Event.create!(source: 'Cluster')
      event.run_actions = 'A'

      expect(event.run_actions).to eq ['A']
    end

    it 'should return nil if run_action is not set' do
      event = Event.create!(source: 'Cluster')

      expect(event.run_actions).to be_nil
    end
  end

  it 'should be immutable afrer create' do
    event = Event.create!(source: 'Cluster')
    event.source = 'other'
    expect { event.save! }.to raise_error ActiveRecord::ReadOnlyRecord
  end

  it 'should not throw when service does not exists' do
    e = Env.first
    e.env_actions.create!(name: 'not_exists', data: { run_by_service: 'db_journal' })
    expect { Event.create(source: 'Cluster', env: e) }.not_to raise_error
  end

  it 'should not throw when service throws an error' do
    class ThrowErrorService
      def initialize(_event)
        raise RuntimeError
      end
    end

    e = Env.first
    e.env_actions.create!(name: 'throw_error', data: { run_by_service: 'throw_error' })
    expect { Event.create(source: 'Cluster', env: e) }.not_to raise_error
  end

  describe 'services' do
    it 'should run db_journal service after create' do
      e = Env.first
      e.env_actions.create!(name: 'db_journal', data: { run_by_service: 'db_journal' })
      Event.create(source: 'Cluster', env: e)
    end

    describe 'write file' do
      let(:path) { '/tmp/event.1' }

      after(:each) do
        # TODO: check why MemFS is not working here
        File.delete(path)
      end

      it 'should run write_file service after create' do
        e = Env.first
        e.env_actions.create!(name: 'write_file', data: { run_by_service: 'write_file' })
        Event.create(source: 'Cluster', env: e, data: { path: path, content: 'some test content' })

        expect(File.exist?(path)).to be true
        expect(File.read(path)).to eq 'some test content'
      end
    end

    describe 'external service' do
      let(:path) { '/opt/putit/putit-plugins/external/test.txt' }

      after(:each) do
        # TODO: check why MemFS is not working here
        File.delete(path)
      end

      xit 'should load service from /opt/putit/putit-plugins/external directory' do
        expect_any_instance_of(ExternalTestService).to receive(:new).and_call_original

        e = Env.first
        e.env_actions.create!(name: 'external', data: { run_by_service: 'external_test' })
        Event.create(source: 'Cluster', env: e, data: { content: 'external test content' })

        expect(File.exist?(path)).to be true
        expect(File.read(path)).to eq 'external test content'
      end
    end

    describe 'event can choose which action it will trigger' do
      let(:env) do
        env = Env.first
        env.env_actions.create!(name: 'A', data: { run_by_service: 'A' })
        env.env_actions.create!(name: 'B', data: { run_by_service: 'B' })
        env.env_actions.create!(name: 'C', data: { run_by_service: 'C' })
        env
      end

      it 'should run one action out of many' do
        Event.create(source: 'Cluster', env: env, run_actions: 'B', data: { hostname: 'host-av-1' })

        expect(AService.called).to be false
        expect(BService.called).to be true
        expect(CService.called).to be false
      end

      it 'should run multiple actions out of many' do
        Event.create(source: 'Cluster', env: env, run_actions: %w[B C], data: { hostname: 'host-av-1' })

        expect(AService.called).to be false
        expect(BService.called).to be true
        expect(CService.called).to be true
      end
    end
  end
end
