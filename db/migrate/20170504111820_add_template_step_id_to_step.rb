class AddTemplateStepIdToStep < ActiveRecord::Migration[5.0]
  def change
    add_column :steps, :origin_step_template_id, :integer
  end
end
