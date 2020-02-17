# == Schema Information
#
# Table name: artifacts
#
#  id            :integer          not null, primary key
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  artifact_type :integer          default("flat")
#  deleted_at    :datetime         indexed
#
# Indexes
#
#  index_artifacts_on_deleted_at  (deleted_at)
#

describe Artifact, type: :model do
  describe 'name' do
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to allow_value('artifact-1').for(:name) }
    it { is_expected.to allow_value('immutable').for(:name) }
    it { is_expected.not_to allow_value(' artifact-1').for(:name) }
  end

  describe 'artifact_type' do
    it {
      is_expected.to define_enum_for(:artifact_type)
        .with_values(%i[flat github_repository github_release])
    }
  end
end
