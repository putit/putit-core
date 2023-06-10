# == Schema Information
#
# Table name: steps
#
#  id                      :integer          not null, primary key
#  name                    :string
#  description             :text
#  template                :boolean
#  properties_description  :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  origin_step_template_id :integer
#  deleted_at              :datetime
#

class Step < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :deployment_pipeline

  has_one :files, class_name: 'AnsibleFiles', dependent: :destroy
  has_one :templates, class_name: 'AnsibleTemplates', dependent: :destroy
  has_one :handlers, class_name: 'AnsibleHandlers', dependent: :destroy
  has_one :tasks, class_name: 'AnsibleTasks', dependent: :destroy
  has_one :vars, class_name: 'AnsibleVars', dependent: :destroy
  has_one :defaults, class_name: 'AnsibleDefaults', dependent: :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, if: :template?
  validates_format_of :name, with: /\A[\w\.\-0-9]+\z/

  after_create  :create_ansible_tables
  after_touch   :detach_from_template, if: :should_detach?
  after_update  :detach_from_template, if: :should_detach?

  scope :templates, -> { where(template: true) }

  amoeba do
    enable
    set template: false

    customize(lambda { |original, cloned|
      cloned.template = false
      cloned.save!
      cloned.files = original.files.amoeba_dup
      cloned.tasks = original.tasks.amoeba_dup
      cloned.templates = original.templates.amoeba_dup
      cloned.vars = original.vars.amoeba_dup
      cloned.defaults = original.defaults.amoeba_dup
      cloned.handlers = original.handlers.amoeba_dup
      cloned.update_column(:origin_step_template_id, original.id)
    })
  end

  def serializable_hash(_options = {})
    {
      id: id,
      name: name,
      description: description,
      tempate: template,
      properties_description: properties_description
    }
  end

  private

  def create_ansible_tables
    create_files
    create_templates
    create_handlers
    create_tasks
    create_vars
    create_defaults
    true
  end

  def should_detach?
    !template? && origin_step_template_id?
  end

  def detach_from_template
    return if saved_changes.empty?

    update_column(:origin_step_template_id, nil)
    true
  end
end
