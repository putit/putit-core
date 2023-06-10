# == Schema Information
#
# Table name: physical_files
#
#  id            :integer          not null, primary key
#  name          :string
#  content       :binary
#  fileable_type :string
#  fileable_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
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
