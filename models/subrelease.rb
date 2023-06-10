# == Schema Information
#
# Table name: subreleases
#
#  id            :integer          not null, primary key
#  release_id    :integer
#  subrelease_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Subrelease < ActiveRecord::Base
  belongs_to :release
  belongs_to :subrelease, class_name: 'Release'
end
