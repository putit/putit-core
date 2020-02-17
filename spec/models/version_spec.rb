# == Schema Information
#
# Table name: versions
#
#  id          :integer          not null, primary key
#  artifact_id :integer          indexed
#  version     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime         indexed
#
# Indexes
#
#  index_versions_on_artifact_id  (artifact_id)
#  index_versions_on_deleted_at   (deleted_at)
#

describe Version, type: :model do
  describe 'version' do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to allow_value('1.2.3-1.SNAPSHOT').for(:version) }
    it { is_expected.not_to allow_value(' $%1.2.3-1.SNAPSHOT').for(:version) }
  end
end
