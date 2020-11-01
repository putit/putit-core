class AddJiraPluginWebhooksTable < ActiveRecord::Migration[6.0]
  def change
    create_table :jira_version_released_incoming_webhooks do |t|
      t.integer :release_id
      t.integer :project_id
      t.string :name
      t.string :description
      t.datetime :release_date
      t.string :raw
      t.timestamps null: false
    end
  end
end
