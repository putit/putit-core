class ApplicationEnvsDirWriter < PutitService
  def initialize(base_dir, release_order)
    super
    @base_dir = base_dir
    @release_order = release_order
  end

  def <<(application_with_version)
    @roavw = @release_order.release_order_application_with_versions.find_by_application_with_version_id(application_with_version.id)
    make_envs_directories!(application_with_version)
  end

  private

  def make_envs_directories!(application_with_version)
    @roavw.envs.each do |env|
      application_env_dir = File.join(@base_dir, application_with_version.dir_name, env.name)
      logger.debug("Creating playbook dir: #{application_env_dir}")
      PutitService.make_dir(application_env_dir)
      logger.debug("Created playbook dir: #{application_env_dir}")
    end
  end
end
