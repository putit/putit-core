# == Schema Information
#
# Table name: ansible_handlers
#
#  id         :integer          not null, primary key
#  step_id    :integer          indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_ansible_handlers_on_step_id  (step_id)
#

class AnsibleHandlers < ActiveRecord::Base
  belongs_to :step
  has_many :physical_files, as: :fileable, dependent: :destroy

  amoeba do
    enable
  end
end
