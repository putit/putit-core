# == Schema Information
#
# Table name: paper_trail_versions
#
#  id         :integer          not null, primary key
#  item_type  :string           indexed => [item_id]
#  item_id    :integer          not null, indexed => [item_type]
#  event      :string           not null
#  whodunnit  :string
#  object     :text
#  created_at :datetime
#
# Indexes
#
#  index_paper_trail_versions_on_item_type_and_item_id  (item_type,item_id)
#

class PaperTrailVersion < PaperTrail::Version
  self.table_name = :paper_trail_versions
end
