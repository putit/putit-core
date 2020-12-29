# == Schema Information
#
# Table name: deployment_pipelines
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string           indexed
#  env_id      :integer
#  position    :integer
#  template    :boolean          default(TRUE)
#  deleted_at  :datetime         indexed
#  description :text
#
# Indexes
#
#  index_deployment_pipelines_on_deleted_at  (deleted_at)
#  index_deployment_pipelines_on_name        (name)
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
