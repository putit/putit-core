describe DepSSHKey, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }

  it 'should delete credentials' do
    k = DepSSHKey.first
    ids = k.credentials.map(&:id)

    k.destroy

    expect(DepSSHKey.exists?(k.id)).to eq false

    ids.each do |id|
      expect(Credential.exists?(id)).to eq false
    end
  end
end
