class JiraHelper
  def self.get_issue(uri)
    json = open(uri, http_basic_authentication: [Settings.jira.username, Settings.jira.password]).read
    JSON.parse(json, symbolize_names: true)
  end

  def self.get_issue_metadata(uri)
    meta = open(uri + '/editmeta', http_basic_authentication: [Settings.jira.username, Settings.jira.password]).read
    JSON.parse(meta, symbolize_names: true)
  end

  def self.get_release_order_transitions(uri)
    meta = open(uri + '/transitions', http_basic_authentication: [Settings.jira.username, Settings.jira.password]).read
    JSON.parse(meta, symbolize_names: true)
  end

  def self.get_release_name(json, self_uri)
    meta_json = JiraHelper.get_issue_metadata self_uri
    fields = meta_json[:fields]
    field_name = fields.select { |k, v| k.to_s.start_with?('customfield') && (v[:name] == 'PUTIT release name') }.first[0]
    json[:fields][field_name]
  end
end
