describe ApprovalController do
  it 'should approve given Approval' do
    approve = Approval.create!(release_order_id: ReleaseOrder.first.id)
    uuid = approve.uuid
    approve.save!

    expect(approve.accepted).to eq false

    get "/approve/#{uuid}"

    expect(last_response.status).to eq 202
    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(Approval.find_by_uuid(uuid).accepted).to eq true
  end
end
