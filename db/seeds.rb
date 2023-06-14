require_relative './seed/role1_step'

# Clean up old tables
# (TODO): check is needed
Application.destroy_all
ArtifactWithVersion.destroy_all
ApplicationWithVersionArtifactWithVersion.destroy_all
Artifact.delete_all
Release.destroy_all
Host.destroy_all
Env.destroy_all
Credential.destroy_all
DepSSHKey.destroy_all
Depuser.destroy_all
ReleaseOrder.destroy_all
ReleaseOrderResult.destroy_all
ReleaseOrderApplicationWithVersion.destroy_all
DeploymentPipeline.destroy_all
DeploymentPipelineStep.destroy_all
User.destroy_all

organization = Organization.create!(name: 'putit')

# Create users for apprivals
User.create!(email: 'approver1@putit.io')
User.create!(email: 'approver2@putit.io')

# Create two releases
web_release = Release.create!(name: 'Web html flat release')
second_release = Release.create!(name: 'Second release for tests')

# Create closed release
closed_release = Release.create!(name: 'Closed release')
closed_release.closed!

# Create first application ...
application_1 = Application.create!(name: 'WEBv1', organization_id: organization.id)
# ... add two versions to it...
app_1_v1 = application_1.versions.create!(version: '1.0.0')
app_1_v2 = application_1.versions.create!(version: '2.0.0')

# ,.. and create environments for it ...
env_dev = application_1.envs.create!(name: 'dev')
env_uat = application_1.envs.create!(name: 'uat')
env_prod = application_1.envs.create!(name: 'prod')
PROPERTIES_STORE[env_prod.properties_key] = {
  'maintainer' => 'putit@putit.io'
}

# ... and add hosts for every environment
testowyhost_1_dev = env_dev.hosts.create!(name: 'host-1', fqdn: 'testowyhost-1.com', ip: '127.0.0.1')
testowyhost_2_dev = env_dev.hosts.create!(name: 'host-2', fqdn: 'testowyhost-2.com', ip: '127.0.0.2')
env_uat.hosts.create!(name: 'host-1', fqdn: 'testowyhost-1.com', ip: '127.0.0.1')
env_uat.hosts.create!(name: 'host-2', fqdn: 'testowyhost-2.com', ip: '127.0.0.2')
testowyhost_1_prod = env_prod.hosts.create!(name: 'host-1', fqdn: 'testowyhost-1.com', ip: '127.0.0.1')
testowyhost_2_prod = env_prod.hosts.create!(name: 'host-2', fqdn: 'testowyhost-2.com', ip: '127.0.0.2')

# Create pipeline
copy_files_pipeline_template = DeploymentPipeline.create(name: 'copy_files')
copy_files_pipeline_template.steps << Step.find_by_name('copy_artifacts').amoeba_dup

send_notification_step_template = Step.templates.create(name: 'notification')
send_notification_step_template.templates.physical_files << PhysicalFile.create!(name: 'notification.j2',
                                                                                 content: 'simple notification')
send_notification_pipeline_template = DeploymentPipeline.create(name: 'send_notifications')
send_notification_pipeline_template.steps << send_notification_step_template.amoeba_dup

# Add pipelines to envs
env_dev.pipelines << copy_files_pipeline_template.amoeba_dup
env_dev.pipelines << send_notification_pipeline_template.amoeba_dup
env_uat.pipelines << copy_files_pipeline_template.amoeba_dup
env_prod.pipelines << copy_files_pipeline_template.amoeba_dup
env_prod.pipelines << send_notification_pipeline_template.amoeba_dup

# Create second application with one version
application_2 = Application.create!(name: 'TEST APPLICATION', organization_id: organization.id)
env_test = application_2.envs.create!(name: 'test')
env_test.pipelines << copy_files_pipeline_template.amoeba_dup
env_test.pipelines << send_notification_pipeline_template.amoeba_dup
app_2_v2 = application_2.versions.create!(version: '2.0.0')

