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

describe DeploymentPipeline, type: :model do
  describe 'steps' do
    it { is_expected.to have_many(:steps).through(:deployment_pipeline_steps) }

    it 'should add step' do
      pipeline = DeploymentPipeline.create!
      step1 = Step.create!(name: 'step1')
      step2 = Step.create!(name: 'step2')

      pipeline.steps << step1
      pipeline.steps << step2

      expect(pipeline.steps.length).to eq 2
    end
  end
end
