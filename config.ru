require './config/environment'

map('/artifact') { run ArtifactController }
map('/application') { run ApplicationController }
map('/release') { run ReleaseController }
map('/step') { run StepController }
map('/sshkey') { run SSHKeyController }
map('/depuser') { run DepuserController }
map('/status') { run StatusController }
map('/credential') { run CredentialController }
map('/approval') { run ApprovalController }
map('/settings') { run SettingsController }
map('/pipeline') { run PipelineController }
map('/orders') { run OrderController }
map('/integration/jira') { run JiraController }
map('/setup_wizard') { run SetupWizardController }

Putit::Integration::IntegrationBase.descendants.each do |plugin|
  map("/handlers/#{plugin.endpoint}") { run plugin }
end
