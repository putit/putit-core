describe ApprovalMailer do
  it 'should deliver Approval email to receipient' do
    u = User.find_by_email('approver1@putit.io')
    ro = ReleaseOrder.first
    a = Approval.create(user_id: u.id, release_order_id: ro.id)

    email = ApprovalMailer.deliver_approval_email(a)

    expect(email.to).to eq ['approver1@putit.io']
    expect(email.from).to eq ['notifications@onlynet.com.pl']
    expect(email.subject).to eq 'Please approve "Web html flat release"'
    expect(email.body).to match 'localhost:9292/approval'
  end

  it 'should not send email the second time' do
    u = User.find_by_email('approver1@putit.io')
    ro = ReleaseOrder.first
    a = Approval.create(user_id: u.id, release_order_id: ro.id)

    email = ApprovalMailer.deliver_approval_email(a)

    a.reload

    expect(a.sent?).to be true

    email = ApprovalMailer.deliver_approval_email(a)

    expect(email).to eq false
  end
end
