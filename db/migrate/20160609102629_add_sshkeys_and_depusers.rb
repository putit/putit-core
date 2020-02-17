class AddSshkeysAndDepusers < ActiveRecord::Migration[5.0]
  def change
    create_table :sshkeys do |t|
      t.string :type, null: false
      t.integer :bits, null: false
      t.string :comment
      t.string :passphrase
      t.string :private_key, null: false
      t.string :encrypted_private_key
      t.string :public_key, null: false
      t.string :ssh2_public_key
      t.string :sha256_fingerprint, null: false
      t.timestamps null: false
    end
    create_table :depusers do |t|
      t.string :username, null: false
      t.timestamps null: false
    end
    create_table :sshkey_depusers do |t|
      t.belongs_to :sshkey, index: true
      t.belongs_to :depuser, index: true
      t.timestamps null: false
    end
  end
end
