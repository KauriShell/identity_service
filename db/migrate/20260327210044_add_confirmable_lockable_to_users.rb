class AddConfirmableLockableToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email

      t.integer :failed_attempts, null: false, default: 0
      t.string :unlock_token
      t.datetime :locked_at
    end

    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token, unique: true
  end
end
