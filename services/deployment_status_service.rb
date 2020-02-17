class DeploymentStatusService < PutitService
  # when first arg is application type then it returns current deployed version per env
  #  thats the case for: models/application.rb and status controller.
  # if it's an application_with_version type then it returns latest deployment/result for this specific awv
  # thats the case for: models/application_with_version.rb
  def get_deployment_status(application, env_app)
    if application.class.name == 'Application'
      type = :application
      result = ReleaseOrderResult.where(application_id: application.id, env_id: env_app.id).last
      log_msg = "No deployment results for application: #{application.name} on environment: #{env_app.name}"
    elsif application.class.name == 'ApplicationWithVersion'
      awv = application
      type = :awv
      result = ReleaseOrderResult.where(application_with_version_id: awv.id, env_id: env_app.id).last
      log_msg = "No deployment results for application: #{awv.application.name} with version: #{awv.version} on environment: #{env_app.name}"
    end

    if result.nil?
      logger.info(log_msg)
    else

      case type
      when :awv
        log_url = "#{Settings.putit_core_url}/status/#{awv.application.url_name}/#{env_app.name}/#{result.id}/logs"
      when :application
        awv = result.application_with_version
        log_url = "#{Settings.putit_core_url}/status/#{application.url_name}/#{env_app.name}/#{result.id}/logs"
      end

      # check if release and release order exist
      if result.release_order.nil?
        release_order = '-'
        release = '-'
      elsif result.release_order.release.nil?
        release_order = result.release_order.name
        release = '-'
      else
        release = result.release_order.release.name
        release_order = result.release_order.name
      end

      deployment_results = {
        release: release,
        change: release_order,
        version: awv.version,
        env: result.env.name,
        status: result.status,
        deployment_date: result.updated_at,
        log_url: log_url
      }
    end
    deployment_results
  end
end
