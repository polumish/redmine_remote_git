class CreateRemoteGitSources < ActiveRecord::Migration[7.2]
  def change
    create_table :remote_git_sources do |t|
      t.references :repository, null: false, index: { unique: true }
      t.string  :source_url,       null: false
      t.string  :mirror_path,      null: false
      t.string  :auth_type,        null: false, default: 'none'
      t.text    :credential_enc
      t.string  :credential_login
      t.integer :vault_key_id
      t.datetime :last_fetch_at
      t.text    :last_error
      t.timestamps
    end
  end
end
