class ReleaseOrderObserver
  def after_update(ro)
    if ro.approved?
      p, n = ro.previous_changes['status']
      if (p == 'waiting_for_approvals') && (n == 'approved') && ro.metadata['jira_approved_transition_id']
        send_transition(ro, ro.metadata['jira_approved_transition_id'].to_i)
      end
    end

    if ro.deployed? && ro.metadata['jira_success_transition_id']
      JIRA_LOGGER.info 'Deployed'
      send_transition(ro, ro.metadata['jira_success_transition_id'].to_i)
    end

    if ro.failed? && ro.metadata['jira_failure_transition_id']
      JIRA_LOGGER.info 'Failed'
      send_transition(ro, ro.metadata['jira_failure_transition_id'].to_i)
    end
  end

  private

  def send_transition(ro, id)
    issue_transition_uri = ro.metadata['jira_issue_uri'] + '/transitions'
    uri = URI.parse(issue_transition_uri)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.basic_auth('putit', 'TuSSk')
    req.body = { 'transition': { 'id': id } }.to_json

    response = Net::HTTP.start(uri.hostname) do |http|
      http.request(req)
    end
  end
end
