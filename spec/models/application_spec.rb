# == Schema Information
#
# Table name: applications
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

describe Application, type: :model do
  it { is_expected.to have_many(:release_order_results) }
  it { is_expected.to have_many(:versions) }

  it 'should use Paper Trail' do
    expect(PaperTrail).to be_enabled
  end
end
