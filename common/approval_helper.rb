class ApprovalHelper
  def self.create_technical_users(emails)
    emails.map do |email|
      name = email.split('@')

      User.find_or_create_by(email: email)
    end
  end
end
