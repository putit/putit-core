# == Schema Information
#
# Table name: ansible_files
#
#  id         :integer          not null, primary key
#  step_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