# Create artifcat with three versions
index_html = Artifact.create!(name: 'index')
first_version = index_html.versions.create!(version: '1.0.0')
second_version = index_html.versions.create!(version: '2.0.0')
third_version = index_html.versions.create!(version: '3.0.0')

# Crete ArtifactWithVersion which is a connection between artifact and its version to be used in application
index_with_first_version = ArtifactWithVersion.create!(artifact_id: index_html.id, version_id: first_version.id)
PROPERTIES_STORE['/artifact/flat/index/1.0.0/properties'] = {
  'install_dir' => '/tmp',
  'source_path' => '/opt/source/index/html/1.0.0/index.html',
  'mode' => '0666'
}
ArtifactWithVersion.create!(artifact_id: index_html.id, version_id: second_version.id)
index_with_third_version = ArtifactWithVersion.create!(artifact_id: index_html.id, version_id: third_version.id)

# Create second artifact with two versions
other_html = Artifact.create!(name: 'other')
other_html.versions.create!(version: '1.0.0')
other_version = other_html.versions.create!(version: '1.4.1')

other_with_version = ArtifactWithVersion.create!(artifact_id: other_html.id, version_id: other_version.id)
PROPERTIES_STORE['/artifact/flat/other/1.4.1/properties'] = {
  'install_dir' => '/tmp',
  'source_path' => '/opt/source/other/html/1.4.1/other.html',
  'mode' => '0666'
}

# Application with version will have artifact with version - that's how we know _what_ to deploy
ApplicationWithVersionArtifactWithVersion.create!(artifact_with_version_id: index_with_first_version.id,
                                                  application_with_version_id: app_1_v1.id)
ApplicationWithVersionArtifactWithVersion.create!(artifact_with_version_id: other_with_version.id,
                                                  application_with_version_id: app_1_v1.id)

ApplicationWithVersionArtifactWithVersion.create!(artifact_with_version_id: index_with_third_version.id,
                                                  application_with_version_id: app_1_v2.id)
ApplicationWithVersionArtifactWithVersion.create!(artifact_with_version_id: other_with_version.id,
                                                  application_with_version_id: app_1_v2.id)

# Create SSH keys
k_1 = SSHKey.generate({ type: 'DSA', comment: 'ala@ala.com', bits: 1024, passphrase: 'haslo' })
k_2 = SSHKey.generate({ type: 'DSA', comment: 'piotr@example.com', bits: 2048, passphrase: 'lkjh' })
k_3 = SSHKey.generate({ type: 'DSA', comment: 'mateusz@example.com', bits: 2048, passphrase: 'pkp intercity' })
sshkey_1 = DepSSHKey.create(name: 'sshkey1', keytype: k_1.type, bits: k_1.bits, private_key: k_1.private_key,
                            public_key: k_1.public_key, ssh_public_key: k_1.public_key, ssh2_public_key: k_1.ssh2_public_key, sha256_fingerprint: k_1.sha256_fingerprint)
sshkey_2 = DepSSHKey.create(name: 'sshkey2', keytype: k_2.type, bits: k_2.bits, private_key: k_2.private_key,
                            public_key: k_2.public_key, ssh_public_key: k_2.public_key, ssh2_public_key: k_2.ssh2_public_key, sha256_fingerprint: k_2.sha256_fingerprint)
sshkey_3 = DepSSHKey.create(name: 'sshkey3', keytype: k_3.type, bits: k_3.bits, private_key: k_3.private_key,
                            public_key: k_3.public_key, ssh_public_key: k_3.public_key, ssh2_public_key: k_3.ssh2_public_key, sha256_fingerprint: k_3.sha256_fingerprint)

# Create UNIX users for deployment
depuser_1 = Depuser.create(username: 'app_user_1')
depuser_2 = Depuser.create(username: 'app_user_2')
depuser_3 = Depuser.create(username: 'app_user_3')

