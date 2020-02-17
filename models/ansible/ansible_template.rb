class AnsibleTemplates < ActiveRecord::Base
  belongs_to :step
  has_many :physical_files, as: :fileable, dependent: :destroy

  amoeba do
    enable
  end
end
