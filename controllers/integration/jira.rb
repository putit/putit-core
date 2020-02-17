class JiraController < Sinatra::Base
  get '/release' do
    'JIRA RELEASE'
  end

  get '/change' do
    'JIRA CHANGE'
  end

  post '/release' do
    json = JSON.parse(request.body.read, symbolize_names: true)

    JIRA_LOGGER.info "Handle Release webhook request: #{json}"

    release_name = JiraHelper.get_release_name(json[:issue], json[:issue][:self])

    if json[:transition]
      handle_transition(release_name, json)
    elsif json[:issue_event_type_name] == 'issue_created'
      create_release(release_name, json)
    end

    status 204
  end

  post '/change' do
    json = JSON.parse(request.body.read, symbolize_names: true)

    JIRA_LOGGER.info "Handle Change webhook request: #{json}"

    issue_uri = json[:issue][:fields][:parent][:self]
    issue = JiraHelper.get_issue(issue_uri)
    release_name = JiraHelper.get_release_name(issue, issue_uri)
    release_order_name = json[:issue][:fields][:summary]

    if json[:transition]
      handle_change_transition(release_order_name, json)
    elsif json[:issue_event_type_name] == 'issue_created'
      create_release_order(release_name, release_order_name, json)
    else
      APP_LOGGER.warn 'Cannot handle request type!'
    end

    status 204
  end

  private

  def handle_transition(release_name, json)
    from = json[:transition][:from_status]
    to = json[:transition][:to_status]

    if (from == 'Open') && (to == 'Closed')
      Release.find_by_name(release_name).closed!
    end

    if (from == 'Closed') && (to == 'Open')
      Release.find_by_name(release_name).open!
    end
  end

  def handle_change_transition(release_order_name, json)
    from = json[:transition][:from_status]
    to = json[:transition][:to_status]
    transition = json[:transition][:transitionName]

    APP_LOGGER.info "Handle Change transision: #{transition}"

    ro = ReleaseOrder.find_by_name(release_order_name)

    if (from == 'Working') && (to == 'Waiting for approvals')
      emails = json[:issue][:fields][ro.metadata['jira_approvers_field_name'].to_sym]
      users = ApprovalHelper.create_technical_users emails.map { |h| h[:emailAddress] }
      users.each do |approval_user|
        ro.approvals.create!(user_id: approval_user.id)
      end

      ro.send_approval_emails
      ro.waiting_for_approvals!

      transitions = JiraHelper.get_release_order_transitions(ro.metadata['jira_issue_uri'])[:transitions]
      transition_id = transitions.select { |h| h[:name] == 'Approvals gathered' }[0][:id]
      ro.metadata['jira_approved_transition_id'] = transition_id
      ro.save!
    end

    if (transition == 'Execute') && (to == 'In Deployment')
      APP_LOGGER.info "Execute Release Order from JIRA; RO.id = #{ro.id}"

      transitions = JiraHelper.get_release_order_transitions(ro.metadata['jira_issue_uri'])[:transitions]

      APP_LOGGER.info "Transition for Release Order #{ro.id}: #{transitions}"

      success_transition_id = transitions.select { |h| h[:name] == 'Success' }[0][:id]
      failure_transition_id = transitions.select { |h| h[:name] == 'Failure' }[0][:id]
      unknown_transition_id = transitions.select { |h| h[:name] == 'Unknown' }[0][:id]
      ro.metadata['jira_success_transition_id'] = success_transition_id
      ro.metadata['jira_failure_transition_id'] = failure_transition_id
      ro.metadata['jira_unknown_transition_id'] = unknown_transition_id
      ro.save!

      APP_LOGGER.info "Release Order #{ro.id} metadata: #{ro.metadata}"

      MakePlaybookService.new(ro).make_playbook!
      RunPlaybookService.new(ro).run!
      ArchivePlaybookService.new(ro).run!
    end
  end

  def create_release(release_name, json)
    APP_LOGGER.info "Handle Release create: #{release_name}"

    r = Release.create(name: release_name)
    r.metadata['jira_issue_uri'] = json[:issue][:self]
    r.metadata['jira_issue_id'] = json[:issue][:id]
    r.metadata['jira_issue_key'] = json[:issue][:key]
    r.save!
  end

  def create_release_order(release_name, release_order_name, json)
    APP_LOGGER.info "Handle Change create: #{release_order_name} for Release: #{release_name}"

    r = Release.find_by_name(release_name)
    APP_LOGGER.info "1: #{r} #{r.id}"
    ro = ReleaseOrder.create(release_id: r.id, name: release_order_name)
    APP_LOGGER.info "2: #{ro} #{r.id}"

    fields = JiraHelper.get_issue_metadata(json[:issue][:self])[:fields]
    APP_LOGGER.info '3'
    approvers_field_name = fields.select { |k, v| k.to_s.start_with?('customfield') && (v[:name] == 'PUTIT change approvers') }.first[0]
    APP_LOGGER.info '4'
    start_date_field_name = fields.select { |k, v| k.to_s.start_with?('customfield') && (v[:name] == 'PUTIT start date') }.first[0]
    APP_LOGGER.info '5'
    end_date_field_name = fields.select { |k, v| k.to_s.start_with?('customfield') && (v[:name] == 'PUTIT end date') }.first[0]
    APP_LOGGER.info '6'

    ro.start_date = Date.parse(json[:issue][:fields][start_date_field_name.to_sym])
    APP_LOGGER.info '7'
    ro.end_date = Date.parse(json[:issue][:fields][end_date_field_name.to_sym])
    APP_LOGGER.info '8'
    ro.metadata['jira_issue_uri'] = json[:issue][:self]
    ro.metadata['jira_issue_id'] = json[:issue][:id]
    ro.metadata['jira_issue_key'] = json[:issue][:key]
    ro.metadata['jira_approvers_field_name'] = approvers_field_name
    APP_LOGGER.info '9'
    ro.save!
    APP_LOGGER.info '10'
  end
end
