# == Schema Information
#
# Table name: physical_files
#
#  id            :integer          not null, primary key
#  name          :string
#  content       :binary
#  fileable_type :string           indexed => [fileable_id]
#  fileable_id   :integer          indexed => [fileable_type]
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_physical_files_on_fileable_type_and_fileable_id  (fileable_type,fileable_id)
#

class PhysicalFile < ActiveRecord::Base
  include Wisper.model
  belongs_to :fileable, polymorphic: true, touch: true

  def serializable_hash(_options = {})
    { id: id,
      name: name }
  end

  amoeba do
    enable
  end
end
