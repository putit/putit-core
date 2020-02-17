# == Schema Information
#
# Table name: subreleases
#
#  id            :integer          not null, primary key
#  release_id    :integer          indexed, indexed => [subrelease_id]
#  subrelease_id :integer          indexed => [release_id], indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_subreleases_on_release_id                    (release_id)
#  index_subreleases_on_release_id_and_subrelease_id  (release_id,subrelease_id) UNIQUE
#  index_subreleases_on_subrelease_id                 (subrelease_id)
#

class Subrelease < ActiveRecord::Base
  belongs_to :release
  belongs_to :subrelease, class_name: 'Release'
end
