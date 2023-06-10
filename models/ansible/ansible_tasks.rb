# == Schema Information
#
# Table name: ansible_tasks
#
#  id         :integer          not null, primary key
#  step_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AnsibleTasks < ActiveRecord::Base
  belongs_to :step
  has_many :physical_files, as: :fileable, dependent: :destroy

  amoeba do
    enable
  end
end
