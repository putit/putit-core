# == Schema Information
#
# Table name: releases
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  status     :integer
#  metadata   :string           default({})
#  deleted_at :datetime
#

describe Release, type: :model do
  describe 'name' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to allow_value('Prop_name-1.45 have space').for(:name) }
    it { is_expected.not_to allow_value(' ').for(:name) }
    it { is_expected.not_to allow_value('/').for(:name) }
  end

  describe 'delete' do
    it 'should delete release orders' do
      r = Release.first
      r_id = r.id
      ids = r.release_orders.map(&:id)

      r.destroy

      expect(Release.exists?(r_id)).to eq false

      ids.each do |id|
        expect(ReleaseOrder.exists?(id)).to eq false
      end
    end
  end

  it { is_expected.to have_many(:dependent_releases).through(:subreleases) }

  it 'should make dependant releases' do
    r1 = Release.create!(name: 'Big release')
    dep1 = Release.create!(name: 'Dependent 1')
    dep2 = Release.create!(name: 'Dependent 2')

    Subrelease.create(release_id: r1.id, subrelease_id: dep1.id)
    Subrelease.create(release_id: r1.id, subrelease_id: dep2.id)

    expect(r1.dependent_releases.map(&:name)[0]).to eq 'Dependent 1'
    expect(r1.dependent_releases.map(&:name)[1]).to eq 'Dependent 2'
  end
end
