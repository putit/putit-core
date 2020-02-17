class PhysicalFileObserver
  def after_create(file)
    return unless file&.fileable

    ansible_table = file.fileable.class.name
    relation_name = Step.reflect_on_all_associations(:has_one).find do |asoc|
      asoc.options[:class_name] == ansible_table
    end.send(:name)
    template = file.fileable.step
    changes = file.previous_changes

    Step.where(origin_step_template_id: template.id).each do |step|
      table = step.send(relation_name)

      cloned = file.amoeba_dup
      table.physical_files << cloned
      cloned.save!
    end
  end
end
