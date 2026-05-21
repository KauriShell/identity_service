class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :refresh_tokens, :user_id
    add_index :refresh_tokens, :token_digest, unique: true
  end
end
