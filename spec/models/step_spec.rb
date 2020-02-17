# == Schema Information
#
# Table name: steps
#
#  id                      :integer          not null, primary key
#  name                    :string
#  description             :text
#  template                :boolean
#  properties_description  :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  origin_step_template_id :integer
#  deleted_at              :datetime         indexed
#
# Indexes
#
#  index_steps_on_deleted_at  (deleted_at)
#

describe Step, type: :model do
  it { is_expected.to have_one(:files) }
  it { is_expected.to have_one(:templates) }
  it { is_expected.to have_one(:handlers) }
  it { is_expected.to have_one(:tasks) }
  it { is_expected.to have_one(:vars) }
  it { is_expected.to have_one(:defaults) }
  it { is_expected.to validate_presence_of(:name) }

  it 'should delete step' do
    s = Step.first

    s.destroy

    expect(Step.exists?(s.id)).to eq false

    expect(AnsibleFiles.exists?(s.files.id)).to eq false
    expect(AnsibleTemplates.exists?(s.templates.id)).to eq false
    expect(AnsibleHandlers.exists?(s.handlers.id)).to eq false
    expect(AnsibleTasks.exists?(s.tasks.id)).to eq false
    expect(AnsibleVars.exists?(s.vars.id)).to eq false
    expect(AnsibleDefaults.exists?(s.defaults.id)).to eq false
  end

  it 'should automatically create files' do
    s = Step.create!(name: 'step')
    expect(s.files).to be
    expect(s.templates).to be
    expect(s.handlers).to be
    expect(s.tasks).to be
    expect(s.vars).to be
    expect(s.defaults).to be
  end

  it 'should clone step and set proper origin id' do
    template = Step.templates.first
    cloned = template.amoeba_dup

    expect(cloned.origin_step_template_id).to eq template.id
  end

  describe 'update' do
    it 'should detach step from step template on first update' do
      template = Step.templates.first
      cloned = template.amoeba_dup

      cloned.update_attribute(:name, 'new name')

      expect(cloned.origin_step_template_id).to be_nil
    end

    it 'should run detach callback only once on step' do
      template = Step.templates.first
      cloned = template.amoeba_dup

      expect(cloned).to receive(:detach_from_template).once

      cloned.update_attribute(:name, 'new name')
    end

    it 'should run detach callback when one of file tables are modified' do
      template = Step.templates.first
      cloned = template.amoeba_dup
      expect(cloned).to receive(:detach_from_template).once

      cloned.files.physical_files.first.update_attribute(:name, 'new name')
      cloned.files.physical_files.first.save!
    end

    it 'should not run detach callback on template' do
      template = Step.templates.first

      expect(template).not_to receive(:detach_from_template)

      template.update_attribute(:name, 'new name')
    end
  end

  describe 'physical files' do
    it 'should add physical file to step' do
      s = Step.create!(name: 'step')
      p = PhysicalFile.create!(name: 'file1')

      s.files.physical_files << p

      expect(s.files.physical_files.length).to eq 1
    end

    ANSIBLE_TABLES.each do |t|
      it "should clone #{t}" do
        s = Step.create!(name: 'step')
        p = PhysicalFile.create!(name: 'file1')

        s.send(t).physical_files << p

        clone = s.amoeba_dup
        clone.save

        expect(clone.send(t).physical_files.length).to eq 1
        clone.send(t).physical_files.first.update_attribute(:name, 'file2')

        expect(s.send(t).physical_files.first.name).to eq 'file1'
        expect(clone.send(t).physical_files.first.name).to eq 'file2'
      end
    end
  end
end
