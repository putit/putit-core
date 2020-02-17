# == Schema Information
#
# Table name: blocked_tokens
#
#  id         :integer          not null, primary key
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_blocked_tokens_on_token  (token)
#

class BlockedToken < ActiveRecord::Base
  establish_connection :users
end
