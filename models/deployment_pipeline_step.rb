# == Schema Information
#
# Table name: deployment_pipeline_steps
#
#  id                     :integer          not null, primary key
#  deployment_pipeline_id :integer          indexed, indexed => [step_id]
#  step_id                :integer          indexed, indexed => [deployment_pipeline_id]
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  position               :integer
#
# Indexes
#
#  index_deployment_pipeline_steps_on_deployment_pipeline_id  (deployment_pipeline_id)
#  index_deployment_pipeline_steps_on_step_id                 (step_id)
#  step_pipeline_index                                        (deployment_pipeline_id,step_id) UNIQUE
#

class DeploymentPipelineStep < ActiveRecord::Base
  belongs_to :deployment_pipeline
  belongs_to :step
  default_scope { order(position: :asc) }
  acts_as_list scope: :deployment_pipeline
end
