# == Schema Information
#
# Table name: deployment_pipeline_steps
#
#  id                     :integer          not null, primary key
#  deployment_pipeline_id :integer
#  step_id                :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  position               :integer
#

class DeploymentPipelineStep < ActiveRecord::Base
  belongs_to :deployment_pipeline
  belongs_to :step
  default_scope { order(position: :asc) }
  acts_as_list scope: :deployment_pipeline
end
