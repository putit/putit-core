# == Schema Information
#
# Table name: paper_trail_versions
#
#  id         :integer          not null, primary key
#  item_type  :string
#  item_id    :integer          not null
#  event      :string           not null
#  whodunnit  :string
#  object     :text
#  created_at :datetime
#

class PaperTrailVersion < PaperTrail::Version
  self.table_name = :paper_trail_versions
end