# Credential is a link between user and it's SSH key
credential_1 = Credential.create(name: 'credential1', depuser_id: depuser_1.id, sshkey_id: sshkey_1.id)
credential_2 = Credential.create(name: 'credential2', depuser_id: depuser_2.id, sshkey_id: sshkey_2.id)
credential_3 = Credential.create(name: 'credential3', depuser_id: depuser_3.id, sshkey_id: sshkey_3.id)

env_dev.credential = credential_1
env_prod.credential = credential_2
testowyhost_1_prod.credential = credential_3
testowyhost_2_prod.credential = credential_3

release_order_1 = web_release.release_orders.create!(
  name: 'Release order 1',
  description: 'First release order.',
  start_date: Time.now - 3.days,
  end_date: Time.now - 1.days
)

# add envs to release order
release_order_1.release_order_results.create!(env_id: env_dev.id,
                                              application_id: application_1.id,
                                              application_with_version_id: app_1_v1.id,
                                              status: :failure,
                                              log: 'LOG1')
release_order_1.release_order_results.create!(env_id: env_uat.id,
                                              application_id: application_1.id,
                                              application_with_version_id: app_1_v1.id,
                                              status: :failure,
                                              log: 'LOG2')
release_order_1.release_order_results.create!(env_id: env_prod.id,
                                              application_id: application_1.id,
                                              application_with_version_id: app_1_v1.id,
                                              status: :success,
                                              log: 'LOG3')

release_order_2 = web_release.release_orders.create!(
  name: 'Release order 2',
  description: 'Second release order.',
  start_date: Time.now - 2.days,
  end_date: Time.now + 31.days
)
roavw1 = release_order_2.release_order_application_with_versions.create!(application_with_version_id: app_1_v1.id)
roavw1.release_order_application_with_version_envs.create(env_id: env_dev.id)
roavw1.release_order_application_with_version_envs.create(env_id: env_prod.id)

roavw2 = release_order_2.release_order_application_with_versions.create!(application_with_version_id: app_2_v2.id)
roavw2.release_order_application_with_version_envs.create(env_id: env_test.id)
release_order_2.release_order_results.create!(env_id: env_dev.id,
                                              application_id: application_1.id,
                                              application_with_version_id: app_1_v2.id,
                                              status: :success,
                                              log: 'LOG4')
release_order_2.release_order_results.create!(env_id: env_uat.id,
                                              application_id: application_1.id,
                                              application_with_version_id: app_1_v2.id,
                                              status: :failure,
                                              log: 'LOG5')

release_order_3 = web_release.release_orders.create!(
  name: 'Future release order 1',
  description: 'Future release order 1.',
  start_date: Time.now + 31.days,
  end_date: Time.now + 41.days
)
roavw3 = release_order_3.release_order_application_with_versions.create!(application_with_version_id: app_1_v2.id)
roavw3.release_order_application_with_version_envs.create(env_id: env_prod.id)

release_order_4 = web_release.release_orders.create!(
  name: 'Future release order 2',
  description: 'Future release order 2.',
  start_date: Time.now + 11.days,
  end_date: Time.now + 13.days
)
release_order_4.release_order_application_with_versions.create!(application_with_version_id: app_1_v2.id)
release_order_4.deployed!

release_order_for_closed_release = closed_release.release_orders.create!(
  name: 'Release order for closed release',
  description: 'Release order for closed release.',
  start_date: Time.now + 11.days,
  end_date: Time.now + 13.days
)
roavw_closed_release = release_order_for_closed_release.release_order_application_with_versions.create!(application_with_version_id: app_1_v1.id)
roavw_closed_release.release_order_application_with_version_envs.create(env_id: env_dev.id)

release_order_for_second_release = second_release.release_orders.create!(
  name: 'Release order for second release',
  description: 'Release order for second open release',
  start_date: Time.now - 2.days,
  end_date: Time.now + 31.days
)
roavw4 = release_order_for_second_release.release_order_application_with_versions.create!(application_with_version_id: app_1_v2.id)
roavw4.release_order_application_with_version_envs.create(env_id: env_dev.id)
roavw4.release_order_application_with_version_envs.create(env_id: env_prod.id)
