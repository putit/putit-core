# == Schema Information
#
# Table name: deployment_pipelines
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  env_id      :integer
#  position    :integer
#  template    :boolean          default(TRUE)
#  deleted_at  :datetime
#  description :text
#

class DeploymentPipeline < ActiveRecord::Base
  acts_as_paranoid
  acts_as_list scope: :env_id

  validates_uniqueness_of :name, if: :template?

  default_scope { self.order(position: :asc) }
  scope :templates, -> { self.where(template: true) }

  has_many :deployment_pipeline_steps
  has_many :steps, through: :deployment_pipeline_steps, dependent: :destroy

  amoeba do
    enable
    set template: false
    nullify :position
  end

  def serializable_hash(options = {})
    logger.debug("to_json options: #{options}")

    result = super(options)
    hash = {
      id: id,
      name: name,
      steps: steps.map(&:name),
      description: description,
      template: template
    }

    hash['position'] = position unless template
    hash
  end
end
