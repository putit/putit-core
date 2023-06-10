# == Schema Information
#
# Table name: ansible_files
#
#  id         :integer          not null, primary key
#  step_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

describe AnsibleFiles, type: :model do
  it 'should clone with physical files' do
    s = Step.create!(name: 'test_test')
    a = s.files
    p = PhysicalFile.create!(name: 'file1')

    a.physical_files << p

    expect(a.physical_files.length).to eq 1

    clone = a.amoeba_dup
    clone.save!

    expect(clone.physical_files.length).to eq 1
  end
end
