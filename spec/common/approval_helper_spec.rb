describe ApprovalHelper do
  it 'should create technical users with prefix' do
    emails = [
      'jira1@putit.io',
      'jira2@putit.io'
    ]

    ApprovalHelper.create_technical_users(emails)

    expect(User.find_by_email('jira1@putit.io')).to be
    expect(User.find_by_email('jira2@putit.io')).to be
  end
end
