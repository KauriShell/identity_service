class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.citext :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.uuid :jti, null: false
      t.integer :role, null: false, default: 0
      t.integer :kyc_status, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :first_name
      t.string :last_name
      t.string :phone_number
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
    add_index :users, :discarded_at
  end
end
