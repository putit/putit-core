class MakePlaybookService < PutitService
  def initialize(release_order, logger_data = {})
    super
    @release = release_order.release
    @release_order = release_order
    @base_dir = @release.playbook_dir
    @applications_with_versions = release_order.application_with_versions
    @applications = release_order.application_with_versions.to_a.map(&:application)
  end

  def get_dir_name
    @release.playbook_dir
  end

  def make_playbook!
    logger.info("Generating deployment playbooks for change: #{@release_order.name}")
    make_release_directory!
    make_applications!
    logger.info("Deployment playbooks for change: #{@release_order.name} generated.")
  end

  private

  def make_release_directory!
    logger.debug("Creating #{@base_dir} dir where deployment playbooks will be stored.")
    FileUtils.mkdir_p @base_dir
    logger.debug("Created #{@base_dir}.")
  end

  def make_applications!
    @applications_with_versions.each do |avw|
      logger.info("Generating files for: #{@applications_with_versions.inspect}")
      ApplicationEnvsDirWriter.new(@base_dir, @release_order) << avw
      DeploymentYmlFileWriter.new(@base_dir, @release_order) << avw
      InventoryFileWriter.new(@base_dir, @release_order) << avw
      CredentialFileWriter.new(@base_dir, @release_order) << avw
      GroupVarsFileWiter.new(@base_dir, @release_order) << avw
      RolesFileWriter.new(@base_dir, @release_order) << avw
      logger.info("End of generating files for: #{@applications_with_versions.inspect}")
    end
  end
end
