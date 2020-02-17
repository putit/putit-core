# == Schema Information
#
# Table name: artifact_with_versions
#
#  id          :integer          not null, primary key
#  artifact_id :integer
#  version_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

describe ArtifactWithVersion do
  it 'should return proper properties_key' do
    a = Artifact.create!(name: 'artifact1')
    a.versions.create!(version: '1.0.0')
    a.versions.create!(version: '1.1.0')
    v = a.versions.create!(version: '2.0.0')

    avv = ArtifactWithVersion.create!(artifact_id: a.id, version_id: v.id)
    expect(avv.properties_key).to eq '/artifact/flat/artifact1/2.0.0/properties'
  end
end
