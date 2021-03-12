# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_20_202241) do

  create_table "ansible_defaults", force: :cascade do |t|
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_ansible_defaults_on_step_id"
  end

  create_table "ansible_files", force: :cascade do |t|
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_ansible_files_on_step_id"
  end

  create_table "ansible_handlers", force: :cascade do |t|
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_ansible_handlers_on_step_id"
  end

  create_table "ansible_tasks", force: :cascade do |t|
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_ansible_tasks_on_step_id"
  end

  create_table "ansible_templates", force: :cascade do |t|
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_ansible_templates_on_step_id"
  end

  create_table "ansible_vars", force: :cascade do |t|
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["step_id"], name: "index_ansible_vars_on_step_id"
  end

  create_table "application_with_version_artifact_with_versions", force: :cascade do |t|
    t.integer "application_with_version_id"
    t.integer "artifact_with_version_id"
  end

  create_table "application_with_versions", force: :cascade do |t|
    t.integer "application_id"
    t.string "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["application_id"], name: "index_application_with_versions_on_application_id"
    t.index ["deleted_at"], name: "index_application_with_versions_on_deleted_at"
  end

  create_table "applications", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_applications_on_deleted_at"
    t.index ["name"], name: "index_applications_on_name"
  end

  create_table "approvals", force: :cascade do |t|
    t.string "name"
    t.string "uuid", limit: 36
    t.string "email"
    t.boolean "accepted", default: false
    t.integer "release_order_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sent", default: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_approvals_on_deleted_at"
    t.index ["release_order_id"], name: "index_approvals_on_release_order_id"
    t.index ["user_id", "release_order_id"], name: "index_approvals_on_user_id_and_release_order_id", unique: true
    t.index ["user_id"], name: "index_approvals_on_user_id"
    t.index ["uuid"], name: "index_approvals_on_uuid"
  end

  create_table "artifact_with_versions", force: :cascade do |t|
    t.integer "artifact_id"
    t.integer "version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "artifact_type", default: 0
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_artifacts_on_deleted_at"
  end

  create_table "credentials", force: :cascade do |t|
    t.integer "sshkey_id"
    t.integer "depuser_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "comment"
    t.datetime "deleted_at"
    t.string "name"
    t.index ["deleted_at"], name: "index_credentials_on_deleted_at"
    t.index ["depuser_id"], name: "index_credentials_on_depuser_id"
    t.index ["name"], name: "index_credentials_on_name"
    t.index ["sshkey_id"], name: "index_credentials_on_sshkey_id"
  end

  create_table "deployment_pipeline_steps", force: :cascade do |t|
    t.integer "deployment_pipeline_id"
    t.integer "step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["deployment_pipeline_id", "step_id"], name: "step_pipeline_index", unique: true
    t.index ["deployment_pipeline_id"], name: "index_deployment_pipeline_steps_on_deployment_pipeline_id"
    t.index ["step_id"], name: "index_deployment_pipeline_steps_on_step_id"
  end

  create_table "deployment_pipelines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "env_id"
    t.integer "position"
    t.boolean "template", default: true
    t.datetime "deleted_at"
    t.text "description"
    t.index ["deleted_at"], name: "index_deployment_pipelines_on_deleted_at"
    t.index ["name"], name: "index_deployment_pipelines_on_name"
  end

  create_table "depusers", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_depusers_on_deleted_at"
  end

  create_table "env_actions", force: :cascade do |t|
    t.integer "env_action_id"
    t.string "uuid", limit: 36
    t.string "data"
    t.integer "status", default: 0
    t.string "name"
    t.string "description"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "enabled", default: true
    t.index ["deleted_at"], name: "index_env_actions_on_deleted_at"
    t.index ["env_action_id"], name: "index_env_actions_on_env_action_id"
    t.index ["uuid"], name: "index_env_actions_on_uuid"
  end

  create_table "env_credentials", force: :cascade do |t|
    t.integer "env_id"
    t.integer "credential_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_id"], name: "index_env_credentials_on_credential_id"
    t.index ["env_id"], name: "index_env_credentials_on_env_id"
  end

  create_table "env_with_actions", force: :cascade do |t|
    t.integer "env_id"
    t.integer "env_action_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["env_action_id"], name: "index_env_with_actions_on_env_action_id"
    t.index ["env_id"], name: "index_env_with_actions_on_env_id"
  end

  create_table "envs", force: :cascade do |t|
    t.string "name", null: false
    t.integer "application_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "aws_tags"
    t.index ["application_id"], name: "index_envs_on_application_id"
    t.index ["deleted_at"], name: "index_envs_on_deleted_at"
    t.index ["name", "application_id"], name: "index_envs_on_name_and_application_id", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.integer "env_id"
    t.string "source"
    t.integer "status"
    t.integer "severity"
    t.string "uuid", limit: 36
    t.string "data"
    t.integer "event_type", default: 1
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_events_on_deleted_at"
    t.index ["env_id"], name: "index_events_on_env_id"
    t.index ["uuid"], name: "index_events_on_uuid"
  end

  create_table "host_applications", force: :cascade do |t|
    t.integer "host_id"
    t.integer "application_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_host_applications_on_application_id"
    t.index ["host_id"], name: "index_host_applications_on_host_id"
  end

  create_table "host_credentials", force: :cascade do |t|
    t.integer "host_id"
    t.integer "credential_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_id"], name: "index_host_credentials_on_credential_id"
    t.index ["host_id"], name: "index_host_credentials_on_host_id"
  end

  create_table "hosts", force: :cascade do |t|
    t.string "fqdn", null: false
    t.string "name"
    t.string "ip"
    t.integer "env_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_hosts_on_deleted_at"
    t.index ["env_id"], name: "index_hosts_on_env_id"
    t.index ["fqdn", "env_id"], name: "index_hosts_on_fqdn_and_env_id", unique: true
  end

  create_table "jira_version_released_incoming_webhooks", force: :cascade do |t|
    t.integer "release_id"
    t.integer "project_id"
    t.string "name"
    t.string "description"
    t.datetime "release_date"
    t.string "raw"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "moneta", id: false, force: :cascade do |t|
    t.string "k", null: false
    t.binary "v"
    t.index ["k"], name: "index_moneta_on_k", unique: true
  end

  create_table "paper_trail_versions", force: :cascade do |t|
    t.string "item_type"
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_paper_trail_versions_on_item_type_and_item_id"
  end

  create_table "physical_files", force: :cascade do |t|
    t.string "name"
    t.binary "content"
    t.string "fileable_type"
    t.integer "fileable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fileable_type", "fileable_id"], name: "index_physical_files_on_fileable_type_and_fileable_id"
  end

  create_table "release_order_application_with_version_envs", force: :cascade do |t|
    t.integer "release_order_application_with_version_id"
    t.integer "env_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["env_id"], name: "env_ro_env"
    t.index ["release_order_application_with_version_id"], name: "env_ro_avw"
  end

  create_table "release_order_application_with_versions", force: :cascade do |t|
    t.integer "release_order_id"
    t.integer "application_with_version_id"
  end

  create_table "release_order_results", force: :cascade do |t|
    t.integer "release_order_id"
    t.integer "env_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "application_id"
    t.integer "application_with_version_id"
    t.text "log", default: ""
    t.index ["env_id"], name: "index_release_order_results_on_env_id"
    t.index ["release_order_id", "env_id", "application_id"], name: "uniq_result", unique: true
    t.index ["release_order_id"], name: "index_release_order_results_on_release_order_id"
  end

  create_table "release_orders", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.text "description"
    t.integer "release_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.binary "archive"
    t.integer "status"
    t.string "name"
    t.string "metadata", default: "{}"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_release_orders_on_deleted_at"
    t.index ["name"], name: "index_release_orders_on_name"
    t.index ["release_id"], name: "index_release_orders_on_release_id"
  end

  create_table "releases", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.string "metadata", default: "{}"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_releases_on_deleted_at"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sshkeys", force: :cascade do |t|
    t.string "keytype", null: false
    t.integer "bits", null: false
    t.string "comment"
    t.string "passphrase"
    t.string "private_key", null: false
    t.string "encrypted_private_key"
    t.string "public_key", null: false
    t.string "ssh2_public_key"
    t.string "sha256_fingerprint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ssh_public_key"
    t.datetime "deleted_at"
    t.string "name"
    t.index ["deleted_at"], name: "index_sshkeys_on_deleted_at"
    t.index ["name"], name: "index_sshkeys_on_name"
  end

  create_table "steps", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.boolean "template"
    t.text "properties_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "origin_step_template_id"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_steps_on_deleted_at"
  end

  create_table "subreleases", force: :cascade do |t|
    t.integer "release_id"
    t.integer "subrelease_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["release_id", "subrelease_id"], name: "index_subreleases_on_release_id_and_subrelease_id", unique: true
    t.index ["release_id"], name: "index_subreleases_on_release_id"
    t.index ["subrelease_id"], name: "index_subreleases_on_subrelease_id"
  end

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", force: :cascade do |t|
    t.integer "artifact_id"
    t.string "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["artifact_id"], name: "index_versions_on_artifact_id"
    t.index ["deleted_at"], name: "index_versions_on_deleted_at"
  end

end
