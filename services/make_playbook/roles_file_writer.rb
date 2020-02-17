class RolesFileWriter < PutitService
  def initialize(base_dir, release_order)
    super
    @base_dir = base_dir
    @release_order = release_order
  end

  def <<(application_with_version)
    @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    make_roles_directory!(application_with_version)
  end

  private

  def make_roles_directory!(application_with_version)
    @roavw.envs.each do |env|
      @roles_dir = File.join(@base_dir, application_with_version.dir_name, env.name, 'roles')
      PutitService.make_dir(@roles_dir)
      make_playbook_directories!(@roles_dir, env)
    end
  end

  def make_playbook_directories!(_roles_dir, env)
    env.pipelines.each do |pipeline|
      pipeline_dir = File.join(@roles_dir, pipeline.name)
      PutitService.make_dir(pipeline_dir)
      write_steps!(pipeline_dir, pipeline)
    end
  end

  def write_steps!(pipeline_dir, pipeline)
    pipeline.steps.each do |step|
      step_dir = File.join(pipeline_dir, step.name)
      PutitService.make_dir(step_dir)

      write_step_contents!(step_dir, step)
    end
  end

  def write_step_contents!(step_dir, step)
    ANSIBLE_TABLES.each do |t|
      task_dir = File.join(step_dir, t)
      PutitService.make_dir(task_dir)

      step.send(t).physical_files.each do |task_file|
        file_name = File.join(task_dir, task_file.name)

        begin
          File.open(file_name, 'wb') do |f|
            f.write(task_file.content)
          end
        rescue StandardError => e
          raise PutitExceptions::MakePlaybookServiceError, "Unable to wrtie step file at #{file_name} due to: #{e.message}"
        end
      end
    end
  end
end
