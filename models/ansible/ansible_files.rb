# == Schema Information
#
# Table name: ansible_files
#
#  id         :integer          not null, primary key
#  step_id    :integer          indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_ansible_files_on_step_id  (step_id)
#

class AnsibleFiles < ActiveRecord::Base
  belongs_to :step
  has_many :physical_files, as: :fileable, dependent: :destroy

  after_touch :touch_step

  amoeba do
    enable
  end

  private

  def touch_step
    step.touch
    true
  end
end
