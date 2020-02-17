class InventoryFileWriter < PutitService
  def initialize(base_dir, release_order)
    super
    @base_dir = base_dir
    @release_order = release_order
  end

  def <<(application_with_version)
    make_inventory_files!(application_with_version)
  end

  private

  def make_inventory_files!(_application_with_version)
    @release_order.release_order_application_with_versions.each do |roavw|
      roavw.envs.each do |env|
        application_dir = File.join(@base_dir, roavw.application_with_version.dir_name, env.name)
        FileUtils.mkdir_p application_dir
        application = roavw.application_with_version.application

        inventory_file = File.join(application_dir, "inventory_#{env.name}")
        logger.debug("Generating inventory file: #{inventory_file} for #{env.name}-#{application.dir_name}")
        group_name = "#{env.name}-#{application.dir_name}"
        content = "[#{group_name}]\n"
        content << get_hosts(env)

        begin
          File.open(inventory_file, 'w') do |f|
            f.write(content)
          end
        rescue StandardError => e
          raise PutitExceptions::MakePlaybookServiceError, "Unable to wrtie inventory playbook file at: #{inventory_file} due to error: #{e.message}"
        end

        logger.debug("End generating inventory for: #{roavw.inspect}")
      end
    end
  end

  def get_hosts(env)
    env.hosts.map do |host|
      host_line = [host.fqdn, "\n"].join(' ')
    end.join('')
  end
end
