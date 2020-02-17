class AddSubreleaseTables < ActiveRecord::Migration[5.0]
  def change
    create_table :subreleases do |t|
      t.integer :release_id
      t.integer :subrelease_id

      t.timestamps
    end

    add_index :subreleases, :release_id
    add_index :subreleases, :subrelease_id
    add_index :subreleases, %i[release_id subrelease_id], unique: true
  end
end
