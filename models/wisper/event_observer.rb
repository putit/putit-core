class EventObserver
  def after_create(event)
    return unless event.env

    actions = event.env.env_actions
    if event.run_actions
      actions = actions.select { |ea| event.run_actions.include?(ea.data[:run_by_service]) }
    end
    actions.each do |ea|
      service_name = ea.data[:run_by_service]
      # TODO: log error if run_by_service is missing and skip to next
      klass = service_name.camelize
      service = "#{klass}Service".safe_constantize
      begin
        if service
          instance = service.new(event)
          instance.run if instance.respond_to?(:run)
        end
      rescue Exception => e
        # TODO: log
      end
    end
  end
end
